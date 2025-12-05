import OSLog
import ServiceManagement

@MainActor
@Observable
class LaunchAtLoginManager {

    // MARK: - Singleton
    static let shared = LaunchAtLoginManager()

    // MARK: - Init
    private init() {}

    // MARK: - Computed Properties
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
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
        } catch {
            AppLogger.error.error("Failed to toggle launch at login: \(error.localizedDescription)")
        }
    }
}
