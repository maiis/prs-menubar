import Foundation
import Testing
@testable import PRs_MenuBar

struct ModelsTests {

    @Test func pullRequestDecoding() async throws {
        let json = """
        {
            "id": "PR_kwDOABCD123",
            "number": 456,
            "title": "Test PR",
            "html_url": "https://github.com/test/repo/pull/456",
            "state": "open",
            "isDraft": false,
            "user": {
                "login": "testuser",
                "avatar_url": "https://example.com/avatar.png"
            },
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-01-02T00:00:00Z",
            "labels": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let pr = try decoder.decode(PullRequest.self, from: json)

        #expect(pr.id == "PR_kwDOABCD123")
        #expect(pr.number == 456)
        #expect(pr.title == "Test PR")
        #expect(pr.htmlURL == "https://github.com/test/repo/pull/456")
        #expect(pr.state == "open")
        #expect(!pr.isDraft)
        #expect(pr.user.login == "testuser")
        #expect(pr.repositoryName == "test/repo")
        #expect(pr.updatedDate != nil)
        #expect(pr.truncatedTitle == "Test PR")
        #expect(pr.labels == [])
    }

    @Test func pullRequestTitleTruncation() async throws {
        let shortPR = PullRequest(
            id: "test-pr-1",
            number: 1,
            title: "Short title",
            htmlURL: "https://github.com/test/repo/pull/1",
            state: "open",
            isDraft: false,
            user: User(login: "test", avatarURL: "https://example.com/avatar.png"),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z",
            labels: []
        )
        #expect(shortPR.truncatedTitle == "Short title")

        let longPR = PullRequest(
            id: "test-pr-2",
            number: 2,
            title: "This is a very long pull request title that exceeds thirty-five characters",
            htmlURL: "https://github.com/test/repo/pull/2",
            state: "open",
            isDraft: false,
            user: User(login: "test", avatarURL: "https://example.com/avatar.png"),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z",
            labels: []
        )
        #expect(longPR.truncatedTitle == "This is a very long pull request ti…")
    }

    @Test func repositoryNameInvalidURL() async throws {
        let pr = PullRequest(
            id: "test-pr-99",
            number: 99,
            title: "Bad URL PR",
            htmlURL: "not-a-url",
            state: "open",
            isDraft: false,
            user: User(login: "u", avatarURL: "https://example.com/a.png"),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z",
            labels: []
        )
        #expect(pr.repositoryName == "")
    }
}
