import SwiftUI

struct MenuBarContentView: View {

    // MARK: - Environment
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) private var openURL

    // MARK: - UI
    var body: some View {
        MenuBarStatusView(
            isRefreshing: appState.isRefreshing,
            isOffline: appState.isOffline,
            hasEnabledAccounts: appState.hasEnabledAccounts,
            error: appState.lastError ?? appState.aggregatedError,
            prCount: appState.prCount,
            lastUpdated: appState.lastUpdated,
            onConfigureToken: {
                openWindow(id: "token-prompt")
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
                        PRListItemView(pr: pr) {
                            if let url = URL(string: pr.htmlURL) {
                                openURL(url)
                            }
                        }
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

        Button {
            Task {
                await appState.manualRefresh()
            }
        } label: {
            if #available(macOS 15.0, *) {
                Label("Refresh Now", systemImage: "arrow.clockwise")
                    .symbolEffect(.rotate, options: .speed(0.5), isActive: appState.isRefreshing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
            } else {
                Label("Refresh Now", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
            }
        }
        .buttonStyle(.plain)
        .keyboardShortcut("r", modifiers: .command)
        .accessibilityLabel("Refresh pull requests")

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
}

// MARK: - Preview
#Preview {
    MenuBarContentView()
        .environment(AppState())
}
