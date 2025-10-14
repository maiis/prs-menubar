import SwiftUI

@main
struct PRsMenuBarApp: App {
    @State private var appState = AppState.shared
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(appState: appState)
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
            Image(systemName: appState.prCount == 0 ? "checkmark.circle.fill" : "bell.badge.fill")
            if appState.prCount > 0 {
                Text("\(appState.prCount)")
            }
        }
        .menuBarExtraStyle(.menu)
        
        Window("GitHub Token", id: "token-prompt") {
            TokenPromptView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

struct MenuBarContentView: View {
    @Bindable var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) private var openURL

    var body: some View {
        if appState.isRefreshing {
            Label("Refreshing...", systemImage: "arrow.clockwise")
                .foregroundStyle(.secondary)
        } else if let error = appState.lastError {
            Label("Error", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if error.contains("token") {
                Button("Configure Token") {
                    openWindow(id: "token-prompt")
                }
                .buttonStyle(.link)
                .font(.caption)
            }
        } else {
            Text("\(appState.prCount) PR\(appState.prCount == 1 ? "" : "s") awaiting review")
                .font(.headline)
            
            if let lastUpdated = appState.lastUpdated {
                Text("Updated \(lastUpdated, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        
        Divider()
        
        // PR List
        if !appState.prs.isEmpty {
            ForEach(appState.prs) { pr in
                Button {
                    if let url = URL(string: pr.htmlURL) {
                        openURL(url)
                    }
                } label: {
                    Text("\(pr.repositoryName) — \(pr.truncatedTitle)")
                }
                .help("\(pr.repositoryName) — \(pr.title)")
                
                Divider()
            }
        }
        
        // Actions
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
