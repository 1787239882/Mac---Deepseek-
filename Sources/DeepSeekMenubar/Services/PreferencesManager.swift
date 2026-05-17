import Foundation
import ServiceManagement

final class PreferencesManager {
    static let shared = PreferencesManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let refreshInterval = "refreshInterval"
        static let lowBalanceThreshold = "lowBalanceThreshold"
        static let launchAtLogin = "launchAtLogin"
    }

    var refreshInterval: TimeInterval {
        get { defaults.object(forKey: Keys.refreshInterval) as? TimeInterval ?? 60 }
        set { defaults.set(newValue, forKey: Keys.refreshInterval) }
    }

    var lowBalanceThreshold: Double {
        get { defaults.object(forKey: Keys.lowBalanceThreshold) as? Double ?? 5.0 }
        set { defaults.set(newValue, forKey: Keys.lowBalanceThreshold) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            applyLaunchAtLogin(newValue)
        }
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            if enabled {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }
}
