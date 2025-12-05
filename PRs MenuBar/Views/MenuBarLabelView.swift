import SwiftUI

struct MenuBarLabelView: View {

    // MARK: - Properties
    let prCount: Int
    let isRefreshing: Bool
    let hasError: Bool
    let hasEnabledAccounts: Bool

    // MARK: - UI
    var body: some View {
        Group {
            if isRefreshing {
                if #available(macOS 15.0, *) {
                    Image(systemName: "arrow.clockwise")
                        .symbolEffect(.rotate, options: .repeat(.continuous))
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            } else if hasError {
                Image(systemName: "exclamationmark.triangle.fill")
            } else if !hasEnabledAccounts {
                Image(systemName: "person.crop.circle.badge.questionmark")
            } else {
                Image(systemName: prCount == 0 ? "checkmark.circle.fill" : "arrow.trianglehead.pull")
            }

            if prCount > 0, hasEnabledAccounts {
                Text("\(prCount)")
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isRefreshing ? "Refreshing" : "")
    }

    // MARK: - Helpers
    private var accessibilityLabel: String {
        if !hasEnabledAccounts {
            return "No accounts configured"
        }
        return "\(prCount) pull requests awaiting review"
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        MenuBarLabelView(prCount: 0, isRefreshing: false, hasError: false, hasEnabledAccounts: true)
        MenuBarLabelView(prCount: 5, isRefreshing: false, hasError: false, hasEnabledAccounts: true)
        MenuBarLabelView(prCount: 2, isRefreshing: true, hasError: false, hasEnabledAccounts: true)
        MenuBarLabelView(prCount: 0, isRefreshing: false, hasError: true, hasEnabledAccounts: true)
        MenuBarLabelView(prCount: 0, isRefreshing: false, hasError: false, hasEnabledAccounts: false)
    }
    .padding()
}
