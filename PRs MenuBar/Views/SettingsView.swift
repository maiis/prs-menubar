import SwiftUI

struct SettingsView: View {

    // MARK: - UI
    var body: some View {
        TabView {
            AccountsSettingsTab()
                .tabItem {
                    Label("Accounts", systemImage: "person.2.fill")
                }

            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gearshape.fill")
                }

            DisplaySettingsTab()
                .tabItem {
                    Label("Display", systemImage: "rectangle.3.group.fill")
                }

            AdvancedSettingsTab()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }

            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
        }
        .frame(minWidth: 550, maxWidth: 550, minHeight: 450, maxHeight: 600)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environment(AppState.shared)
}
