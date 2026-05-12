import SwiftUI

struct ErrorStateView: View {

    // MARK: - Properties
    let error: GitServiceError
    let additionalAccountsAffected: Int
    let onConfigureToken: () -> Void
    let onRetry: () -> Void

    // MARK: - UI
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Unable to load pull requests", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if error.requiresTokenUpdate {
                    Button("Update Token", action: onConfigureToken)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }

                Button("Retry", action: onRetry)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    // MARK: - Helpers
    private var message: String {
        let base = error.friendlyDescription
        guard additionalAccountsAffected > 0 else { return base }
        let suffix = additionalAccountsAffected == 1
            ? "+ 1 other account also failing"
            : "+ \(additionalAccountsAffected) other accounts also failing"
        return "\(base) \(suffix)"
    }
}

// MARK: - Offline State View

struct OfflineStateView: View {

    // MARK: - Properties
    let onRetry: () -> Void

    // MARK: - UI
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No Connection", systemImage: "wifi.slash")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Check your internet connection and try again")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview
#Preview("Error State") {
    ErrorStateView(
        error: .unauthorized,
        additionalAccountsAffected: 0,
        onConfigureToken: {},
        onRetry: {}
    )
    .frame(width: 280)
}

#Preview("Multi-account Error") {
    ErrorStateView(
        error: .rateLimited(resetDate: Date().addingTimeInterval(120)),
        additionalAccountsAffected: 2,
        onConfigureToken: {},
        onRetry: {}
    )
    .frame(width: 280)
}

#Preview("Offline State") {
    OfflineStateView(onRetry: {})
        .frame(width: 280)
}
