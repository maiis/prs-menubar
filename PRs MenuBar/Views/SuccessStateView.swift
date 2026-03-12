import SwiftUI

struct SuccessStateView: View {

    // MARK: - Properties
    let prCount: Int

    // MARK: - UI
    var body: some View {
        Text("\(prCount) PR\(prCount == 1 ? "" : "s") awaiting review")
            .font(.headline)
    }
}

// MARK: - Preview
#Preview {
    SuccessStateView(prCount: 5)
        .padding()
}
