import Foundation
import Observation

@MainActor
@Observable
final class AppViewModel {
    var balance: BalanceInfo?
    var monthlyCost: MonthlyCostInfo?
    var usageStats: [ModelUsage] = []
    var isLoadingBalance = false
    var isLoadingCost = false
    var isLoadingUsage = false
    var balanceError: String?
    var costError: String?
    var usageError: String?
    var isConfigured = false
    var lastUpdated: Date?

    private let api = DeepSeekAPIService.shared
    private let prefs = PreferencesManager.shared
    private var refreshTask: Task<Void, Never>?

    init() {
        checkConfiguration()
    }

    var isLowBalance: Bool {
        guard let balance, let value = Double(balance.totalBalance) else { return false }
        return value < prefs.lowBalanceThreshold
    }

    func checkConfiguration() {
        guard let key = try? KeychainManager.load(), !key.isEmpty else {
            isConfigured = false
            return
        }
        isConfigured = true
        let platformToken = try? KeychainManager.load(account: .platformTokenAccount)
        Task { await api.configure(apiKey: key, platformToken: platformToken) }
        startAutoRefresh()
    }

    func configureAndStart(apiKey: String, platformToken: String?) {
        try? KeychainManager.save(key: apiKey)
        if let token = platformToken, !token.isEmpty {
            try? KeychainManager.save(key: token, account: .platformTokenAccount)
        }
        isConfigured = true
        Task { await api.configure(apiKey: apiKey, platformToken: platformToken) }
        startAutoRefresh()
        Task { await refreshAll() }
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshBalance() }
            group.addTask { await self.refreshCost() }
            group.addTask { await self.refreshUsage() }
        }
        lastUpdated = Date()
    }

    func refreshBalance() async {
        isLoadingBalance = true
        balanceError = nil
        do {
            balance = try await api.fetchBalance()
        } catch {
            balanceError = error.localizedDescription
        }
        isLoadingBalance = false
    }

    func refreshCost() async {
        isLoadingCost = true
        costError = nil
        do {
            monthlyCost = try await api.fetchMonthlyCost()
        } catch {
            costError = error.localizedDescription
        }
        isLoadingCost = false
    }

    func refreshUsage() async {
        isLoadingUsage = true
        usageError = nil
        do {
            usageStats = try await api.fetchUsageAmount()
        } catch {
            usageError = error.localizedDescription
        }
        isLoadingUsage = false
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.prefs.refreshInterval ?? 60))
                guard !Task.isCancelled else { break }
                await self?.refreshAll()
            }
        }
    }
}

extension String {
    static let platformTokenAccount = "platform-token"
}
