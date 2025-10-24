import SwiftUI

struct SettingsView: View {

    // MARK: - Environment
    @Environment(AppState.self) private var appState

    // MARK: - AppStorage
    @AppStorage(UserDefaults.refreshIntervalKey) private var refreshInterval = 600.0
    @AppStorage(UserDefaults.sortNewestFirstKey) private var sortNewestFirst = true
    @AppStorage(UserDefaults.filterDraftsKey) private var filterDrafts = false
    @AppStorage(UserDefaults.groupByRepoKey) private var groupByRepo = false

    // MARK: - UI
    var body: some View {
        Form {
            Section {
                AccountsListView()
                    .environment(appState)
            } header: {
                Text("Accounts")
            } footer: {
                Text("Configure your Git service accounts to track pull requests across multiple providers.")
                    .font(.caption)
            }
            
            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { LaunchAtLoginManager.shared.isEnabled },
                    set: { _ in LaunchAtLoginManager.shared.toggle() }
                ))

                Picker("Refresh Interval", selection: $refreshInterval) {
                    Text("5 minutes").tag(300.0)
                    Text("10 minutes").tag(600.0)
                    Text("15 minutes").tag(900.0)
                    Text("30 minutes").tag(1800.0)
                }
                .onChange(of: refreshInterval) { _, _ in
                    appState.restartRefreshTimer()
                }

                Toggle("Sort Newest First", isOn: $sortNewestFirst)
                    .onChange(of: sortNewestFirst) { _, _ in
                        Task {
                            await appState.manualRefresh()
                        }
                    }

                Toggle("Hide Draft PRs", isOn: $filterDrafts)
                    .onChange(of: filterDrafts) { _, _ in
                        Task {
                            await appState.manualRefresh()
                        }
                    }

                Toggle("Group by Repository", isOn: $groupByRepo)
                    .onChange(of: groupByRepo) { _, _ in
                        Task {
                            await appState.manualRefresh()
                        }
                    }
            } header: {
                Text("General")
            } footer: {
                Text(
                    "Pull requests are sorted by last updated date. Draft PRs may still need work before review. Grouping organizes PRs by repository name."
                )
                .font(.caption)
            }

            Section {
                LabeledContent("App Version") {
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Bundle ID") {
                    Text("me.maiis.prsmenubar")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            } header: {
                Text("About")
            }

            if let destination = URL(string: "https://buymeacoffee.com/maiis") {
                Section {
                    Link(destination: destination) {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                            Text("Buy Me a Coffee")
                        }
                    }
                } header: {
                    Text("Support")
                } footer: {
                    Text("If you find this app useful, consider supporting its development!")
                        .font(.caption)
                }
            }

            Section {
                Toggle("Demo Mode", isOn: Binding(
                    get: { appState.isDemoMode },
                    set: { appState.setDemoMode($0) }
                ))
            } header: {
                Text("App Review")
            } footer: {
                Text("Enable demo mode to preview the app with sample pull requests. No token required.")
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 650)
    }

    // MARK: - Getters
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
