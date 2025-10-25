import SwiftUI

struct AppearanceSettingsTab: View {
    @Environment(AppState.self) private var appState
    @AppStorage(UserDefaults.sortNewestFirstKey) private var sortNewestFirst = true
    @AppStorage(UserDefaults.filterDraftsKey) private var filterDrafts = false
    @AppStorage(UserDefaults.groupByRepoKey) private var groupByRepo = false

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

            Divider()
                .padding(.vertical, 8)

            Section {
                Toggle("Hide Draft PRs", isOn: $filterDrafts)
                    .onChange(of: filterDrafts) { _, _ in
                        Task {
                            await appState.manualRefresh()
                        }
                    }
            } header: {
                Text("Filtering")
                    .font(.headline)
            } footer: {
                Text("Draft pull requests are still in progress and may not be ready for review yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.vertical, 8)

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
    AppearanceSettingsTab()
        .environment(AppState.shared)
        .frame(width: 550, height: 450)
}
