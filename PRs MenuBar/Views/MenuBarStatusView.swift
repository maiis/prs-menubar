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
            if isRefreshing {
                VStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.regular)

                    Text(prCount == 0 ? "Loading pull requests..." : "Refreshing...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if isOffline {
                OfflineStateView(onRetry: onRetry)
            } else if let error {
                ErrorStateView(error: error, onConfigureToken: onConfigureToken, onRetry: onRetry)
            } else if hasEnabledAccounts {
                SuccessStateView(prCount: prCount, lastUpdated: lastUpdated)
            }
            // When no accounts, don't show anything here - NoAccountsStateView is shown in MenuBarContentView
        }
    }
}
