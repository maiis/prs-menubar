import OSLog
import SwiftUI

@main
struct PRsMenuBarApp: App {

    // MARK: - Init
    init() {
        // Use .notice level for launch log so it's persisted (info/debug are only live-streamed)
        AppLogger.app
            .notice(
                "PRs MenuBar app launching - version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")"
            )
    }

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
                    AppLogger.app.info("Menu bar content view appeared")
                    if !AccountManager.shared.hasCompletedOnboarding {
                        AppLogger.app.info("Onboarding not completed, opening onboarding window")
                        openWindow(id: "onboarding")
                    }
                }
        } label: {
            MenuBarLabelView(
                prCount: appState.prCount,
                isRefreshing: appState.isRefreshing,
                hasError: appState.lastError != nil,
                hasEnabledAccounts: appState.hasEnabledAccounts
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
                    Task { @MainActor in
                        if let settingsWindow = NSApplication.shared.windows.first(where: { $0.title == "Settings" }) {
                            settingsWindow.makeKeyAndOrderFront(nil)
                        }
                    }
                }
        }
    }
}
