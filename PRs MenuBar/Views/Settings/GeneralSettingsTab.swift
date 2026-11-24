import OSLog
import ServiceManagement
import SwiftUI

struct GeneralSettingsTab: View {

    // MARK: - Environment
    @Environment(AppState.self) private var appState

    // MARK: - State
    @AppStorage(UserDefaults.refreshIntervalKey) private var refreshInterval = 600.0
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    // MARK: - UI
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
            } header: {
                Text("Startup")
                    .font(.headline)
            } footer: {
                Text("Automatically start PRs MenuBar when you log in to your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Refresh Interval", selection: $refreshInterval) {
                    Text("5 minutes").tag(300.0)
                    Text("10 minutes").tag(600.0)
                    Text("15 minutes").tag(900.0)
                    Text("30 minutes").tag(1800.0)
                }
                .onChange(of: refreshInterval) { _, _ in
                    appState.restartRefreshTimer()
                }
            } header: {
                Text("Updates")
                    .font(.headline)
            } footer: {
                Text("How often the app checks for new pull requests. More frequent updates may impact battery life.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            #if DEBUG
                Section {
                    Button("Reset to Onboarding") {
                        resetToOnboarding()
                    }
                    .foregroundStyle(.red)
                } header: {
                    Text("Debug")
                        .font(.headline)
                } footer: {
                    Text("Remove all accounts and reset to onboarding state. The app will quit. Debug builds only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            #endif
        }
        .formStyle(.grouped)
    }

    // MARK: - Actions
    private func setLaunchAtLogin(_ enabled: Bool) {
        // Also stops the re-entry when the sync below writes `launchAtLogin` back.
        guard enabled != (SMAppService.mainApp.status == .enabled) else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            AppLogger.app.info("Launch at login \(enabled ? "enabled" : "disabled")")
        } catch {
            AppLogger.error.error("Failed to toggle launch at login: \(error.localizedDescription)")
        }
        // Reflect what the system actually did, e.g. when registration needs user approval.
        let actual = SMAppService.mainApp.status == .enabled
        if actual != launchAtLogin {
            launchAtLogin = actual
        }
    }

    #if DEBUG
        private func resetToOnboarding() {
            let accountManager = AccountManager.shared
            // Removes each account's keychain token too.
            for account in accountManager.getAccounts() {
                try? accountManager.removeAccount(account)
            }
            // Wipes every preference, including the onboarding flag.
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            // Quit the app - it will relaunch in onboarding mode
            NSApplication.shared.terminate(nil)
        }
    #endif
}

// MARK: - Preview
#Preview {
    GeneralSettingsTab()
        .environment(AppState.shared)
        .frame(width: 550, height: 450)
}
