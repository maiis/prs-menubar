import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        Label {
            Text("All caught up!")
                .font(.subheadline)
                .lineLimit(1)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - No Accounts State View

struct NoAccountsStateView: View {

    // MARK: - Properties
    let onAddAccount: () -> Void

    // MARK: - UI
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No Accounts", systemImage: "person.crop.circle.badge.questionmark")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Add an account to see pull requests awaiting your review")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Add Account...", action: onAddAccount)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview
#Preview("Empty State") {
    EmptyStateView()
        .padding()
}

#Preview("No Accounts") {
    NoAccountsStateView(onAddAccount: {})
        .frame(width: 280)
}
