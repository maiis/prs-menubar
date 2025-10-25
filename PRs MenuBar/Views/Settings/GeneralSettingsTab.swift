import SwiftUI

struct GeneralSettingsTab: View {
    @Environment(AppState.self) private var appState
    @AppStorage(UserDefaults.refreshIntervalKey) private var refreshInterval = 600.0

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

            Divider()
                .padding(.vertical, 8)

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
        }
        .formStyle(.grouped)
    }
}

#Preview {
    GeneralSettingsTab()
        .environment(AppState.shared)
        .frame(width: 550, height: 450)
}
