import SwiftUI

struct MainContentView: View {
    @Bindable var viewModel: AppViewModel
    @State private var showSettings = false
    @State private var showUsageDetail = false

    var body: some View {
        if showSettings {
            SettingsInlineView(viewModel: viewModel, isPresented: $showSettings)
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        VStack(spacing: 8) {
            headerView

            if let balance = viewModel.balance {
                BalanceCard(
                    balance: balance,
                    isLow: viewModel.isLowBalance,
                    monthlyCost: viewModel.monthlyCost,
                    isLoadingCost: viewModel.isLoadingCost,
                    costError: viewModel.costError
                )
            } else if viewModel.isLoadingBalance {
                BalanceLoadingSkeleton()
            } else {
                BalanceErrorView(error: viewModel.balanceError)
            }

            usageSection

            footerView
        }
        .padding(12)
        .frame(width: 300)
        .onAppear {
            if viewModel.isConfigured {
                Task { await viewModel.refreshAll() }
            }
        }
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.caption)
                .foregroundStyle(.green)
            Text("DeepSeek")
                .font(.subheadline.weight(.medium))
            Spacer()
            if let last = viewModel.lastUpdated {
                Text(last, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var usageSection: some View {
        if !viewModel.usageStats.isEmpty {
            usageSummaryRow

            if showUsageDetail {
                perModelStats
            }
        } else if viewModel.isLoadingUsage && viewModel.usageStats.isEmpty {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(width: 120, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(width: 80, height: 10)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } else if viewModel.usageError != nil {
            VStack(spacing: 4) {
                Text("用量明细与历史趋势")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("请在网页端查看详细用量数据")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var usageSummaryRow: some View {
        let totalTokens = viewModel.usageStats.reduce(0) { $0 + $1.totalTokens }
        let totalRequests = viewModel.usageStats.reduce(0) { $0 + $1.totalRequests }

        return Button {
            showUsageDetail.toggle()
        } label: {
            HStack {
                Image(systemName: showUsageDetail ? "chevron.down" : "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("用量明细")
                    .font(.caption)
                    .foregroundStyle(.primary)
                Spacer()
                HStack(spacing: 4) {
                    Text(formatNumber(totalTokens))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text("\(formatNumber(totalRequests)) 请求")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var perModelStats: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.usageStats) { model in
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.model)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)

                    HStack {
                        Text("今日消费")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        let cost = viewModel.monthlyCost?.todayModelCost[model.model] ?? 0
                        let symbol = viewModel.monthlyCost?.currency == "CNY" ? "¥" : "$"
                        Text("\(symbol)\(String(format: "%.2f", cost))")
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }

                    HStack {
                        Text("Tokens")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatNumber(model.totalTokens))
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }

                    HStack {
                        Text("API 请求次数")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatNumber(model.totalRequests))
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }
                }
                if model.model != viewModel.usageStats.last?.model {
                    Divider()
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private var footerView: some View {
        HStack(spacing: 4) {
            Button("偏好设置") {
                showSettings = true
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.blue)

            Spacer()

            Button("刷新") {
                Task { await viewModel.refreshAll() }
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.blue)
            .disabled(viewModel.isLoadingBalance || viewModel.isLoadingCost || viewModel.isLoadingUsage)

            Button("View on Web") {
                if let url = URL(string: "https://platform.deepseek.com/usage") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.blue)

            Text("·")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
    }
}

private struct BalanceLoadingSkeleton: View {
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .frame(width: 80, height: 20)
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .frame(width: 100, height: 14)
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct BalanceErrorView: View {
    let error: String?

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.red)
            Text(error ?? "无法获取余额")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
