import SwiftUI

struct ErrorStateView: View {

    // MARK: - Properties
    let error: String
    let onConfigureToken: () -> Void
    let onRetry: () -> Void

    // MARK: - UI
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Unable to load pull requests", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            Text(friendlyErrorMessage(error))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if isTokenError {
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
    private var isTokenError: Bool {
        let lowercased = error.lowercased()
        return lowercased.contains("unauthorized") ||
            lowercased.contains("token") ||
            lowercased.contains("401") ||
            lowercased.contains("403")
    }

    private func friendlyErrorMessage(_ error: String) -> String {
        let lowercased = error.lowercased()

        // Authentication errors
        if lowercased.contains("unauthorized") || lowercased.contains("401") {
            if lowercased.contains("gitlab") {
                return "Your GitLab token is invalid or expired. Please update it."
            } else if lowercased.contains("gitea") {
                return "Your Gitea token is invalid or expired. Please update it."
            }
            return "Your token is invalid or expired. Please update it."
        }

        // Forbidden errors
        if lowercased.contains("forbidden") || lowercased.contains("403") {
            return "Access denied. Please check your token permissions."
        }

        // Rate limit errors
        if lowercased.contains("rate limit") || lowercased.contains("429") {
            if lowercased.contains("gitlab") {
                return "GitLab API rate limit exceeded. Try again later."
            } else if lowercased.contains("gitea") {
                return "Gitea API rate limit exceeded. Try again later."
            }
            return "API rate limit exceeded. Try again later."
        }

        // Network errors
        if lowercased.contains("not connected") || lowercased.contains("offline") {
            return "You appear to be offline. Check your internet connection."
        }

        if lowercased.contains("timed out") || lowercased.contains("timeout") {
            return "Request timed out. Please try again."
        }

        if lowercased.contains("network") || lowercased.contains("internet") ||
            lowercased.contains("connection")
        {
            return "Network error. Check your internet connection and try again."
        }

        // DNS errors
        if lowercased.contains("dns") || lowercased.contains("host") {
            return "Unable to reach server. Check your connection and try again."
        }

        // Server errors
        if lowercased.contains("500") || lowercased.contains("502") ||
            lowercased.contains("503") || lowercased.contains("504")
        {
            return "Server error. The service may be temporarily unavailable."
        }

        return "Something went wrong. Please try again."
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
        error: "Unauthorized: Invalid token",
        onConfigureToken: {},
        onRetry: {}
    )
    .frame(width: 280)
}

#Preview("Offline State") {
    OfflineStateView(onRetry: {})
        .frame(width: 280)
}
