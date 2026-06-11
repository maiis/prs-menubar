import Foundation
import Testing
@testable import PRs_MenuBar

/// Exercises the `Decodable` parsing in the three services end-to-end (request → stubbed JSON →
/// `PullRequest`), covering `FailableDecodable` skip-on-malformed-node, snake_case mapping, and
/// draft precedence — the code rewritten from `JSONSerialization` on this branch.
@Suite(.serialized)
@MainActor
final class ServiceDecodingTests {

    init() {
        StubURLProtocol.register()
    }

    deinit { StubURLProtocol.unregister() }

    // MARK: - GitLab

    @Test func gitLabDecodesMRsAndSkipsMalformed() async throws {
        let mrs = """
        [
          {"iid":1,"project_id":10,"title":"Add feature","web_url":"https://gitlab.com/o/r/-/merge_requests/1",
           "state":"opened","created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-02T00:00:00Z",
           "author":{"username":"alice"},"labels":["bug"],"draft":false},
          {"iid":2,"project_id":10,"title":"Draft: stuff","web_url":"https://gitlab.com/o/r/-/merge_requests/2",
           "state":"opened","created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-02T00:00:00Z",
           "author":{"username":"bob"},"labels":[],"work_in_progress":true},
          {"iid":99,"broken":true},
          {"iid":4,"project_id":10,"title":"No labels key","web_url":"https://gitlab.com/o/r/-/merge_requests/4",
           "state":"opened","created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-02T00:00:00Z",
           "author":{"username":"carol"}},
          {"iid":5,"project_id":10,"title":"WIP: title fallback","web_url":"https://gitlab.com/o/r/-/merge_requests/5",
           "state":"opened","created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-02T00:00:00Z",
           "author":{"username":"dave"},"labels":[]}
        ]
        """
        StubURLProtocol.responder = { request in
            if request.url?.path.hasSuffix("/user") == true {
                return .init(json: #"{"id": 42}"#)
            }
            return .init(json: mrs)
        }

        let service = GitLabService(baseURL: "https://gitlab.com/api/v4", token: "t")
        let prs = try await service.fetchReviewRequestedPRs(filterDrafts: false, excludedLabels: [])

        #expect(prs.count == 4) // iid 99 (missing fields) skipped
        #expect(prs.map(\.number) == [1, 2, 4, 5])
        // snake_case mapping (web_url → htmlURL, project_id used in id)
        #expect(prs[0].htmlURL == "https://gitlab.com/o/r/-/merge_requests/1")
        #expect(prs[0].user.login == "alice")
        #expect(prs[0].labels == ["bug"])
        // draft precedence: explicit draft:false wins
        #expect(prs[0].isDraft == false)
        // work_in_progress true wins over the (also-draft-looking) title
        #expect(prs[1].isDraft == true)
        // missing labels key tolerated (regression guard) → empty labels, not a dropped MR
        #expect(prs[2].number == 4)
        #expect(prs[2].labels == [])
        // no api draft flag → falls back to title prefix "WIP:"
        #expect(prs[3].isDraft == true)
    }

    // MARK: - Gitea

    @Test func giteaDecodesIssuesAndSkipsMalformed() async throws {
        let issues = """
        [
          {"number":1,"title":"Add feature","html_url":"https://gitea.example.com/owner/repo/pulls/1",
           "state":"open","created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-02T00:00:00Z",
           "user":{"login":"alice"},"labels":[{"name":"bug"}],"draft":false},
          {"number":2,"title":"Ready title","html_url":"https://gitea.example.com/owner/repo/pulls/2",
           "state":"open","created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-02T00:00:00Z",
           "user":{"login":"bob"},"labels":[],"draft":true},
          {"number":3,"title":"[WIP] title fallback","html_url":"https://gitea.example.com/owner/repo/pulls/3",
           "state":"open","created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-02T00:00:00Z",
           "user":{"login":"carol"}},
          {"number":4,"title":"Bad URL","html_url":"https://gitea.example.com/",
           "state":"open","created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-02T00:00:00Z",
           "user":{"login":"dave"}},
          {"number":99,"broken":true}
        ]
        """
        StubURLProtocol.responder = { _ in .init(json: issues) }

        let service = GiteaService(baseURL: "https://gitea.example.com/api/v1", token: "t")
        let prs = try await service.fetchReviewRequestedPRs(filterDrafts: false, excludedLabels: [])

        // #4 (unparseable owner/repo) and #99 (missing fields) are dropped
        #expect(prs.map(\.number) == [1, 2, 3])
        #expect(prs[0].user.login == "alice")
        #expect(prs[0].labels == ["bug"])
        #expect(prs[0].repositoryName == "owner/repo")
        #expect(prs[0].isDraft == false)
        #expect(prs[1].isDraft == true) // explicit draft flag
        #expect(prs[2].isDraft == true) // "[WIP]" title fallback
    }

    // MARK: - GitHub

    @Test func gitHubDecodesNodesAndSkipsNullAuthor() async throws {
        let body = """
        {"data":{"search":{"nodes":[
          {"id":"PR_1","number":1,"title":"Add feature","url":"https://github.com/owner/repo/pull/1",
           "state":"OPEN","isDraft":false,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-02T00:00:00Z",
           "author":{"login":"alice"},"labels":{"nodes":[{"name":"bug"},{"name":"p1"}]}},
          {"id":"PR_2","number":2,"title":"Ghost author","url":"https://github.com/owner/repo/pull/2",
           "state":"OPEN","createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-02T00:00:00Z",
           "author":null,"labels":{"nodes":[]}},
          {"id":"PR_3","title":"Missing number","url":"https://github.com/owner/repo/pull/3",
           "state":"OPEN","createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-02T00:00:00Z",
           "author":{"login":"carol"}}
        ]}}}
        """
        StubURLProtocol.responder = { _ in .init(json: body) }

        let service = GitHubService(token: "t")
        let prs = try await service.fetchReviewRequestedPRs(filterDrafts: false, excludedLabels: [])

        #expect(prs.count == 1) // null-author and missing-number nodes skipped
        #expect(prs[0].number == 1)
        #expect(prs[0].state == "open") // lowercased
        #expect(prs[0].user.login == "alice")
        #expect(prs[0].labels == ["bug", "p1"])
        #expect(prs[0].isDraft == false)
    }

    @Test func gitHubSurfacesGraphQLErrors() async {
        StubURLProtocol.responder = { _ in
            .init(json: #"{"errors":[{"message":"Bad credentials"}]}"#)
        }
        let service = GitHubService(token: "t")
        await #expect(throws: GitServiceError.networkError("Bad credentials")) {
            try await service.fetchReviewRequestedPRs(filterDrafts: false, excludedLabels: [])
        }
    }

    // MARK: - normalizeURL / FNV-1a

    @Test func normalizeURLIsDeterministicAndCollisionResistant() {
        let service = GiteaService(baseURL: "https://x", token: "t")
        let a1 = service.normalizeURL("https://gitea.example.com")
        let a2 = service.normalizeURL("https://gitea.example.com")
        #expect(a1 == a2) // deterministic across calls
        #expect(!a1.isEmpty)
        // distinct hosts must not collide (the reason FNV replaced the prefix scheme)
        #expect(a1 != service.normalizeURL("https://gitea.example.org"))
        #expect(a1 != service.normalizeURL("https://git.example.com"))
        // scheme is ignored: http and https normalize identically
        #expect(a1 == service.normalizeURL("http://gitea.example.com"))
        // base36 output is lowercase alphanumeric
        #expect(a1.allSatisfy { $0.isNumber || ($0.isLetter && $0.isLowercase) })
    }
}
