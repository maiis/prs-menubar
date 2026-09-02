import Foundation
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
@MainActor
struct AppStateTests {

    init() {
        TestHelpers.cleanupUserDefaults()
    }

    @Test func initialState() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        #expect(appState.prs.isEmpty)
        #expect(appState.prCount == 0)
        #expect(!appState.isRefreshing)
        #expect(appState.lastError == nil)
    }

    @Test func prCountComputedProperty() async {
        let mockPRs = [
            PullRequest(
                id: "test-pr-1",
                number: 100,
                title: "Test PR 1",
                htmlURL: "https://github.com/test/repo/pull/100",
                state: "open",
                isDraft: false,
                user: User(login: "testuser"),
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
                user: User(login: "testuser2"),
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

    // MARK: - hasAccountErrors Tests

    @Test func hasAccountErrors_noErrors_returnsFalse() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        #expect(appState.hasAccountErrors == false)
    }

    @Test func hasAccountErrors_enabledAccountWithError_returnsTrue() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: .unauthorized)

        #expect(appState.hasAccountErrors == true)
    }

    @Test func hasAccountErrors_disabledAccountWithError_returnsFalse() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test", isEnabled: false)
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: .unauthorized)

        #expect(appState.hasAccountErrors == false)
    }

    @Test func hasAccountErrors_nilError_returnsFalse() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: nil)

        #expect(appState.hasAccountErrors == false)
    }

    // MARK: - displayError Tests

    @Test func displayError_noErrors_returnsNil() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        #expect(appState.displayError == nil)
    }

    @Test func displayError_singleError_returnsTypedError() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: .unauthorized)

        #expect(appState.displayError?.error == .unauthorized)
        #expect(appState.displayError?.additionalAccountsAffected == 0)
    }

    @Test func displayError_multipleErrors_reportsAdditionalCount() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account1 = ProviderAccount(provider: .github, name: "GitHub")
        let account2 = ProviderAccount(provider: .gitlab, name: "GitLab")
        appState.setAccounts([account1, account2])
        appState.setAccountError(account1.id, error: .unauthorized)
        appState.setAccountError(account2.id, error: .rateLimited(resetDate: nil))

        // Sorted by errorDescription, so "API rate limit..." comes before "Unauthorized..."
        #expect(appState.displayError?.error == .rateLimited(resetDate: nil))
        #expect(appState.displayError?.additionalAccountsAffected == 1)
    }

    @Test func displayError_disabledAccountsIgnored() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account1 = ProviderAccount(provider: .github, name: "GitHub")
        let account2 = ProviderAccount(provider: .gitlab, name: "GitLab", isEnabled: false)
        appState.setAccounts([account1, account2])
        appState.setAccountError(account1.id, error: .unauthorized)
        appState.setAccountError(account2.id, error: .rateLimited(resetDate: nil))

        #expect(appState.displayError?.error == .unauthorized)
        #expect(appState.displayError?.additionalAccountsAffected == 0)
    }

    @Test func displayError_nilError_ignored() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: nil)

        #expect(appState.displayError == nil)
    }

    // MARK: - Transient Retry Gate

    @Test func perAccountTransientErrorsGateTheRetry() {
        let appState = AppState(githubService: MockGitHubService(mockPRs: []))
        let account = ProviderAccount(provider: .github, name: "Enabled")
        appState.setAccounts([account])

        #expect(!appState.hasRetriableTransientError)

        // The multi-account path never throws, so this is the only signal a retry can key on.
        appState.setAccountError(account.id, error: .timeout)
        #expect(appState.hasRetriableTransientError)

        appState.setAccountError(account.id, error: .connectionFailed)
        #expect(appState.hasRetriableTransientError)

        // A rate limit won't clear on the retry's 15s timescale.
        appState.setAccountError(account.id, error: .rateLimited(resetDate: nil))
        #expect(!appState.hasRetriableTransientError)

        appState.setAccountError(account.id, error: .unauthorized)
        #expect(!appState.hasRetriableTransientError)
    }

    @Test func aDisabledAccountsErrorDoesNotGateTheRetry() {
        let appState = AppState(githubService: MockGitHubService(mockPRs: []))
        let disabled = ProviderAccount(provider: .gitlab, name: "Disabled", isEnabled: false)
        appState.setAccounts([disabled])

        appState.setAccountError(disabled.id, error: .timeout)
        #expect(!appState.hasRetriableTransientError)
    }

    // MARK: - Reduced Resource Usage

    @Test func prefersReducedResourceUsageTracksTheSystemFlag() {
        let appState = AppState(githubService: MockGitHubService(mockPRs: []))

        #expect(!appState.prefersReducedResourceUsage)

        appState.setPrefersReducedResourceUsage(true)
        #expect(appState.prefersReducedResourceUsage)

        appState.setPrefersReducedResourceUsage(true)
        #expect(appState.prefersReducedResourceUsage)

        appState.setPrefersReducedResourceUsage(false)
        #expect(!appState.prefersReducedResourceUsage)
    }

    // MARK: - Account Order

    @Test func reloadAccountOrderRepublishesThePersistedOrder() {
        let key = "providerAccounts"
        let previous = UserDefaults.standard.data(forKey: key)
        defer {
            if let previous {
                UserDefaults.standard.set(previous, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        let first = ProviderAccount(provider: .github, name: "First")
        let second = ProviderAccount(provider: .gitlab, name: "Second")
        AccountManager.shared.saveAccounts([first, second])

        let appState = AppState(githubService: MockGitHubService(mockPRs: []))
        #expect(appState.accounts.map(\.name) == ["First", "Second"])

        AccountManager.shared.saveAccounts([second, first])
        appState.reloadAccountOrder()

        #expect(appState.accounts.map(\.name) == ["Second", "First"])
    }
}
