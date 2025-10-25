import Foundation
@testable import PRs_MenuBar

final class MockGitHubService: GitHubServiceProtocol, Sendable {
    let mockPRs: [PullRequest]
    let shouldThrowError: Bool

    init(mockPRs: [PullRequest] = [], shouldThrowError: Bool = false) {
        self.mockPRs = mockPRs
        self.shouldThrowError = shouldThrowError
    }

    func fetchReviewRequestedPRs(
        filterDrafts: Bool = false,
        excludedLabels: [String] = []
    ) async throws -> [PullRequest] {
        if shouldThrowError {
            throw GitServiceError.invalidResponse
        }

        // Apply filtering to mock data to match real service behavior
        var filtered = mockPRs

        if filterDrafts {
            filtered = filtered.filter { !$0.isDraft }
        }

        if !excludedLabels.isEmpty {
            let excludedLabelsLowercase = excludedLabels
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty }

            if !excludedLabelsLowercase.isEmpty {
                filtered = filtered.filter { pr in
                    let prLabelsLowercase = pr.labels.map { $0.lowercased() }
                    return !prLabelsLowercase.contains(where: { excludedLabelsLowercase.contains($0) })
                }
            }
        }

        return filtered
    }
}
