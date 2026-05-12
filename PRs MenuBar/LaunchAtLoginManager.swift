import OSLog
import ServiceManagement

@MainActor
@Observable
final class LaunchAtLoginManager {

    // MARK: - Singleton
    static let shared = LaunchAtLoginManager()

    // MARK: - State
    private(set) var isEnabled: Bool

    // MARK: - Init
    private init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    // MARK: - Actions
    func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
                AppLogger.app.info("Launch at login disabled")
            } else {
                try SMAppService.mainApp.register()
                AppLogger.app.info("Launch at login enabled")
            }
            isEnabled = SMAppService.mainApp.status == .enabled
        } catch {
            AppLogger.error.error("Failed to toggle launch at login: \(error.localizedDescription)")
            isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
}
