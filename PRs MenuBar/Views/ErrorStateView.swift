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

            Text(friendlyErrorMessage(error))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if error.lowercased().contains("unauthorized") || error.lowercased().contains("token") {
                    Button("Update Token") {
                        onConfigureToken()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func friendlyErrorMessage(_ error: String) -> String {
        let lowercased = error.lowercased()
        if lowercased.contains("unauthorized") {
            return "Your GitHub token is invalid or expired. Please update it."
        } else if lowercased.contains("rate limit") {
            return "GitHub API rate limit exceeded. Try again later."
        } else if lowercased.contains("network") || lowercased.contains("internet") {
            return "Check your internet connection and try again."
        } else {
            return "Something went wrong. Please try again."
        }
    }
}

// MARK: - Preview
#Preview {
    ErrorStateView(
        error: "Unauthorized: Invalid token",
        onConfigureToken: {},
        onRetry: {}
    )
    .padding()
}
