import SwiftUI

struct SettingsView: View {

    // MARK: - State
    @State private var showTokenSheet = false
    @State private var showDeleteConfirmation = false
    @State private var tokenDeleted = false

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

            Section {
                Button("Update GitHub Token") {
                    tokenDeleted = false
                    showTokenSheet = true
                }

                Button("Delete Token") {
                    showDeleteConfirmation = true
                }
                .foregroundStyle(.red)

                if tokenDeleted {
                    Label("Token deleted successfully", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            } header: {
                Text("Authentication")
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
                Text("Enable demo mode to preview the app with sample pull requests. No GitHub token required.")
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 550)
        .sheet(isPresented: $showTokenSheet) {
            TokenPromptView()
                .environment(AppState.shared)
        }
        .confirmationDialog(
            "Are you sure you want to delete your GitHub token?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Token", role: .destructive) {
                deleteToken()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to enter a new token to continue using the app.")
        }
    }

    // MARK: - Getters
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    // MARK: - Actions
    private func deleteToken() {
        do {
            try KeychainManager.deleteToken()
            tokenDeleted = true
        } catch {
            tokenDeleted = false
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
