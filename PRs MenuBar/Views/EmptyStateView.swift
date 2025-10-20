import SwiftUI

struct EmptyStateView: View {
  var body: some View {
    Label {
      Text("All caught up!")
        .font(.subheadline)
        .lineLimit(1)
    } icon: {
      Image(systemName: "checkmark.circle.fill")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 6)
    .padding(.horizontal, 12)
  }
}
