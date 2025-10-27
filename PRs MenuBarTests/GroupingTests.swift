import Foundation
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
@MainActor
struct GroupingTests {

    init() {
        TestHelpers.cleanupUserDefaults()
    }

    @Test func groupByRepoDisabled() async throws {
        let mockPRs = [
            PullRequest(
                id: "test-pr-1",
                number: 1,
                title: "PR 1",
                htmlURL: "https://github.com/owner1/repo1/pull/1",
                state: "open",
                isDraft: false,
                user: User(login: "user1", avatarURL: ""),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z",
                labels: []
            ),
            PullRequest(
                id: "test-pr-2",
                number: 2,
                title: "PR 2",
                htmlURL: "https://github.com/owner2/repo2/pull/2",
                state: "open",
                isDraft: false,
                user: User(login: "user2", avatarURL: ""),
                createdAt: "2025-01-02T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z",
                labels: []
            )
        ]

        let defaults = UserDefaults.standard
        defaults.sortNewestFirst = true
        defaults.filterDrafts = false
        defaults.groupByRepo = false

        let mockService = MockGitHubService(mockPRs: mockPRs)
        let appState = AppState(githubService: mockService)
        await appState.refreshPRCount()

        let grouped = appState.groupedPRs
        #expect(grouped.count == 1)
        #expect(grouped[0].0 == "")
        #expect(grouped[0].1.count == 2)
    }

    @Test func groupByRepoEnabled() async throws {
        let mockPRs = [
            PullRequest(
                id: "test-pr-1",
                number: 1,
                title: "PR 1",
                htmlURL: "https://github.com/owner1/repo1/pull/1",
                state: "open",
                isDraft: false,
                user: User(login: "user1", avatarURL: ""),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z",
                labels: []
            ),
            PullRequest(
                id: "test-pr-2",
                number: 2,
                title: "PR 2",
                htmlURL: "https://github.com/owner2/repo2/pull/2",
                state: "open",
                isDraft: false,
                user: User(login: "user2", avatarURL: ""),
                createdAt: "2025-01-02T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z",
                labels: []
            ),
            PullRequest(
                id: "test-pr-3",
                number: 3,
                title: "PR 3",
                htmlURL: "https://github.com/owner1/repo1/pull/3",
                state: "open",
                isDraft: false,
                user: User(login: "user3", avatarURL: ""),
                createdAt: "2025-01-03T00:00:00Z",
                updatedAt: "2025-01-03T00:00:00Z",
                labels: []
            )
        ]

        let defaults = UserDefaults.standard
        defaults.sortNewestFirst = true
        defaults.filterDrafts = false
        defaults.groupByRepo = true

        let mockService = MockGitHubService(mockPRs: mockPRs)
        let appState = AppState(githubService: mockService)
        await appState.refreshPRCount()

        let grouped = appState.groupedPRs
        #expect(grouped.count == 2)

        // Repos are sorted alphabetically, so owner1/repo1 comes first
        #expect(grouped[0].0 == "owner1/repo1")
        #expect(grouped[0].1.count == 2)
        #expect(grouped[1].0 == "owner2/repo2")
        #expect(grouped[1].1.count == 1)
    }
}
