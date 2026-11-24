import SwiftUI

struct AccountsSettingsTab: View {

    // MARK: - UI
    var body: some View {
        Form {
            Section {
                AccountsListView()
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

// MARK: - Preview
#Preview {
    AccountsSettingsTab()
        .environment(AppState.shared)
        .frame(width: 550, height: 450)
}
