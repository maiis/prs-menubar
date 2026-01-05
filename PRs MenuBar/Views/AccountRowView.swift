import Foundation
import SwiftUI

struct AccountRowView: View {

    // MARK: - Properties
    let account: ProviderAccount
    let onEdit: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void

    // MARK: - State
    @State private var showDeleteConfirmation = false

    // MARK: - Environment
    @Environment(AppState.self) private var appState

    // MARK: - UI
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { account.isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .fixedSize()

            Image(systemName: account.provider.iconName)
                .frame(width: 20, height: 20)
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
                            .truncationMode(.middle)
                    }
                }
                if account.isEnabled { accountStatusView }
            }
            Spacer()

            if account.isEnabled {
                statusIcon
                    .frame(width: 20, height: 20)
            }

            Menu {
                Button("Edit") { onEdit() }
                Divider()
                Button("Delete", role: .destructive) { showDeleteConfirmation = true }
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
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will remove the account and its token. This action cannot be undone.") }
    }

    // MARK: - Helpers
    @ViewBuilder
    private var accountStatusView: some View {
        let status = appState.getAccountStatus(account)
        HStack(spacing: 4) {
            switch status {
            case .loading:
                ProgressView().controlSize(.mini)
                Text("Fetching...").font(.caption2).foregroundStyle(.secondary)
            case let .success(date):
                Text("Last: \(date, style: .relative)").font(.caption2).foregroundStyle(.green)
            case let .error(errorMessage):
                Text(errorMessage).font(.caption2).foregroundStyle(.red).lineLimit(1)
            case .unknown:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        let status = appState.getAccountStatus(account)
        switch status {
        case .loading:
            ProgressView().controlSize(.small)
        case .success:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).imageScale(.small)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange).imageScale(.small)
        case .unknown:
            EmptyView()
        }
    }
}

// MARK: - Preview
#Preview {
    AccountRowView(
        account: ProviderAccount(
            id: UUID(),
            provider: .github,
            name: "Personal GitHub",
            baseURL: "",
            isEnabled: true
        ),
        onEdit: {},
        onToggle: { _ in },
        onDelete: {}
    )
    .environment(AppState.shared)
    .frame(width: 400)
}
