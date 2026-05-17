import Foundation

struct CostResponse: Decodable {
    let data: CostData?
}

struct CostData: Decodable {
    let bizData: [BizData]?

    enum CodingKeys: String, CodingKey {
        case bizData = "biz_data"
    }
}

struct BizData: Decodable {
    let currency: String?
    let days: [CostDay]?
    let total: [CostModelTotal]?
}

struct CostDay: Decodable {
    let date: String
    let data: [CostModelItem]?
}

struct CostModelItem: Decodable {
    let model: String?
    let usage: [CostUsage]?
}

struct CostUsage: Decodable {
    let amount: String?
    let promptTokens: Int?
    let completionTokens: Int?
    let requests: Int?

    enum CodingKeys: String, CodingKey {
        case amount
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case requests
    }
}

struct CostModelTotal: Decodable {
    let model: String?
    let usage: [CostUsage]?
}

struct ModelUsage: Identifiable {
    let id = UUID()
    let model: String
    let totalTokens: Int
    let totalRequests: Int
}

struct DailyUsageStats: Identifiable {
    let id = UUID()
    let date: String
    let promptTokens: Int
    let completionTokens: Int
    let requests: Int
}

struct ModelUsageSummary: Identifiable {
    let id = UUID()
    let model: String
    let totalTokens: Int
    let totalRequests: Int
    let percentage: Double
}

struct MonthlyCostInfo {
    let currency: String
    let totalSpent: Double
    let dailyCount: Int
    let dailyUsage: [DailyUsageStats]
    let modelSummary: [ModelUsageSummary]
    let todayModelCost: [String: Double]
}
