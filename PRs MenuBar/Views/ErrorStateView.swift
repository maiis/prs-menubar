import SwiftUI

struct ErrorStateView: View {

    // MARK: - Properties
    let displayError: AppState.DisplayError
    let onConfigureToken: () -> Void
    let onRetry: () -> Void

    // MARK: - UI
    var body: some View {
        ContentUnavailableView {
            Label("Unable to load pull requests", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(displayError.message)
        } actions: {
            if displayError.error.requiresTokenUpdate {
                Button("Update Token", action: onConfigureToken)
                    .buttonStyle(.borderedProminent)
            }

            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - Offline State View

struct OfflineStateView: View {

    // MARK: - Properties
    let onRetry: () -> Void

    // MARK: - UI
    var body: some View {
        ContentUnavailableView {
            Label("No Connection", systemImage: "wifi.slash")
        } description: {
            Text("Check your internet connection and try again.")
        } actions: {
            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - Preview
#Preview("Error State") {
    ErrorStateView(
        displayError: AppState.DisplayError(error: .unauthorized, additionalAccountsAffected: 0),
        onConfigureToken: {},
        onRetry: {}
    )
    .frame(width: 360, height: 280)
}

#Preview("Multi-account Error") {
    ErrorStateView(
        displayError: AppState.DisplayError(
            error: .rateLimited(resetDate: Date().addingTimeInterval(120)),
            additionalAccountsAffected: 2
        ),
        onConfigureToken: {},
        onRetry: {}
    )
    .frame(width: 360, height: 280)
}

#Preview("Offline State") {
    OfflineStateView(onRetry: {})
        .frame(width: 360, height: 280)
}
