import SwiftUI

struct EmptyStateView: View {
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.green)

      Text("All caught up!")
        .font(.subheadline)
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
