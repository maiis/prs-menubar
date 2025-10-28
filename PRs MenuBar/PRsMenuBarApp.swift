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
                    if !AccountManager.shared.hasCompletedOnboarding {
                        openWindow(id: "onboarding")
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

        Window("Get Started", id: "onboarding") {
            ProviderSelectionView()
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
                    // Find and bring the settings window to front
                    DispatchQueue.main.async {
                        if let settingsWindow = NSApplication.shared.windows.first(where: { $0.title == "Settings" }) {
                            settingsWindow.makeKeyAndOrderFront(nil)
                        }
                    }
                }
        }
    }
}
