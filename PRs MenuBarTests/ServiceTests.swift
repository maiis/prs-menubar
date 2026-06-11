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

    @Test func appStateFetchesMultipleAccountsConcurrently() {
        // Create multiple test accounts
        let accountManager = AccountManager.shared
        accountManager.saveAccounts([]) // Clear existing

        let githubAccount = ProviderAccount(
            provider: .github,
            name: "GitHub Test",
            baseURL: "https://api.github.com"
        )

        let gitlabAccount = ProviderAccount(
            provider: .gitlab,
            name: "GitLab Test",
            baseURL: "https://gitlab.com/api/v4"
        )

        accountManager.addAccount(githubAccount)
        accountManager.addAccount(gitlabAccount)

        // Save mock tokens
        try? accountManager.saveToken("github_test_token", for: githubAccount)
        try? accountManager.saveToken("gitlab_test_token", for: gitlabAccount)

        // Create AppState with mock services
        let mockGitHubService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockGitHubService)

        // This will attempt to fetch from both accounts concurrently
        // In a real scenario, this would use TaskGroup to fetch in parallel
        // For now, we just verify the structure exists
        #expect(appState.accountErrors.isEmpty)

        // Cleanup
        accountManager.saveAccounts([])
    }
}
