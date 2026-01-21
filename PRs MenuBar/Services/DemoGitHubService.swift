import Foundation

final class DemoGitHubService: GitServiceProtocol, Sendable {
    // MARK: - Singleton
    static let shared = DemoGitHubService()

    // MARK: - Init
    private init() {}

    // MARK: - Public API
    func fetchReviewRequestedPRs(
        filterDrafts: Bool = false,
        excludedLabels: [String] = []
    ) async throws -> [PullRequest] {
        try await Task.sleep(for: .seconds(0.5))

        let dateFormatter = ISO8601DateFormatter()
        let prs = [
            PullRequest(
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
            PullRequest(
                id: "demo-pr-2",
                number: 456,
                title: "Fix memory leak in background refresh task",
                htmlURL: "https://github.com/example/awesome-app/pull/123",
                state: "open",
                isDraft: false,
                user: User(login: "contributor2"),
                createdAt: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 5)),
                updatedAt: dateFormatter.string(from: Date().addingTimeInterval(-7200)),
                labels: ["bug", "high-priority"]
            ),
            PullRequest(
                id: "demo-pr-3",
                number: 789,
                title: "Update dependencies to latest versions",
                htmlURL: "https://github.com/example/backend-api/pull/789",
                state: "open",
                isDraft: true,
                user: User(login: "maintainer3"),
                createdAt: dateFormatter.string(from: Date().addingTimeInterval(-86400)),
                updatedAt: dateFormatter.string(from: Date().addingTimeInterval(-1800)),
                labels: ["dependencies", "maintenance"]
            ),
            PullRequest(
                id: "demo-pr-4",
                number: 321,
                title: "Implement dark mode support for settings panel",
                htmlURL: "https://github.com/example/ui-components/pull/321",
                state: "open",
                isDraft: false,
                user: User(login: "designer4"),
                createdAt: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 3)),
                updatedAt: dateFormatter.string(from: Date().addingTimeInterval(-5400)),
                labels: ["ui", "enhancement"]
            ),
            PullRequest(
                id: "demo-pr-5",
                number: 654,
                title: "Add comprehensive test coverage for API endpoints",
                htmlURL: "https://github.com/example/testing-suite/pull/654",
                state: "open",
                isDraft: false,
                user: User(login: "qa-engineer5"),
                createdAt: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 4)),
                updatedAt: dateFormatter.string(from: Date().addingTimeInterval(-10800)),
                labels: ["testing", "quality"]
            )
        ]

        var filtered = prs

        if filterDrafts {
            filtered = filtered.filter { !$0.isDraft }
        }

        if !excludedLabels.isEmpty {
            let excludedLabelsSet = Set(
                excludedLabels
                    .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                    .filter { !$0.isEmpty }
            )

            if !excludedLabelsSet.isEmpty {
                filtered = filtered.filter { pr in
                    !pr.labels.contains(where: { excludedLabelsSet.contains($0.lowercased()) })
                }
            }
        }

        return filtered
    }
}
