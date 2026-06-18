import SwiftUI

struct MenuBarContentView: View {

    // MARK: - Environment
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openURL) private var openURL

    // MARK: - State
    /// Measured natural height of the card list, so the popover fits its content up to `maxListHeight`.
    @State private var contentHeight: CGFloat = 320

    // MARK: - Constants
    /// Caps the list height; ~7-8 cards fit before it starts scrolling.
    private let maxListHeight: CGFloat = 720

    // MARK: - UI
    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            content

            Divider()

            footer
        }
        .frame(width: 360)
        .avatarImageCache()
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 8) {
            Text("Pull Requests")
                .font(.headline)

            if appState.hasEnabledAccounts, appState.prCount > 0 {
                Text("\(appState.prCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.tint))
                    .foregroundStyle(.white)
            }

            Spacer()

            if appState.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }

            Button(action: refresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("r", modifiers: .command)
            .disabled(appState.isRefreshing)
            .help("Refresh now")
            .accessibilityLabel("Refresh pull requests")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        if !appState.prs.isEmpty {
            cardList
        } else {
            placeholder
                .frame(maxWidth: .infinity, minHeight: 280)
                .padding()
        }
    }

    /// Single card layout for all systems. Swipe is enabled on macOS 27 via
    /// `swipeActionsContainer()`; on macOS 26 the same Open/Copy actions live in each
    /// row's context menu (right-click).
    private var cardList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(appState.groupedPRs, id: \.0) { repoName, prs in
                    Section {
                        ForEach(prs) { pr in
                            row(for: pr, showRepoName: repoName.isEmpty)
                        }
                    } header: {
                        sectionHeader(repoName)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                contentHeight = height
            }
        }
        .frame(height: min(contentHeight, maxListHeight))
        .modifier(SwipeContainerIfAvailable())
    }

    @ViewBuilder
    private var placeholder: some View {
        if appState.isRefreshing {
            ProgressView()
                .controlSize(.small)
        } else if let displayError = appState.displayError {
            ErrorStateView(
                error: displayError.error,
                additionalAccountsAffected: displayError.additionalAccountsAffected,
                onConfigureToken: openSettingsWindow,
                onRetry: refresh
            )
        } else if appState.isOffline {
            OfflineStateView(onRetry: refresh)
        } else if appState.hasEnabledAccounts {
            EmptyStateView()
        } else {
            NoAccountsStateView {
                openWindow(id: "onboarding")
            }
        }
    }

    // MARK: - Footer
    private var footer: some View {
        HStack(spacing: 12) {
            SettingsLink {
                Label("Settings", systemImage: "gear")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(",", modifiers: .command)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers
    /// A PR card with leading (open) / trailing (copy) swipe actions plus a matching context menu.
    private func row(for pr: PullRequest, showRepoName: Bool) -> some View {
        PRListItemView(pr: pr, prependRepoName: showRepoName)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    openPR(pr)
                } label: {
                    Label("Open", systemImage: "safari")
                }
                .tint(.blue)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    copyURL(pr)
                } label: {
                    Label("Copy URL", systemImage: "doc.on.doc")
                }
                .tint(.gray)
            }
            .contextMenu {
                Button {
                    openPR(pr)
                } label: {
                    Label("Open in Browser", systemImage: "safari")
                }
                Button {
                    copyURL(pr)
                } label: {
                    Label("Copy URL", systemImage: "doc.on.doc")
                }
            }
    }

    @ViewBuilder
    private func sectionHeader(_ repoName: String) -> some View {
        if !repoName.isEmpty {
            let parts = repoName.split(separator: "/", maxSplits: 1).map(String.init)
            HStack(spacing: 0) {
                if parts.count == 2 {
                    Text("\(parts[0])/")
                        .foregroundStyle(.tertiary)
                    Text(parts[1])
                        .foregroundStyle(.secondary)
                } else {
                    Text(repoName)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            .fontWeight(.semibold)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 3)
        }
    }

    // MARK: - Actions
    private func refresh() {
        Task {
            await appState.manualRefresh()
        }
    }

    private func openPR(_ pr: PullRequest) {
        if let url = URL(string: pr.htmlURL) {
            openURL(url)
        }
    }

    private func copyURL(_ pr: PullRequest) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(pr.htmlURL, forType: .string)
    }

    private func openSettingsWindow() {
        // Activate first: a menu bar app may be in the background, and the Settings
        // scene's onAppear only handles activation when the window (re)appears.
        NSApp.activate()
        openSettings()
    }
}

// MARK: - SwipeContainerIfAvailable
/// Enables swipe actions on the scrollable container on macOS 27 (`swipeActionsContainer()`),
/// and is a no-op on macOS 26 where rows fall back to their context menu.
private struct SwipeContainerIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 27.0, *) {
            content.swipeActionsContainer()
        } else {
            content
        }
    }
}

// MARK: - Preview
#Preview {
    MenuBarContentView()
        .environment(AppState(githubService: DemoGitHubService.shared))
}
