import OSLog
import SwiftUI

struct AccountsListView: View {

    // MARK: - State
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
            if appState.accounts.isEmpty {
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
                    ForEach(appState.accounts) { account in
                        AccountRowView(account: account) {
                            accountToEdit = account
                        } onToggle: { isEnabled in
                            var updated = account
                            updated.isEnabled = isEnabled
                            accountManager.updateAccount(updated)
                            appState.reloadAccounts()
                        } onDelete: {
                            deleteAccount(account)
                        }
                    }
                    .reorderableIfAvailable(appState.accounts.count > 1)
                }
                .listStyle(.inset)
                .accountReorderContainer(move: moveAccounts)
            }
        }
        .onAppear { appState.reloadAccounts() }
        .sheet(item: $providerToAdd) { provider in
            AddAccountView(provider: provider)
        }
        .sheet(item: $accountToEdit) { account in
            AddAccountView(provider: account.provider, existingAccount: account)
        }
        .alert("Delete Failed", item: $deleteError) { _ in
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Actions
    /// `destinationID` is the account the dragged rows land in front of; `nil` means the end.
    private func moveAccounts(_ sources: [ProviderAccount.ID], before destinationID: ProviderAccount.ID?) {
        let stored = accountManager.getAccounts()
        let reordered = AccountManager.reordering(stored, moving: sources, before: destinationID)
        guard reordered != stored else { return }

        accountManager.saveAccounts(reordered)
        appState.reloadAccountOrder()
    }

    private func deleteAccount(_ account: ProviderAccount) {
        do {
            try accountManager.removeAccount(account)
            appState.reloadAccounts()
        } catch {
            deleteError = error.localizedDescription
            AppLogger.error.error("Failed to delete account: \(error.localizedDescription)")
        }
    }
}

// MARK: - Reordering
private extension DynamicViewContent {
    /// Draggable rows on macOS 27; a no-op below, where the list keeps its insertion order.
    /// - Parameter isEnabled: false leaves the rows static, so a single account offers no
    ///   drag handle for a reorder that cannot change anything.
    @ViewBuilder
    func reorderableIfAvailable(_ isEnabled: Bool) -> some View {
        if #available(macOS 27.0, *), isEnabled {
            reorderable()
        } else {
            self
        }
    }
}

private extension View {
    /// Receives drops from `reorderableIfAvailable()`, flattening `ReorderDifference` into plain
    /// ids so no macOS 27-only type escapes this file.
    @ViewBuilder
    func accountReorderContainer(
        move: @escaping ([ProviderAccount.ID], ProviderAccount.ID?) -> Void
    ) -> some View {
        if #available(macOS 27.0, *) {
            reorderContainer(for: ProviderAccount.self) { difference in
                switch difference.destination.position {
                case let .before(id):
                    move(difference.sources, id)
                case .end:
                    move(difference.sources, nil)
                }
            }
        } else {
            self
        }
    }
}

// MARK: - Preview
#Preview {
    AccountsListView()
        .environment(AppState.shared)
}
