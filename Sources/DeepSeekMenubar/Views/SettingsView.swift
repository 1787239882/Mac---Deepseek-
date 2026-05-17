import SwiftUI

struct SettingsInlineView: View {
    @Bindable var viewModel: AppViewModel
    @Binding var isPresented: Bool

    @State private var apiKey: String = ""
    @State private var platformToken: String = ""
    @State private var refreshInterval: Double = 60
    @State private var lowBalanceThreshold: Double = 5.0
    @State private var launchAtLogin: Bool = false

    var body: some View {
        VStack(spacing: 14) {
            // 顶部标题栏
            HStack {
                Button { isPresented = false } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                Spacer()
                Text("偏好设置")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }

            Divider()

            // API Key
            VStack(alignment: .leading, spacing: 4) {
                Text("DeepSeek API Key")
                    .font(.caption.weight(.medium))
                SecureField("sk-...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .fontDesign(.monospaced)
                Text("用于查询余额，可在 platform.deepseek.com 获取")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // 平台 Token（可选）
            VStack(alignment: .leading, spacing: 4) {
                Text("平台 Token（可选）")
                    .font(.caption.weight(.medium))
                SecureField("userToken...", text: $platformToken)
                    .textFieldStyle(.roundedBorder)
                    .fontDesign(.monospaced)
                Text("用于本月消费统计。获取：登录 platform.deepseek.com → F12 → Application → Local Storage → 复制 userToken")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            // 刷新间隔
            VStack(alignment: .leading, spacing: 4) {
                Text("刷新间隔: \(Int(refreshInterval)) 秒")
                    .font(.caption.weight(.medium))
                Slider(value: $refreshInterval, in: 15...300, step: 15)
            }

            // 低余额阈值
            VStack(alignment: .leading, spacing: 4) {
                Text("低余额警告阈值: ¥\(Int(lowBalanceThreshold))")
                    .font(.caption.weight(.medium))
                Slider(value: $lowBalanceThreshold, in: 0...50, step: 1)
            }

            Toggle("开机自启", isOn: $launchAtLogin)
                .font(.caption)

            Divider()

            // 保存按钮
            HStack {
                Spacer()
                Button("保存") {
                    let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    let token = platformToken.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !key.isEmpty {
                        viewModel.configureAndStart(apiKey: key, platformToken: token.isEmpty ? nil : token)
                    }
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .frame(width: 300)
        .onAppear {
            apiKey = (try? KeychainManager.load()) ?? ""
            platformToken = (try? KeychainManager.load(account: .platformTokenAccount)) ?? ""
            refreshInterval = PreferencesManager.shared.refreshInterval
            lowBalanceThreshold = PreferencesManager.shared.lowBalanceThreshold
            launchAtLogin = PreferencesManager.shared.launchAtLogin
        }
        .onChange(of: refreshInterval) { _, newValue in
            PreferencesManager.shared.refreshInterval = newValue
        }
        .onChange(of: lowBalanceThreshold) { _, newValue in
            PreferencesManager.shared.lowBalanceThreshold = newValue
        }
        .onChange(of: launchAtLogin) { _, newValue in
            PreferencesManager.shared.launchAtLogin = newValue
        }
    }
}
