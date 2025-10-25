import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AccountsSettingsTab()
                .environment(appState)
                .tabItem {
                    Label("Accounts", systemImage: "person.2.fill")
                }
                .tag(0)

            GeneralSettingsTab()
                .environment(appState)
                .tabItem {
                    Label("General", systemImage: "gearshape.fill")
                }
                .tag(1)

            AppearanceSettingsTab()
                .environment(appState)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }
                .tag(2)

            AdvancedSettingsTab()
                .environment(appState)
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

#Preview {
    SettingsView()
        .environment(AppState.shared)
}
