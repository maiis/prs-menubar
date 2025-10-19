import SwiftUI

@main
struct PRsMenuBarApp: App {
    @State private var appState = AppState.shared
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(appState: appState)
                .environment(appState)
                .onAppear {
                    if KeychainManager.getToken() == nil {
                        openWindow(id: "token-prompt")
                    }
                }
                .onChange(of: appState.lastError) { _, newValue in
                    if let err = newValue, err.lowercased().contains("unauthorized") {
                        openWindow(id: "token-prompt")
                    }
                }
        } label: {
            MenuBarLabelView(
                prCount: appState.prCount,
                isRefreshing: appState.isRefreshing,
                hasError: appState.lastError != nil
            )
        }
        .menuBarExtraStyle(.menu)

        Window("GitHub Token", id: "token-prompt") {
            TokenPromptView()
                .environment(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Settings {
            SettingsView()
        }
    }
}

struct MenuBarContentView: View {
    @Bindable var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) private var openURL

    var body: some View {
        MenuBarStatusView(
            isRefreshing: appState.isRefreshing,
            error: appState.lastError,
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
            ForEach(appState.prs) { pr in
                PRListItemView(pr: pr) {
                    if let url = URL(string: pr.htmlURL) {
                        openURL(url)
                    }
                }
            }

            Divider()
        } else if !appState.isRefreshing && appState.lastError == nil {
            EmptyStateView()
            Divider()
        }

        Button {
            Task {
                await appState.manualRefresh()
            }
        } label: {
            Label("Refresh Now", systemImage: "arrow.clockwise")
                .symbolEffect(.rotate, options: .speed(0.5), isActive: appState.isRefreshing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
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

#Preview {
    MenuBarContentView(appState: AppState())
}
