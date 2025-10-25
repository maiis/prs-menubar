import SwiftUI

struct DisplaySettingsTab: View {
    // MARK: - Environment
    @Environment(AppState.self) private var appState

    // MARK: - State
    @AppStorage(UserDefaults.sortNewestFirstKey) private var sortNewestFirst = true
    @AppStorage(UserDefaults.filterDraftsKey) private var filterDrafts = false
    @AppStorage(UserDefaults.groupByRepoKey) private var groupByRepo = false
    @AppStorage(UserDefaults.excludedLabelsKey) private var excludedLabels = ""

    // MARK: - UI
    var body: some View {
        Form {
            Section {
                Toggle("Sort Newest First", isOn: $sortNewestFirst)
                    .onChange(of: sortNewestFirst) { _, _ in
                        Task {
                            await appState.manualRefresh()
                        }
                    }
            } header: {
                Text("Sorting")
                    .font(.headline)
            } footer: {
                Text(
                    "Pull requests are sorted by their last updated date. Choose whether to show the newest or oldest PRs first."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Hide Draft PRs", isOn: $filterDrafts)
                    .onChange(of: filterDrafts) { _, _ in
                        Task {
                            await appState.manualRefresh()
                        }
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Exclude Labels:")
                        .font(.subheadline)

                    TextField("bug, wontfix, dependencies", text: $excludedLabels)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: excludedLabels) { _, _ in
                            Task {
                                await appState.manualRefresh()
                            }
                        }
                }
            } header: {
                Text("Filtering")
                    .font(.headline)
            } footer: {
                Text(
                    "Hide draft PRs and exclude PRs with specific labels. Enter comma-separated label names (case-insensitive). Supported by GitHub, GitLab, and Gitea."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Group by Repository", isOn: $groupByRepo)
                    .onChange(of: groupByRepo) { _, _ in
                        Task {
                            await appState.manualRefresh()
                        }
                    }
            } header: {
                Text("Grouping")
                    .font(.headline)
            } footer: {
                Text("Organize pull requests by repository name for easier navigation across multiple projects.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    DisplaySettingsTab()
        .environment(AppState.shared)
        .frame(width: 550, height: 450)
}
