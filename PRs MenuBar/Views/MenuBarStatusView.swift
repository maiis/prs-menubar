import SwiftUI

struct MenuBarStatusView: View {

    // MARK: - Properties
    let isRefreshing: Bool
    let isOffline: Bool
    let hasEnabledAccounts: Bool
    let error: String?
    let prCount: Int
    let lastUpdated: Date?
    let onConfigureToken: () -> Void
    let onRetry: () -> Void

    // MARK: - UI
    var body: some View {
        Group {
            if isRefreshing, prCount == 0 {
                // First load only: static text (no animated ProgressView to avoid MenuBarExtra re-render loops)
                Text("Loading pull requests...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let error {
                // Show specific error message first - it's more informative than generic "offline"
                ErrorStateView(error: error, onConfigureToken: onConfigureToken, onRetry: onRetry)
            } else if isOffline {
                // Only show generic offline view if we have no specific error details
                OfflineStateView(onRetry: onRetry)
            } else if hasEnabledAccounts {
                SuccessStateView(prCount: prCount, lastUpdated: lastUpdated)
            }
            // When no accounts, don't show anything here - NoAccountsStateView is shown in MenuBarContentView
        }
    }
}
