import SwiftUI

@main
struct DeepSeekMenubarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra {
            if viewModel.isConfigured {
                MainContentView(viewModel: viewModel)
            } else {
                SetupView(viewModel: viewModel)
            }
        } label: {
            MenuBarLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    let viewModel: AppViewModel

    var body: some View {
        if viewModel.isConfigured {
            if viewModel.isLoadingBalance && viewModel.balance == nil {
                Text("···")
                    .fontWeight(.medium)
            } else if let balance = viewModel.balance {
                HStack(spacing: 4) {
                    if viewModel.isLowBalance {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                    Text("\(balance.currencySymbol)\(balance.totalBalance)")
                        .font(.system(.body, design: .monospaced, weight: .medium))
                        .monospacedDigit()
                }
            } else {
                Image(systemName: "wifi.slash")
            }
        } else {
            Image(systemName: "key.fill")
                .font(.caption)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

