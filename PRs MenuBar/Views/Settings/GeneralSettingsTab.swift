import SwiftUI

struct GeneralSettingsTab: View {

    // MARK: - Environment
    @Environment(AppState.self) private var appState

    // MARK: - State
    @AppStorage(UserDefaults.refreshIntervalKey) private var refreshInterval = 600.0

    // MARK: - UI
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { LaunchAtLoginManager.shared.isEnabled },
                    set: { _ in LaunchAtLoginManager.shared.toggle() }
                ))
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
    #if DEBUG
        private func resetToOnboarding() {
            let accountManager = AccountManager.shared

            // Remove all accounts (including keychain tokens)
            for account in accountManager.getAccounts() {
                try? accountManager.removeAccount(account)
            }

            // Delete legacy token (for migration cleanup)
            try? KeychainManager.deleteToken(for: "github-token")

            // Reset onboarding flag
            accountManager.hasCompletedOnboarding = false

            // Clear UserDefaults
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
                UserDefaults.standard.synchronize()
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
