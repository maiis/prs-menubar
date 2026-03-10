import SwiftUI

struct PRListItemView: View {

    // MARK: - Properties
    let pr: PullRequest
    let showRepoName: Bool

    // MARK: - Environment
    @Environment(\.openURL) private var openURL

    // MARK: - UI
    var body: some View {
        Menu {
            Text("by \(pr.user.login)")
            Text("\(pr.repositoryName) #\(pr.number)")

            if pr.isDraft {
                Text("Draft")
            }

            if !pr.labels.isEmpty {
                Text(pr.labels.joined(separator: ", "))
            }

            if let created = pr.createdDate {
                Text("Created \(created.formatted(date: .abbreviated, time: .shortened))")
            }

            if let updated = pr.updatedDate {
                Text("Updated \(updated.formatted(date: .abbreviated, time: .shortened))")
            }

            Divider()

            Button {
                if let url = URL(string: pr.htmlURL) {
                    openURL(url)
                }
            } label: {
                Label("Open in Browser", systemImage: "safari")
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(pr.htmlURL, forType: .string)
            } label: {
                Label("Copy URL", systemImage: "doc.on.doc")
            }
        } label: {
            if pr.isDraft {
                Label(menuLabel, systemImage: "pencil.and.outline")
            } else {
                Text(menuLabel)
            }
        } primaryAction: {
            if let url = URL(string: pr.htmlURL) {
                openURL(url)
            }
        }
        .accessibilityLabel("\(pr.title) in \(pr.repositoryName) by \(pr.user.login)")
        .help(pr.title)
    }

    // MARK: - Computed Properties
    private var menuLabel: String {
        let titlePart = showRepoName
            ? "\(pr.repositoryName) · \(pr.truncatedTitle)"
            : pr.truncatedTitle
        return "\(titlePart) · \(pr.relativeAge)"
    }
}

// MARK: - Preview
#Preview("Regular PR") {
    let dateFormatter = ISO8601DateFormatter()
    PRListItemView(
        pr: PullRequest(
            id: "demo-pr-1",
            number: 123,
            title: "Add new authentication flow with OAuth2 support",
            htmlURL: "https://github.com/example/awesome-app/pull/123",
            state: "open",
            isDraft: false,
            user: User(login: "octocat"),
            createdAt: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 2)),
            updatedAt: dateFormatter.string(from: Date().addingTimeInterval(-3600)),
            labels: ["enhancement", "security"]
        ),
        showRepoName: true
    )
    .padding()
}

#Preview("Draft PR") {
    let dateFormatter = ISO8601DateFormatter()
    PRListItemView(
        pr: PullRequest(
            id: "demo-pr-2",
            number: 456,
            title: "WIP: Refactor database layer",
            htmlURL: "https://github.com/example/awesome-app/pull/456",
            state: "open",
            isDraft: true,
            user: User(login: "developer1"),
            createdAt: dateFormatter.string(from: Date().addingTimeInterval(-86400)),
            updatedAt: dateFormatter.string(from: Date().addingTimeInterval(-1800)),
            labels: []
        ),
        showRepoName: false
    )
    .padding()
}
