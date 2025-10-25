import SwiftUI

struct AdvancedSettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section {
                Toggle("Demo Mode", isOn: Binding(
                    get: { appState.isDemoMode },
                    set: { appState.setDemoMode($0) }
                ))
            } header: {
                Text("Preview")
                    .font(.headline)
            } footer: {
                Text(
                    "Enable demo mode to preview the app with sample pull requests. No account configuration required. Perfect for screenshots and app store reviews."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AdvancedSettingsTab()
        .environment(AppState.shared)
        .frame(width: 550, height: 450)
}
