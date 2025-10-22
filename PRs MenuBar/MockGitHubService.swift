import Foundation

final class MockGitHubService: GitHubServiceProtocol, Sendable {
  static let shared = MockGitHubService()

  init() {}

  func fetchReviewRequestedPRs() async throws -> [PullRequest] {
    [
      PullRequest(
        id: 1,
        number: 142,
        title: "Add dark mode support to settings panel",
        htmlURL: "https://github.com/apple/swift/pull/142",
        state: "open",
        user: User(
          login: "johndoe",
          avatarURL: "https://avatars.githubusercontent.com/u/1?v=4"
        ),
        createdAt: "2025-10-15T10:30:00Z",
        updatedAt: "2025-10-20T14:22:00Z"
      ),
      PullRequest(
        id: 2,
        number: 89,
        title: "Fix memory leak in background task manager",
        htmlURL: "https://github.com/facebook/react/pull/89",
        state: "open",
        user: User(
          login: "sarahsmith",
          avatarURL: "https://avatars.githubusercontent.com/u/2?v=4"
        ),
        createdAt: "2025-10-18T09:15:00Z",
        updatedAt: "2025-10-21T08:45:00Z"
      ),
      PullRequest(
        id: 3,
        number: 256,
        title: "Implement lazy loading for image gallery component",
        htmlURL: "https://github.com/microsoft/vscode/pull/256",
        state: "open",
        user: User(
          login: "alexchen",
          avatarURL: "https://avatars.githubusercontent.com/u/3?v=4"
        ),
        createdAt: "2025-10-19T16:20:00Z",
        updatedAt: "2025-10-21T09:10:00Z"
      ),
      PullRequest(
        id: 4,
        number: 523,
        title: "Refactor authentication flow to use new OAuth2 provider",
        htmlURL: "https://github.com/vercel/next.js/pull/523",
        state: "open",
        user: User(
          login: "mikelee",
          avatarURL: "https://avatars.githubusercontent.com/u/4?v=4"
        ),
        createdAt: "2025-10-17T11:05:00Z",
        updatedAt: "2025-10-20T17:30:00Z"
      ),
      PullRequest(
        id: 5,
        number: 78,
        title: "Update dependencies and fix security vulnerabilities",
        htmlURL: "https://github.com/tailwindlabs/tailwindcss/pull/78",
        state: "open",
        user: User(
          login: "emilyjones",
          avatarURL: "https://avatars.githubusercontent.com/u/5?v=4"
        ),
        createdAt: "2025-10-16T13:45:00Z",
        updatedAt: "2025-10-21T10:00:00Z"
      )
    ]
  }
}
