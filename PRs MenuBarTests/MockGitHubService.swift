@testable import PRs_MenuBar

final class MockGitHubService: GitHubServiceProtocol, Sendable {
    let mockPRs: [PullRequest]
    let shouldThrowError: Bool

    init(mockPRs: [PullRequest] = [], shouldThrowError: Bool = false) {
        self.mockPRs = mockPRs
        self.shouldThrowError = shouldThrowError
    }

    func fetchReviewRequestedPRs() async throws -> [PullRequest] {
        if shouldThrowError {
            throw GitHubError.invalidResponse
        }
        return mockPRs
    }
}
