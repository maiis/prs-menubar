import SwiftUI

struct MenuBarStatusView: View {
  let isRefreshing: Bool
  let error: String?
  let prCount: Int
  let lastUpdated: Date?
  let onConfigureToken: () -> Void
  let onRetry: () -> Void

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
      } else if let error {
        ErrorStateView(error: error, onConfigureToken: onConfigureToken, onRetry: onRetry)
      } else {
        SuccessStateView(prCount: prCount, lastUpdated: lastUpdated)
      }
    }
  }
}

private struct ErrorStateView: View {
  let error: String
  let onConfigureToken: () -> Void
  let onRetry: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.orange)
        Text("Unable to load pull requests")
          .font(.headline)
      }

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
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
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

private struct SuccessStateView: View {
  let prCount: Int
  let lastUpdated: Date?

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("\(prCount) PR\(prCount == 1 ? "" : "s") awaiting review")
        .font(.headline)

      if let lastUpdated {
        Text("Updated \(lastUpdated, style: .relative)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 4)
  }
}
