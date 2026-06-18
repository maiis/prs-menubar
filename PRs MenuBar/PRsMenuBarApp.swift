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
    // Xcode 27's @State macro rejects a bare `if`-expression initializer, and SwiftFormat
    // collapses an immediately-invoked closure back into that rejected form — so the branch
    // selection lives in a static factory, which both tools leave alone.
    @State private var appState = PRsMenuBarApp.makeInitialAppState()

    private static func makeInitialAppState() -> AppState {
        if CommandLine.arguments.contains("-mockData") {
            AppState(githubService: DemoGitHubService.shared)
        } else {
            AppState.shared
        }
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
                hasError: appState.lastError != nil || appState.hasAccountErrors,
                hasEnabledAccounts: appState.hasEnabledAccounts
            )
        }
        .menuBarExtraStyle(.window)

        Window("Get Started", id: "onboarding") {
            ProviderSelectionView()
                .environment(appState)
                .onAppear {
                    // Accessory (menu bar) apps don't auto-activate when a window opens, so the
                    // window stays non-key and prominent controls render greyed/"disabled".
                    NSApp.activate()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Settings {
            SettingsView()
                .environment(appState)
                .onAppear {
                    NSApp.activate()
                    // Find and bring the settings window to front
                    Task {
                        if let settingsWindow = NSApplication.shared.windows.first(where: { $0.title == "Settings" }) {
                            settingsWindow.makeKeyAndOrderFront(nil)
                        }
                    }
                }
        }
    }
}
