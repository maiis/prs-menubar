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
    /// View-local: through `AppState` this would cost an @Observable notification per arrow key.
    @State private var selectedPRID: PullRequest.ID?
    @FocusState private var isListFocused: Bool

    // MARK: - Settings
    @AppStorage(UserDefaults.showAvatarsKey) private var showAvatars = true
    @AppStorage(UserDefaults.showLabelsKey) private var showLabels = true

    // MARK: - Constants
    /// Caps the list height; ~7-8 cards fit before it starts scrolling.
    private let maxListHeight: CGFloat = 720

    // MARK: - UI
    var body: some View {
        VStack(spacing: 0) {
            errorBanner

            content

            Divider()

            footer
        }
        .frame(width: 360)
        .avatarImageCache()
        // The window keeps this view alive between openings, so the selection has to be cleared
        // explicitly or a stale highlight is still sitting there on the next open.
        .onDisappear { selectedPRID = nil }
    }

    // MARK: - Error Banner
    /// The placeholder states only render when there are no cards, so without this a failing
    /// account is invisible in the panel whenever another account still returned pull requests.
    @ViewBuilder
    private var errorBanner: some View {
        if !appState.prs.isEmpty {
            if let displayError = appState.displayError {
                banner(
                    icon: "exclamationmark.triangle.fill",
                    tint: .orange,
                    message: displayError.message,
                    actionTitle: displayError.error.requiresTokenUpdate ? "Update Token" : "Retry",
                    action: displayError.error.requiresTokenUpdate ? openSettingsWindow : refresh
                )
            } else if appState.isOffline {
                // Offline before any request has failed: the cards below are the last good fetch.
                banner(
                    icon: "wifi.slash",
                    tint: .secondary,
                    message: "No connection. Showing the pull requests from the last refresh.",
                    actionTitle: "Retry",
                    action: refresh
                )
            }
        }
    }

    private func banner(
        icon: String,
        tint: some ShapeStyle,
        message: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)

                Text(message)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button(actionTitle, action: action)
            }
            .font(.caption)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()
        }
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
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(appState.groupedPRs, id: \.0) { repoName, prs in
                        Section {
                            ForEach(prs) { pr in
                                row(for: pr, showRepoName: repoName.isEmpty)
                                    .id(pr.id)
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
            .swipeContainerIfAvailable()
            .onChange(of: selectedPRID) { _, id in
                guard let id else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    scrollProxy.scrollTo(id, anchor: .center)
                }
            }
        }
        // A window, not an NSMenu — arrow-key traversal is ours to build.
        .focusable()
        .focusEffectDisabled()
        .focused($isListFocused)
        .onKeyPress(.downArrow) { moveSelection(by: 1) }
        .onKeyPress(.upArrow) { moveSelection(by: -1) }
        .onKeyPress(.return) { openSelection() }
        .onAppear {
            selectedPRID = nil
            isListFocused = true
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if appState.isRefreshing {
            ProgressView()
                .controlSize(.small)
        } else if let displayError = appState.displayError {
            ErrorStateView(
                displayError: displayError,
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
            if appState.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("r", modifiers: .command)
                .help("Refresh now")
                .accessibilityLabel("Refresh pull requests")
            }

            Spacer()

            Menu {
                Button("Settings…", action: openSettingsWindow)
                    .keyboardShortcut(",", modifiers: .command)

                Divider()

                Button("Quit PRs MenuBar") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("More")
            .accessibilityLabel("More options")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers
    /// A PR card with leading (open) / trailing (copy) swipe actions plus a matching context menu.
    private func row(for pr: PullRequest, showRepoName: Bool) -> some View {
        PRListItemView(
            pr: pr,
            prependRepoName: showRepoName,
            isSelected: pr.id == selectedPRID,
            showAvatar: showAvatars,
            showLabels: showLabels
        )
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            openButton(for: pr).tint(.blue)
        }
        .swipeActions(edge: .trailing) {
            copyButton(for: pr).tint(.gray)
        }
        .contextMenu {
            openButton(for: pr)
            copyButton(for: pr)
        }
    }

    private func openButton(for pr: PullRequest) -> some View {
        Button {
            openPR(pr)
        } label: {
            Label("Open", systemImage: "safari")
        }
    }

    private func copyButton(for pr: PullRequest) -> some View {
        Button {
            copyURL(pr)
        } label: {
            Label("Copy URL", systemImage: "doc.on.doc")
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

    // MARK: - Keyboard Navigation
    /// Wraps at both ends like an NSMenu. With nothing selected, down starts at the top and up
    /// at the bottom.
    private func moveSelection(by offset: Int) -> KeyPress.Result {
        // Flattened across repository groups, so this follows the on-screen order.
        let ids = appState.groupedPRs.flatMap { $0.1.map(\.id) }
        guard !ids.isEmpty else { return .ignored }

        // A refresh can drop the selected PR.
        guard let current = selectedPRID, let index = ids.firstIndex(of: current) else {
            selectedPRID = offset > 0 ? ids.first : ids.last
            return .handled
        }

        selectedPRID = ids[(index + offset + ids.count) % ids.count]
        return .handled
    }

    private func openSelection() -> KeyPress.Result {
        guard let selectedPRID, let pr = appState.prs.first(where: { $0.id == selectedPRID }) else {
            return .ignored
        }
        openPR(pr)
        return .handled
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

// MARK: - Swipe Container
private extension View {
    /// Enables swipe actions on the scrollable container on macOS 27 (`swipeActionsContainer()`),
    /// and is a no-op on macOS 26 where rows fall back to their context menu.
    @ViewBuilder
    func swipeContainerIfAvailable() -> some View {
        if #available(macOS 27.0, *) {
            swipeActionsContainer()
        } else {
            self
        }
    }
}

// MARK: - Preview
#Preview("Loaded") {
    MenuBarContentView()
        .environment(AppState(githubService: DemoGitHubService.shared))
}

#Preview("Error Banner") {
    let appState = AppState(githubService: DemoGitHubService.shared)
    let account = ProviderAccount(provider: .gitlab, name: "GitLab")
    let dateFormatter = ISO8601DateFormatter()
    appState.setAccounts([account])
    appState.setAccountError(account.id, error: .unauthorized)
    appState.setPRs([
        PullRequest(
            id: "preview-pr-1",
            number: 226,
            title: "Fallback for an offer without title",
            htmlURL: "https://gitlab.com/qoqa/qoqa_partners/-/merge_requests/226",
            state: "open",
            isDraft: false,
            user: User(login: "coder"),
            createdAt: dateFormatter.string(from: Date().addingTimeInterval(-86400)),
            updatedAt: dateFormatter.string(from: Date().addingTimeInterval(-3060)),
            labels: ["bug"],
            labelColors: ["bug": "d73a4a"]
        )
    ])
    return MenuBarContentView()
        .environment(appState)
}
