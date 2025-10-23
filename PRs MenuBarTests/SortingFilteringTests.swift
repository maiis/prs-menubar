import Foundation
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
@MainActor
struct SortingFilteringTests {

    init() {
        TestHelpers.cleanupUserDefaults()
    }

    @Test func sortNewestFirst() async throws {
        let mockPRs = [
            PullRequest(
                id: "test-pr-1",
                number: 1,
                title: "Oldest PR",
                htmlURL: "https://github.com/test/repo/pull/1",
                state: "open",
                isDraft: false,
                user: User(login: "user1", avatarURL: ""),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            ),
            PullRequest(
                id: "test-pr-2",
                number: 2,
                title: "Newest PR",
                htmlURL: "https://github.com/test/repo/pull/2",
                state: "open",
                isDraft: false,
                user: User(login: "user2", avatarURL: ""),
                createdAt: "2025-01-03T00:00:00Z",
                updatedAt: "2025-01-03T00:00:00Z"
            ),
            PullRequest(
                id: "test-pr-3",
                number: 3,
                title: "Middle PR",
                htmlURL: "https://github.com/test/repo/pull/3",
                state: "open",
                isDraft: false,
                user: User(login: "user3", avatarURL: ""),
                createdAt: "2025-01-02T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z"
            )
        ]

        let defaults = UserDefaults.standard
        defaults.sortNewestFirst = true
        defaults.filterDrafts = false

        let mockService = MockGitHubService(mockPRs: mockPRs)
        let appState = AppState(githubService: mockService)
        await appState.refreshPRCount()

        #expect(appState.prs.count == 3)
        #expect(appState.prs[0].title == "Newest PR")
        #expect(appState.prs[1].title == "Middle PR")
        #expect(appState.prs[2].title == "Oldest PR")
    }

    @Test func sortOldestFirst() async throws {
        let mockPRs = [
            PullRequest(
                id: "test-pr-1",
                number: 1,
                title: "Oldest PR",
                htmlURL: "https://github.com/test/repo/pull/1",
                state: "open",
                isDraft: false,
                user: User(login: "user1", avatarURL: ""),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            ),
            PullRequest(
                id: "test-pr-2",
                number: 2,
                title: "Newest PR",
                htmlURL: "https://github.com/test/repo/pull/2",
                state: "open",
                isDraft: false,
                user: User(login: "user2", avatarURL: ""),
                createdAt: "2025-01-03T00:00:00Z",
                updatedAt: "2025-01-03T00:00:00Z"
            )
        ]

        let defaults = UserDefaults.standard
        defaults.sortNewestFirst = false
        defaults.filterDrafts = false

        let mockService = MockGitHubService(mockPRs: mockPRs)
        let appState = AppState(githubService: mockService)
        await appState.refreshPRCount()

        #expect(appState.prs.count == 2)
        #expect(appState.prs[0].title == "Oldest PR")
        #expect(appState.prs[1].title == "Newest PR")
    }

    @Test func filterDraftPRs() async throws {
        let mockPRs = [
            PullRequest(
                id: "test-pr-1",
                number: 1,
                title: "Ready PR",
                htmlURL: "https://github.com/test/repo/pull/1",
                state: "open",
                isDraft: false,
                user: User(login: "user1", avatarURL: ""),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            ),
            PullRequest(
                id: "test-pr-2",
                number: 2,
                title: "Draft PR",
                htmlURL: "https://github.com/test/repo/pull/2",
                state: "open",
                isDraft: true,
                user: User(login: "user2", avatarURL: ""),
                createdAt: "2025-01-02T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z"
            ),
            PullRequest(
                id: "test-pr-3",
                number: 3,
                title: "Another Ready PR",
                htmlURL: "https://github.com/test/repo/pull/3",
                state: "open",
                isDraft: false,
                user: User(login: "user3", avatarURL: ""),
                createdAt: "2025-01-03T00:00:00Z",
                updatedAt: "2025-01-03T00:00:00Z"
            )
        ]

        let defaults = UserDefaults.standard
        defaults.filterDrafts = true
        defaults.sortNewestFirst = true

        let mockService = MockGitHubService(mockPRs: mockPRs)
        let appState = AppState(githubService: mockService)
        await appState.refreshPRCount()

        #expect(appState.prs.count == 2)
        #expect(appState.prs[0].title == "Another Ready PR")
        #expect(appState.prs[1].title == "Ready PR")
    }
}
