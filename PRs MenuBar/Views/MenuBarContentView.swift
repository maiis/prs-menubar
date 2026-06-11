import AppKit
import SwiftUI

struct MenuBarContentView: View {

    // MARK: - Environment
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    // MARK: - UI
    var body: some View {
        MenuBarStatusView(
            isRefreshing: appState.isRefreshing,
            isOffline: appState.isOffline,
            hasEnabledAccounts: appState.hasEnabledAccounts,
            displayError: appState.displayError,
            prCount: appState.prCount,
            onConfigureToken: {
                openSettings()
            },
            onRetry: {
                Task {
                    await appState.manualRefresh()
                }
            }
        )

        Divider()

        if !appState.prs.isEmpty {
            ForEach(appState.groupedPRs, id: \.0) { repoName, prs in
                Section {
                    ForEach(prs) { pr in
                        // When grouped (repoName non-empty), the group header shows the repo,
                        // so the row doesn't need to repeat it.
                        PRListItemView(pr: pr, prependRepoName: repoName.isEmpty)
                    }
                } header: {
                    if !repoName.isEmpty {
                        Text(repoName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
            }
        } else if !appState.isRefreshing, appState.lastError == nil, !appState.isOffline {
            if appState.hasEnabledAccounts {
                EmptyStateView()
            } else {
                NoAccountsStateView {
                    openWindow(id: "onboarding")
                }
            }
        }

        Divider()

        refreshButton

        SettingsLink {
            Label("Settings...", systemImage: "gear")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("Quit")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
        .keyboardShortcut("q", modifiers: .command)
    }

    // MARK: - Helpers
    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    private var refreshButton: some View {
        Button {
            Task {
                await appState.manualRefresh()
            }
        } label: {
            Label("Refresh Now", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
        .keyboardShortcut("r", modifiers: .command)
        .accessibilityLabel("Refresh pull requests")
        .disabled(appState.isRefreshing)
    }
}

// MARK: - Preview
#Preview {
    MenuBarContentView()
        .environment(AppState(githubService: DemoGitHubService.shared))
}
