import Foundation

actor DeepSeekAPIService {
    static let shared = DeepSeekAPIService()

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private var apiKey: String?
    private var platformToken: String?

    func configure(apiKey key: String, platformToken token: String? = nil) {
        apiKey = key
        platformToken = Self.extractToken(token)
    }

    /// 支持粘贴原始 token 字符串或 JSON 对象 {"value":"...", "__version":"0"}
    private static func extractToken(_ raw: String?) -> String? {
        guard let raw = raw, !raw.isEmpty else { return nil }
        if let data = raw.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let value = json["value"] as? String, !value.isEmpty {
            return value
        }
        return raw
    }

    func fetchBalance() async throws -> BalanceInfo {
        guard let key = apiKey else { throw APIError.notConfigured }
        guard let url = URL(string: "https://api.deepseek.com/user/balance") else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 15
        let (data, response) = try await session.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        switch httpResponse.statusCode {
        case 200...299: break
        case 401, 403: throw APIError.unauthorized
        case 429: throw APIError.rateLimited
        case 500...599: throw APIError.serverError(httpResponse.statusCode)
        default: throw APIError.httpError(httpResponse.statusCode)
        }
        let decoded = try JSONDecoder().decode(BalanceResponse.self, from: data)
        guard let info = decoded.balanceInfos.first else { throw APIError.noData }
        return info
    }

    func fetchMonthlyCost() async throws -> MonthlyCostInfo {
        guard let token = platformToken else { throw APIError.noPlatformToken }
        let now = Date()
        let cal = Calendar.current
        let month = String(format: "%02d", cal.component(.month, from: now))
        let year = String(cal.component(.year, from: now))

        guard let url = URL(string: "https://platform.deepseek.com/api/v0/usage/cost?month=\(month)&year=\(year)") else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        req.setValue("https://platform.deepseek.com/usage", forHTTPHeaderField: "Referer")
        req.timeoutInterval = 15
        let (data, response) = try await session.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        switch httpResponse.statusCode {
        case 200...299: break
        case 401, 403: throw APIError.unauthorized
        case 500...599: throw APIError.serverError(httpResponse.statusCode)
        default: throw APIError.httpError(httpResponse.statusCode)
        }
        let decoded = try JSONDecoder().decode(CostResponse.self, from: data)
        guard let bizData = decoded.data?.bizData?.first else { throw APIError.noCostData }
        let currency = bizData.currency ?? "CNY"
        var totalSpent: Double = 0
        var dailyCount = 0
        var dailyUsage: [DailyUsageStats] = []
        if let days = bizData.days {
            dailyCount = days.count
            for day in days {
                var dayPrompt = 0, dayCompletion = 0, dayRequests = 0
                var daySpent: Double = 0
                if let items = day.data {
                    for item in items {
                        if let usage = item.usage {
                            for u in usage {
                                if let amt = u.amount, let val = Double(amt) {
                                    daySpent += val
                                }
                                dayPrompt += u.promptTokens ?? 0
                                dayCompletion += u.completionTokens ?? 0
                                dayRequests += u.requests ?? 0
                            }
                        }
                    }
                }
                totalSpent += daySpent
                dailyUsage.append(DailyUsageStats(
                    date: day.date,
                    promptTokens: dayPrompt,
                    completionTokens: dayCompletion,
                    requests: dayRequests
                ))
            }
        }
        var todayModelCost: [String: Double] = [:]
        if let days = bizData.days {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let todayStr = df.string(from: Date())
            for day in days where day.date == todayStr {
                if let items = day.data {
                    for item in items {
                        let modelName = item.model ?? "未知模型"
                        var cost: Double = 0
                        for u in item.usage ?? [] {
                            if let amt = u.amount, let val = Double(amt) {
                                cost += val
                            }
                        }
                        todayModelCost[modelName] = (todayModelCost[modelName] ?? 0) + cost
                    }
                }
            }
        }

        var modelSummary: [ModelUsageSummary] = []
        var grandTotalTokens = 0
        if let totals = bizData.total {
            for total in totals {
                var totalTokens = 0, totalRequests = 0
                if let usage = total.usage {
                    for u in usage {
                        totalTokens += (u.promptTokens ?? 0) + (u.completionTokens ?? 0)
                        totalRequests += u.requests ?? 0
                    }
                }
                grandTotalTokens += totalTokens
                modelSummary.append(ModelUsageSummary(
                    model: total.model ?? "未知模型",
                    totalTokens: totalTokens,
                    totalRequests: totalRequests,
                    percentage: 0
                ))
            }
        }
        if grandTotalTokens > 0 {
            for i in modelSummary.indices {
                let ms = modelSummary[i]
                modelSummary[i] = ModelUsageSummary(
                    model: ms.model,
                    totalTokens: ms.totalTokens,
                    totalRequests: ms.totalRequests,
                    percentage: Double(ms.totalTokens) / Double(grandTotalTokens) * 100
                )
            }
        }
        return MonthlyCostInfo(
            currency: currency,
            totalSpent: totalSpent,
            dailyCount: dailyCount,
            dailyUsage: dailyUsage,
            modelSummary: modelSummary,
            todayModelCost: todayModelCost
        )
    }

    func fetchUsageAmount() async throws -> [ModelUsage] {
        guard let token = platformToken else { throw APIError.noPlatformToken }
        let now = Date()
        let cal = Calendar.current
        let month = String(format: "%02d", cal.component(.month, from: now))
        let year = String(cal.component(.year, from: now))

        guard let url = URL(string: "https://platform.deepseek.com/api/v0/usage/amount?month=\(month)&year=\(year)") else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        req.setValue("https://platform.deepseek.com/usage", forHTTPHeaderField: "Referer")
        req.timeoutInterval = 15
        let (data, response) = try await session.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        switch httpResponse.statusCode {
        case 200...299: break
        case 401, 403: throw APIError.unauthorized
        case 500...599: throw APIError.serverError(httpResponse.statusCode)
        default: throw APIError.httpError(httpResponse.statusCode)
        }

        // Decode with manual type-based parsing
        struct AmountResponse: Decodable {
            let data: AmountData?
        }
        struct AmountData: Decodable {
            let bizData: AmountBizData?
            enum CodingKeys: String, CodingKey {
                case bizData = "biz_data"
            }
        }
        struct AmountBizData: Decodable {
            let total: [AmountModel]?
        }
        struct AmountModel: Decodable {
            let model: String?
            let usage: [AmountEntry]?
        }
        struct AmountEntry: Decodable {
            let type: String?
            let amount: String?
        }

        let decoded = try JSONDecoder().decode(AmountResponse.self, from: data)
        guard let totals = decoded.data?.bizData?.total else {
            throw APIError.noCostData
        }

        var result: [ModelUsage] = []
        for modelEntry in totals {
            guard let modelName = modelEntry.model, let usage = modelEntry.usage else { continue }
            var totalTokens = 0
            var totalRequests = 0
            for entry in usage {
                guard let type = entry.type, let amt = entry.amount, let val = Int(amt) else { continue }
                switch type {
                case "PROMPT_TOKEN", "PROMPT_CACHE_HIT_TOKEN", "PROMPT_CACHE_MISS_TOKEN", "RESPONSE_TOKEN":
                    totalTokens += val
                case "REQUEST":
                    totalRequests += val
                default:
                    break
                }
            }
            result.append(ModelUsage(model: modelName, totalTokens: totalTokens, totalRequests: totalRequests))
        }
        return result
    }
}

enum APIError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError(Int)
    case httpError(Int)
    case decodingFailed(Error)
    case noData
    case noPlatformToken
    case noCostData

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "API key not configured"
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .unauthorized: return "API key is invalid or expired"
        case .rateLimited: return "Rate limited — too many requests"
        case .serverError(let code): return "Server error (\(code))"
        case .httpError(let code): return "HTTP error (\(code))"
        case .decodingFailed: return "Failed to parse server response"
        case .noData: return "No balance data available"
        case .noPlatformToken: return "未配置平台 Token"
        case .noCostData: return "无消费数据"
        }
    }
}
