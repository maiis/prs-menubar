import SwiftUI

struct MenuBarLabelView: View {
  let prCount: Int
  let isRefreshing: Bool
  let hasError: Bool

  var body: some View {
    Group {
      if isRefreshing {
        Image(systemName: "arrow.clockwise")
          .symbolEffect(.rotate, options: .repeat(.continuous))
      } else if hasError {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.orange)
      } else {
        Image(systemName: prCount == 0 ? "checkmark.circle.fill" : "arrow.trianglehead.pull")
          .foregroundStyle(prCount == 0 ? .green : .primary)
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
