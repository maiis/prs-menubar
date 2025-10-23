import Foundation

final class DemoGitHubService: GitHubServiceProtocol, Sendable {
    static let shared = DemoGitHubService()

    private init() {}

    func fetchReviewRequestedPRs() async throws -> [PullRequest] {
        try await Task.sleep(for: .seconds(0.5))

        return [
            PullRequest(
                id: "demo-pr-1",
                number: 123,
                title: "Add new authentication flow with OAuth2 support",
                htmlURL: "https://github.com/example/awesome-app/pull/123",
                state: "open",
                isDraft: false,
                user: User(login: "developer1", avatarURL: ""),
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 2)),
                updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
            ),
            PullRequest(
                id: "demo-pr-2",
                number: 456,
                title: "Fix memory leak in background refresh task",
                htmlURL: "https://github.com/example/awesome-app/pull/123",
                state: "open",
                isDraft: false,
                user: User(login: "contributor2", avatarURL: ""),
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 5)),
                updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200))
            ),
            PullRequest(
                id: "demo-pr-3",
                number: 789,
                title: "Update dependencies to latest versions",
                htmlURL: "https://github.com/example/backend-api/pull/789",
                state: "open",
                isDraft: true,
                user: User(login: "maintainer3", avatarURL: ""),
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)),
                updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-1800))
            ),
            PullRequest(
                id: "demo-pr-4",
                number: 321,
                title: "Implement dark mode support for settings panel",
                htmlURL: "https://github.com/example/ui-components/pull/321",
                state: "open",
                isDraft: false,
                user: User(login: "designer4", avatarURL: ""),
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 3)),
                updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-5400))
            ),
            PullRequest(
                id: "demo-pr-5",
                number: 654,
                title: "Add comprehensive test coverage for API endpoints",
                htmlURL: "https://github.com/example/testing-suite/pull/654",
                state: "open",
                isDraft: false,
                user: User(login: "qa-engineer5", avatarURL: ""),
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 4)),
                updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-10800))
            )
        ]
    }
}
