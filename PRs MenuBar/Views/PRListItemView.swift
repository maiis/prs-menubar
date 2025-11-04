import SwiftUI

// Shared date formatter to avoid repeated instantiation in previews
private let previewDateFormatter = ISO8601DateFormatter()

struct PRListItemView: View {

    // MARK: - State
    @AppStorage(UserDefaults.groupByRepoKey) private var groupByRepo = false

    // MARK: - Properties
    let pr: PullRequest
    let onTap: () -> Void

    // MARK: - UI
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .lineLimit(1)
        }
        .help("\(pr.repositoryName) — \(pr.title)")
    }

    // MARK: - Computed Properties
    private var title: String {
        groupByRepo ? pr.truncatedTitle : "\(pr.repositoryName) - \(pr.truncatedTitle)"
    }
}

// MARK: - Preview
#Preview {
    PRListItemView(
        pr: PullRequest(
            id: "demo-pr-1",
            number: 123,
            title: "Add new authentication flow with OAuth2 support",
            htmlURL: "https://github.com/example/awesome-app/pull/123",
            state: "open",
            isDraft: false,
            user: User(login: "developer1", avatarURL: ""),
            createdAt: previewDateFormatter.string(from: Date().addingTimeInterval(-86400 * 2)),
            updatedAt: previewDateFormatter.string(from: Date().addingTimeInterval(-3600)),
            labels: ["enhancement", "security"]
        ),
        onTap: {}
    )
    .padding()
}
