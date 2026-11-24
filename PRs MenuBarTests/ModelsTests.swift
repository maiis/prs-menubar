import Foundation
import Testing
@testable import PRs_MenuBar

struct ModelsTests {

    private func pr(
        htmlURL: String = "https://github.com/owner/repo/pull/1",
        updatedAt: String = "2025-01-01T00:00:00Z"
    ) -> PullRequest {
        PullRequest(
            id: "test-pr",
            number: 1,
            title: "Test PR",
            htmlURL: htmlURL,
            isDraft: false,
            user: User(login: "dev"),
            updatedAt: updatedAt
        )
    }

    @Test func repositoryNameAcrossProviderURLs() {
        #expect(pr(htmlURL: "https://github.com/owner/repo/pull/100").repositoryName == "owner/repo")
        #expect(pr(htmlURL: "https://gitlab.com/group/project/-/merge_requests/7").repositoryName == "group/project")
        #expect(pr(htmlURL: "https://gitea.example.com/org/app/pulls/3").repositoryName == "org/app")
    }

    @Test func repositoryNameInvalidURL() {
        #expect(pr(htmlURL: "not-a-url").repositoryName == "")
    }

    @Test func dateParsingAcrossProviderTimestampFormats() throws {
        // GitHub: whole seconds + Zulu. GitLab: fractional seconds (regression guard —
        // these used to return nil). Gitea: numeric UTC offset.
        #expect(pr(updatedAt: "2024-01-02T00:00:00Z").updatedDate != nil)
        #expect(pr(updatedAt: "2017-04-30T09:00:00.054Z").updatedDate != nil)
        let gitea = try #require(pr(updatedAt: "2020-01-01T10:00:00+01:00").updatedDate)
        // +01:00 means 09:00 UTC
        #expect(gitea == Date(timeIntervalSince1970: 1_577_869_200))
    }
}
