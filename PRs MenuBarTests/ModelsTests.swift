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
    
    @Test func repositoryNameCaching() async throws {
        // Test that repository name is cached and consistent
        let pr = PullRequest(
            id: "test-pr-cache",
            number: 100,
            title: "Cache Test PR",
            htmlURL: "https://github.com/owner/repo/pull/100",
            state: "open",
            isDraft: false,
            user: User(login: "test", avatarURL: "https://example.com/avatar.png"),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z",
            labels: []
        )
        
        // Access repository name multiple times to verify consistency
        let firstAccess = pr.repositoryName
        let secondAccess = pr.repositoryName
        let thirdAccess = pr.repositoryName
        
        #expect(firstAccess == "owner/repo")
        #expect(secondAccess == "owner/repo")
        #expect(thirdAccess == "owner/repo")
        #expect(firstAccess == secondAccess)
        #expect(secondAccess == thirdAccess)
    }
    
    @Test func pullRequestEncodingDecoding() async throws {
        // Test that encoding and decoding preserves cached values
        let original = PullRequest(
            id: "test-pr-encode",
            number: 200,
            title: "Encode Test PR",
            htmlURL: "https://github.com/test/myrepo/pull/200",
            state: "open",
            isDraft: false,
            user: User(login: "coder", avatarURL: "https://example.com/avatar.png"),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-02T00:00:00Z",
            labels: ["bug", "priority"]
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PullRequest.self, from: data)
        
        // Verify all properties match including cached repository name
        #expect(decoded.id == original.id)
        #expect(decoded.number == original.number)
        #expect(decoded.title == original.title)
        #expect(decoded.htmlURL == original.htmlURL)
        #expect(decoded.state == original.state)
        #expect(decoded.isDraft == original.isDraft)
        #expect(decoded.repositoryName == original.repositoryName)
        #expect(decoded.repositoryName == "test/myrepo")
        #expect(decoded.labels == original.labels)
    }
}
