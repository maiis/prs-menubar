import SwiftUI

struct AccountsListView: View {
    @State private var accounts: [ProviderAccount] = []
    @State private var showAddAccount = false
    @State private var selectedProvider: GitProvider = .github
    @State private var accountToEdit: ProviderAccount?
    
    @Environment(AppState.self) private var appState
    
    private let accountManager = AccountManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Accounts")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    ForEach(GitProvider.allCases, id: \.self) { provider in
                        Button {
                            selectedProvider = provider
                            showAddAccount = true
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
        .onAppear {
            loadAccounts()
        }
        .sheet(isPresented: $showAddAccount) {
            AddAccountView(provider: selectedProvider)
                .environment(appState)
                .onDisappear {
                    loadAccounts()
                }
        }
        .sheet(item: $accountToEdit) { account in
            if let token = accountManager.getToken(for: account) {
                AddAccountView(provider: account.provider, existingAccount: account)
                    .environment(appState)
                    .onDisappear {
                        loadAccounts()
                        accountToEdit = nil
                    }
            }
        }
    }
    
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
        loadAccounts()
        
        Task {
            await appState.manualRefresh()
        }
    }
    
    private func deleteAccount(_ account: ProviderAccount) {
        accountManager.removeAccount(account)
        loadAccounts()
        
        Task {
            await appState.manualRefresh()
        }
    }
}

struct AccountRowView: View {
    let account: ProviderAccount
    let onEdit: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { account.isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            
            Image(systemName: account.provider.iconName)
                .foregroundStyle(account.isEnabled ? .primary : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.body)
                    .foregroundStyle(account.isEnabled ? .primary : .secondary)
                
                HStack(spacing: 4) {
                    Text(account.provider.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if account.provider == .gitea || account.baseURL != account.provider.defaultBaseURL {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(account.baseURL)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Menu {
                Button("Edit") {
                    onEdit()
                }
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    showDeleteConfirmation = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.vertical, 4)
        .confirmationDialog(
            "Delete \(account.name)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the account and its token. This action cannot be undone.")
        }
    }
}

#Preview {
    AccountsListView()
        .environment(AppState.shared)
}
