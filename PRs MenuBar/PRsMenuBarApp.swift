import SwiftUI

@main
struct PRsMenuBarApp: App {

    // MARK: - State
    @State private var appState = if CommandLine.arguments.contains("-mockData") {
        AppState(githubService: DemoGitHubService.shared)
    } else {
        AppState.shared
    }

    // MARK: - Environment
    @Environment(\.openWindow) private var openWindow

    // MARK: - UI
    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
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
                .environment(appState)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
    }
}
