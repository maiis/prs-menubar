import SwiftUI

struct PRListItemView: View {

    // MARK: - Properties
    let pr: PullRequest
    let showRepoName: Bool
    let onTap: () -> Void

    // MARK: - UI
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .lineLimit(1)
        }
        .accessibilityLabel("\(pr.title) in \(pr.repositoryName)")
        .help("\(pr.repositoryName) — \(pr.title)")
    }

    // MARK: - Computed Properties
    private var title: String {
        showRepoName ? "\(pr.repositoryName) - \(pr.truncatedTitle)" : pr.truncatedTitle
    }
}

// MARK: - Preview
#Preview {
    let dateFormatter = ISO8601DateFormatter()
    PRListItemView(
        pr: PullRequest(
            id: "demo-pr-1",
            number: 123,
            title: "Add new authentication flow with OAuth2 support",
            htmlURL: "https://github.com/example/awesome-app/pull/123",
            state: "open",
            isDraft: false,
            user: User(login: "developer1"),
            createdAt: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 2)),
            updatedAt: dateFormatter.string(from: Date().addingTimeInterval(-3600)),
            labels: ["enhancement", "security"]
        ),
        showRepoName: true,
        onTap: {}
    )
    .padding()
}
