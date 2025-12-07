import SwiftUI

struct SuccessStateView: View {

    // MARK: - Properties
    let prCount: Int
    let lastUpdated: Date?

    // MARK: - UI
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
    }
}

// MARK: - Preview
#Preview {
    SuccessStateView(prCount: 5, lastUpdated: Date().addingTimeInterval(-450))
        .padding()
}
