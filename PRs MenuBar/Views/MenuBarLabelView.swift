import SwiftUI

struct MenuBarLabelView: View {

    // MARK: - Properties
    let prCount: Int
    let isRefreshing: Bool
    let hasError: Bool

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
            } else {
                Image(systemName: prCount == 0 ? "checkmark.circle.fill" : "arrow.trianglehead.pull")
            }

            if prCount > 0 {
                Text("\(prCount)")
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .accessibilityLabel("\(prCount) pull requests awaiting review")
        .accessibilityValue(isRefreshing ? "Refreshing" : "")
    }
}
