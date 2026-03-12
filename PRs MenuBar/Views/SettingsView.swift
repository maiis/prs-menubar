import SwiftUI

struct SettingsView: View {

    // MARK: - Environment
    @Environment(AppState.self) private var appState

    // MARK: - State
    @State private var selectedTab = 0

    // MARK: - UI
    var body: some View {
        TabView(selection: $selectedTab) {
            AccountsSettingsTab()
                .tabItem {
                    Label("Accounts", systemImage: "person.2.fill")
                }
                .tag(0)

            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gearshape.fill")
                }
                .tag(1)

            DisplaySettingsTab()
                .tabItem {
                    Label("Display", systemImage: "rectangle.3.group.fill")
                }
                .tag(2)

            AdvancedSettingsTab()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
                .tag(3)

            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
                .tag(4)
        }
        .frame(minWidth: 550, maxWidth: 550, minHeight: 450, maxHeight: 600)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environment(AppState.shared)
}
