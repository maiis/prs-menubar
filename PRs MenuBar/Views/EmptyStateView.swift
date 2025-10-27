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
    }
}

// MARK: - Preview
#Preview {
    EmptyStateView()
        .padding()
}
