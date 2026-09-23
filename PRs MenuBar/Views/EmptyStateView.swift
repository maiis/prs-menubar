import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label("All caught up", systemImage: "checkmark.circle.fill")
        } description: {
            Text("No pull requests are awaiting your review.")
        }
    }
}

// MARK: - No Accounts State View

struct NoAccountsStateView: View {

    // MARK: - Properties
    let onAddAccount: () -> Void

    // MARK: - UI
    var body: some View {
        ContentUnavailableView {
            Label("No Accounts", systemImage: "person.crop.circle.badge.questionmark")
        } description: {
            Text("Add an account to see pull requests awaiting your review.")
        } actions: {
            Button("Add Account…", action: onAddAccount)
                .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Preview
#Preview("Empty State") {
    EmptyStateView()
        .frame(width: 360, height: 280)
}

#Preview("No Accounts") {
    NoAccountsStateView(onAddAccount: {})
        .frame(width: 360, height: 280)
}
