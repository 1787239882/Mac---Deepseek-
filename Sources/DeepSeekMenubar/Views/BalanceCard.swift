import SwiftUI

struct BalanceCard: View {
    let balance: BalanceInfo
    let isLow: Bool
    let monthlyCost: MonthlyCostInfo?
    let isLoadingCost: Bool
    let costError: String?

    var body: some View {
        HStack(spacing: 12) {
            // 余额
            HStack(spacing: 10) {
                Image(systemName: isLow ? "exclamationmark.triangle.fill" : "dollarsign.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isLow ? .yellow : .green)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(balance.currencySymbol)\(balance.totalBalance)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(isLow ? .yellow : .primary)
                    Text("账户余额")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Divider()
                .frame(height: 32)

            // 本月消费
            HStack(spacing: 10) {
                Image(systemName: "creditcard.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 1) {
                    if isLoadingCost && monthlyCost == nil {
                        Text("···")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .monospacedDigit()
                    } else if let cost = monthlyCost {
                        Text("\(cost.currency == "CNY" ? "¥" : "$")\(String(format: "%.2f", cost.totalSpent))")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .monospacedDigit()
                    } else if let err = costError {
                        Text(err.prefix(12) + (err.count > 12 ? "…" : ""))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    } else {
                        Text("—")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    Text("本月消费")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
