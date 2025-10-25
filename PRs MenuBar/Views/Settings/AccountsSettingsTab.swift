import SwiftUI

struct AccountsSettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section {
                AccountsListView()
                    .environment(appState)
            } header: {
                Text("Accounts")
                    .font(.headline)
            } footer: {
                Text("Configure your Git service accounts to track pull requests across multiple providers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AccountsSettingsTab()
        .environment(AppState.shared)
        .frame(width: 550, height: 450)
}
