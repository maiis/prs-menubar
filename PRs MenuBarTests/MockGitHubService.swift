import Foundation
@testable import PRs_MenuBar

final class MockGitHubService: GitServiceProtocol, Sendable {
    let mockPRs: [PullRequest]
    let shouldThrowError: Bool
    let warnings: Set<FetchWarning>

    init(mockPRs: [PullRequest] = [], shouldThrowError: Bool = false, warnings: Set<FetchWarning> = []) {
        self.mockPRs = mockPRs
        self.shouldThrowError = shouldThrowError
        self.warnings = warnings
    }

    func fetchReviewRequestedPRs(
        filterDrafts: Bool = false,
        excludedLabels: [String] = []
    ) async throws -> FetchResult {
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

        return FetchResult(prs: filtered, warnings: warnings)
    }
}
