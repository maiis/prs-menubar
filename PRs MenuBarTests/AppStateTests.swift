import Foundation
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
@MainActor
struct AppStateTests {

    init() {
        TestHelpers.cleanupUserDefaults()
    }

    @Test func initialState() async throws {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        #expect(appState.prs.isEmpty)
        #expect(appState.prCount == 0)
        #expect(appState.isRefreshing == false)
        #expect(appState.lastError == nil)
        #expect(appState.lastUpdated == nil)
    }

    @Test func prCountComputedProperty() async throws {
        let mockPRs = [
            PullRequest(
                id: "test-pr-1",
                number: 100,
                title: "Test PR 1",
                htmlURL: "https://github.com/test/repo/pull/100",
                state: "open",
                isDraft: false,
                user: User(login: "testuser", avatarURL: "https://example.com/avatar.png"),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z",
                labels: []
            ),
            PullRequest(
                id: "test-pr-2",
                number: 200,
                title: "Test PR 2",
                htmlURL: "https://github.com/test/repo/pull/200",
                state: "open",
                isDraft: false,
                user: User(login: "testuser2", avatarURL: "https://example.com/avatar2.png"),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z",
                labels: []
            )
        ]

        let mockService = MockGitHubService(mockPRs: mockPRs)
        let appState = AppState(githubService: mockService)

        await appState.refreshPRCount()

        #expect(appState.prCount == 2)
        #expect(appState.prs.count == 2)
    }
}
