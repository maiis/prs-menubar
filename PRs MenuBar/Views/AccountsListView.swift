import OSLog
import SwiftUI

struct AccountsListView: View {

    // MARK: - State
    @State private var accounts: [ProviderAccount] = []
    @State private var providerToAdd: GitProvider?
    @State private var accountToEdit: ProviderAccount?
    @State private var deleteError: String?

    // MARK: - Environment
    @Environment(AppState.self) private var appState

    // MARK: - Properties
    private let accountManager = AccountManager.shared

    // MARK: - UI
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Menu {
                    ForEach(GitProvider.allCases, id: \.self) { provider in
                        Button {
                            providerToAdd = provider
                        } label: {
                            Label(provider.displayName, systemImage: provider.iconName)
                        }
                    }
                } label: {
                    Label("Add Account", systemImage: "plus")
                }
                .fixedSize()
            }
            if accounts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No accounts configured")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Add an account to start tracking pull requests")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                List {
                    ForEach(accounts) { account in
                        AccountRowView(account: account) {
                            accountToEdit = account
                        } onToggle: { isEnabled in
                            toggleAccount(account, isEnabled: isEnabled)
                        } onDelete: {
                            deleteAccount(account)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .onAppear { loadAccounts() }
        .sheet(item: $providerToAdd) { provider in
            AddAccountView(provider: provider)
                .environment(appState)
                .onDisappear { loadAccounts() }
        }
        .sheet(item: $accountToEdit) { account in
            if accountManager.getToken(for: account) != nil {
                AddAccountView(provider: account.provider, existingAccount: account)
                    .environment(appState)
                    .onDisappear {
                        loadAccounts()
                        accountToEdit = nil
                    }
            }
        }
        .alert(
            "Delete Failed",
            isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )
        ) {
            Button("OK") { deleteError = nil }
        } message: {
            if let error = deleteError {
                Text(error)
            }
        }
    }

    // MARK: - Actions
    private func loadAccounts() {
        accounts = accountManager.getAccounts()
        appState.reloadAccounts()
    }

    private func toggleAccount(_ account: ProviderAccount, isEnabled: Bool) {
        let updated = ProviderAccount(
            id: account.id,
            provider: account.provider,
            name: account.name,
            baseURL: account.baseURL,
            isEnabled: isEnabled
        )
        accountManager.updateAccount(updated)
        // loadAccounts() calls reloadAccounts() which triggers a refresh
        loadAccounts()
    }

    private func deleteAccount(_ account: ProviderAccount) {
        do {
            try accountManager.removeAccount(account)
            // loadAccounts() calls reloadAccounts() which triggers a refresh
            loadAccounts()
        } catch {
            deleteError = error.localizedDescription
            AppLogger.error.error("Failed to delete account: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
#Preview {
    AccountsListView()
        .environment(AppState.shared)
}
