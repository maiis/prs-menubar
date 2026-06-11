import Foundation
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
@MainActor
struct ServiceTests {

    init() {
        TestHelpers.cleanupUserDefaults()
    }

    // MARK: - GitServiceFactory Tests

    @Test func gitServiceFactoryCreatesGitHubService() {
        let account = ProviderAccount(
            provider: .github,
            name: "Test GitHub",
            baseURL: "https://api.github.com"
        )

        let service = GitServiceFactory.createService(for: account, token: "test_token")

        #expect(service is GitHubService)
    }

    @Test func gitServiceFactoryCreatesGitLabService() {
        let account = ProviderAccount(
            provider: .gitlab,
            name: "Test GitLab",
            baseURL: "https://gitlab.com/api/v4"
        )

        let service = GitServiceFactory.createService(for: account, token: "test_token")

        #expect(service is GitLabService)
    }

    @Test func gitServiceFactoryCreatesGiteaService() {
        let account = ProviderAccount(
            provider: .gitea,
            name: "Test Gitea",
            baseURL: "https://gitea.example.com/api/v1"
        )

        let service = GitServiceFactory.createService(for: account, token: "test_token")

        #expect(service is GiteaService)
    }

    // MARK: - GitServiceProtocol HTTP Response Validation Tests

    @Test func validateHTTPResponseSucceedsFor200() throws {
        let service = GitHubService(token: "test")
        let url = try #require(URL(string: "https://api.github.com"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))

        // Should not throw (the test is `throws`, so a thrown error fails it)
        try service.validateHTTPResponse(response)
    }

    @Test func validateHTTPResponseThrowsFor401() throws {
        let service = GitHubService(token: "test")
        let url = try #require(URL(string: "https://api.github.com"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        ))

        do {
            try service.validateHTTPResponse(response)
            Issue.record("Expected unauthorized error")
        } catch let error as GitServiceError {
            if case .unauthorized = error {
                // Expected
            } else {
                Issue.record("Expected unauthorized error, got \(error)")
            }
        }
    }

    @Test func validateHTTPResponseThrowsFor403() throws {
        let service = GitHubService(token: "test")
        let url = try #require(URL(string: "https://api.github.com"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 403,
            httpVersion: nil,
            headerFields: nil
        ))

        do {
            try service.validateHTTPResponse(response)
            Issue.record("Expected forbidden error")
        } catch let error as GitServiceError {
            if case .forbidden = error {
                // Expected
            } else {
                Issue.record("Expected forbidden error, got \(error)")
            }
        }
    }

    @Test func validateHTTPResponseThrowsFor429WithRateLimit() throws {
        let service = GitHubService(token: "test")
        let url = try #require(URL(string: "https://api.github.com"))
        let resetDate = Date().addingTimeInterval(3600)
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 429,
            httpVersion: nil,
            headerFields: [
                "X-RateLimit-Reset": String(Int(resetDate.timeIntervalSince1970))
            ]
        ))

        do {
            try service.validateHTTPResponse(response)
            Issue.record("Expected rate limited error")
        } catch let error as GitServiceError {
            if case let .rateLimited(date) = error {
                #expect(date != nil)
            } else {
                Issue.record("Expected rate limited error, got \(error)")
            }
        }
    }

    // MARK: - Concurrent Account Fetching Tests

    @Test func appStateFetchesMultipleAccountsConcurrently() async throws {
        StubURLProtocol.register()
        defer {
            StubURLProtocol.unregister()
            AccountManager.shared.saveAccounts([])
        }

        // GitHub succeeds with one PR; GitLab's user lookup fails with 401.
        StubURLProtocol.responder = { request in
            if request.url?.host?.contains("github") == true {
                return .init(json: """
                {"data":{"search":{"nodes":[
                  {"id":"PR_1","number":1,"title":"Feat","url":"https://github.com/o/r/pull/1",
                   "state":"OPEN","isDraft":false,"createdAt":"2024-01-01T00:00:00Z",
                   "updatedAt":"2024-01-02T00:00:00Z","author":{"login":"alice"},"labels":{"nodes":[]}}
                ]}}}
                """)
            }
            return .init(statusCode: 401, json: #"{"message":"unauthorized"}"#)
        }

        let accountManager = AccountManager.shared
        accountManager.saveAccounts([])
        let githubAccount = ProviderAccount(provider: .github, name: "GitHub Test", baseURL: "https://api.github.com")
        let gitlabAccount = ProviderAccount(
            provider: .gitlab,
            name: "GitLab Test",
            baseURL: "https://gitlab.com/api/v4"
        )
        accountManager.addAccount(githubAccount)
        accountManager.addAccount(gitlabAccount)
        try accountManager.saveToken("github_test_token", for: githubAccount)
        try accountManager.saveToken("gitlab_test_token", for: gitlabAccount)

        // AppState() (no injected service) exercises the real multi-account TaskGroup fan-out.
        // It also kicks off one timer-driven refresh at init; refreshing twice guarantees a fully
        // completed refresh whose result we then assert (both produce identical stubbed output).
        let appState = AppState()
        await appState.refreshPRCount()
        await appState.refreshPRCount()

        // The successful account's PR is present; the failing account is isolated to its own error.
        #expect(appState.prs.map(\.number) == [1])
        #expect(appState.accountErrors[gitlabAccount.id] == .unauthorized)
        #expect(appState.accountErrors[githubAccount.id] == nil)
    }
}
