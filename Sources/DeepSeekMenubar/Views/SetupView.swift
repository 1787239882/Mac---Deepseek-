import SwiftUI

struct SetupView: View {
    @Bindable var viewModel: AppViewModel
    @State private var apiKey = ""

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.largeTitle)
                .foregroundStyle(.blue)
            Text("DeepSeek Usage")
                .font(.headline)
            Text("请在下方输入你的 DeepSeek API Key\n可在 platform.deepseek.com 获取")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            SecureField("sk-...", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .fontDesign(.monospaced)
                .frame(width: 280)
            Button("确认") {
                guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                viewModel.configureAndStart(apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines), platformToken: nil)
            }
            .buttonStyle(.borderedProminent)
            .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(24)
        .frame(width: 340)
        .overlay(alignment: .bottomTrailing) {
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(8)
        }
    }
}
