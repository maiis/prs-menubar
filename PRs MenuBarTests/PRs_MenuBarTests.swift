import Testing
import Foundation
@testable import PRs_MenuBar

// MARK: - Models Tests
struct ModelsTests {

    @Test func pullRequestDecoding() async throws {
        let json = """
        {
            "id": 123,
            "number": 456,
            "title": "Test PR",
            "html_url": "https://github.com/test/repo/pull/456",
            "state": "open",
            "user": {
                "login": "testuser",
                "avatar_url": "https://example.com/avatar.png"
            },
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-01-02T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let pr = try decoder.decode(PullRequest.self, from: json)

        #expect(pr.id == 123)
        #expect(pr.number == 456)
        #expect(pr.title == "Test PR")
        #expect(pr.htmlURL == "https://github.com/test/repo/pull/456")
        #expect(pr.state == "open")
        #expect(pr.user.login == "testuser")
        #expect(pr.repositoryName == "test/repo")
        #expect(pr.updatedDate != nil)
        #expect(pr.truncatedTitle == "Test PR")
    }

    @Test func pullRequestTitleTruncation() async throws {
        let shortPR = PullRequest(
            id: 1,
            number: 1,
            title: "Short title",
            htmlURL: "https://github.com/test/repo/pull/1",
            state: "open",
            user: User(login: "test", avatarURL: "https://example.com/avatar.png"),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z"
        )
        #expect(shortPR.truncatedTitle == "Short title")

        let longPR = PullRequest(
            id: 2,
            number: 2,
            title: "This is a very long pull request title that exceeds thirty-five characters",
            htmlURL: "https://github.com/test/repo/pull/2",
            state: "open",
            user: User(login: "test", avatarURL: "https://example.com/avatar.png"),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z"
        )
        #expect(longPR.truncatedTitle == "This is a very long pull request ti…")
    }

    @Test func searchResponseDecoding() async throws {
        let json = """
        {
            "total_count": 2,
            "incomplete_results": false,
            "items": [
                {
                    "id": 1,
                    "number": 100,
                    "title": "First PR",
                    "html_url": "https://github.com/owner1/repo1/pull/100",
                    "state": "open",
                    "user": {
                        "login": "user1",
                        "avatar_url": "https://example.com/avatar1.png"
                    },
                    "created_at": "2025-01-01T00:00:00Z",
                    "updated_at": "2025-01-02T00:00:00Z"
                },
                {
                    "id": 2,
                    "number": 200,
                    "title": "Second PR",
                    "html_url": "https://github.com/owner2/repo2/pull/200",
                    "state": "open",
                    "user": {
                        "login": "user2",
                        "avatar_url": "https://example.com/avatar2.png"
                    },
                    "created_at": "2025-01-01T00:00:00Z",
                    "updated_at": "2025-01-02T00:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(GitHubSearchResponse.self, from: json)

        #expect(response.totalCount == 2)
        #expect(response.items.count == 2)
        #expect(response.items[0].title == "First PR")
        #expect(response.items[1].title == "Second PR")
        #expect(response.items[0].repositoryName == "owner1/repo1")
        #expect(response.items[1].repositoryName == "owner2/repo2")
    }

    @Test func repositoryNameInvalidURL() async throws {
        let pr = PullRequest(
            id: 99,
            number: 99,
            title: "Bad URL PR",
            htmlURL: "not-a-url",
            state: "open",
            user: User(login: "u", avatarURL: "https://example.com/a.png"),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z"
        )
        #expect(pr.repositoryName == "")
    }
}

// MARK: - AppState Tests
@MainActor
struct AppStateTests {

    @Test func initialState() async throws {
        let appState = AppState()

        #expect(appState.prs.isEmpty)
        #expect(appState.prCount == 0)
        #expect(appState.isRefreshing == false)
        #expect(appState.lastError == nil)
        #expect(appState.lastUpdated == nil)
    }

    @Test func prCountComputedProperty() async throws {
        let appState = AppState()

        #expect(appState.prCount == 0)

        // Manually set PRs to test computed property
        let mockPRs = [
            PullRequest(
                id: 1,
                number: 100,
                title: "Test PR 1",
                htmlURL: "https://github.com/test/repo/pull/100",
                state: "open",
                user: User(login: "testuser", avatarURL: "https://example.com/avatar.png"),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z"
            ),
            PullRequest(
                id: 2,
                number: 200,
                title: "Test PR 2",
                htmlURL: "https://github.com/test/repo/pull/200",
                state: "open",
                user: User(login: "testuser2", avatarURL: "https://example.com/avatar2.png"),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z"
            )
        ]

        appState.prs = mockPRs
        #expect(appState.prCount == 2)
    }
}


