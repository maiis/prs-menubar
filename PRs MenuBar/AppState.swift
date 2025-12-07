import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class AppState {

    // MARK: - Singleton
    static let shared = AppState()

    // MARK: - Properties
    private(set) var prs: [PullRequest] = []
    private(set) var isRefreshing = false
    private(set) var lastError: String?
    private(set) var lastUpdated: Date?
    private(set) var isDemoMode = false
    private(set) var accounts: [ProviderAccount] = []
    private(set) var accountErrors: [UUID: String] = [:]
    private(set) var accountLastFetch: [UUID: Date] = [:]

    private var refreshTask: Task<Void, Never>?
    private var githubService: GitServiceProtocol
    private let accountManager = AccountManager.shared
    private let networkMonitor = NetworkMonitor.shared

    // MARK: - Computed Properties
    var isOffline: Bool {
        !networkMonitor.isConnected
    }

    var hasEnabledAccounts: Bool {
        !isDemoMode && accounts.contains(where: \.isEnabled)
    }

    // MARK: - Init
    init(githubService: GitServiceProtocol? = nil) {
        let isDemo = UserDefaults.standard.isDemoMode
        self.isDemoMode = isDemo
        if let provided = githubService {
            self.githubService = provided
        } else {
            self.githubService = isDemo ? DemoGitHubService.shared : GitHubService.shared
        }
        self.accounts = accountManager.getAccounts()
        // Use .notice so this is persisted in system logs
        AppLogger.app.notice("AppState initialized with \(self.accounts.count) accounts, demoMode: \(isDemo)")
        startRefreshTimer()
    }

    // Note: deinit cannot use MainActor-isolated properties in Swift 6
    // The refreshTask will be automatically cancelled when AppState is deallocated

    var prCount: Int {
        prs.count
    }

    var groupedPRs: [(String, [PullRequest])] {
        guard UserDefaults.standard.groupByRepo else {
            return [("", prs)]
        }

        let grouped = Dictionary(grouping: prs) { $0.repositoryName }
        return grouped.sorted { $0.key < $1.key }
    }

    // MARK: - Actions
    func setDemoMode(_ enabled: Bool) {
        AppLogger.app.info("Demo mode set to: \(enabled)")
        isDemoMode = enabled
        UserDefaults.standard.isDemoMode = enabled
        githubService = enabled ? DemoGitHubService.shared : GitHubService.shared
        Task {
            await refreshPRCount()
        }
    }

    func refreshPRCount() async {
        guard !isRefreshing else {
            AppLogger.refresh.debug("Refresh already in progress, skipping")
            return
        }

        AppLogger.refresh.info("Starting PR refresh")
        isRefreshing = true
        lastError = nil

        do {
            let filterDrafts = UserDefaults.standard.filterDrafts
            let excludedLabelsString = UserDefaults.standard.excludedLabels
            let excludedLabels = excludedLabelsString
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            let isTestService = !(githubService is GitHubService) &&
                !(githubService is DemoGitHubService)

            if isDemoMode || isTestService {
                AppLogger.refresh.debug("Fetching PRs in demo/test mode")
                let fetchedPRs = try await githubService.fetchReviewRequestedPRs(
                    filterDrafts: filterDrafts,
                    excludedLabels: excludedLabels
                )
                prs = sortAndFilterPRs(fetchedPRs)
                lastUpdated = Date()
                AppLogger.refresh.info("Demo/test refresh completed: \(fetchedPRs.count) PRs")
            } else {
                let enabledAccounts = accountManager.getAccounts().filter(\.isEnabled)
                AppLogger.refresh.info("Fetching PRs from \(enabledAccounts.count) enabled accounts")
                var allPRs: [PullRequest] = []

                await withTaskGroup(of: (UUID, Result<[PullRequest], Error>).self) { group in
                    for account in enabledAccounts {
                        guard let token = accountManager.getToken(for: account) else {
                            accountErrors[account.id] = "No token found"
                            AppLogger.error.error("No token found for account: \(account.displayName)")
                            continue
                        }

                        AppLogger.refresh.debug("Starting fetch for account: \(account.displayName)")
                        group.addTask {
                            let service = GitServiceFactory.createService(for: account, token: token)
                            let result: Result<[PullRequest], Error>
                            do {
                                let prs = try await service.fetchReviewRequestedPRs(
                                    filterDrafts: filterDrafts,
                                    excludedLabels: excludedLabels
                                )
                                result = .success(prs)
                            } catch {
                                result = .failure(error)
                            }
                            return (account.id, result)
                        }
                    }

                    for await (accountId, result) in group {
                        switch result {
                        case let .success(fetchedPRs):
                            allPRs.append(contentsOf: fetchedPRs)
                            accountErrors[accountId] = nil
                            accountLastFetch[accountId] = Date()
                            if let account = enabledAccounts.first(where: { $0.id == accountId }) {
                                AppLogger.refresh.info("Fetched \(fetchedPRs.count) PRs from \(account.displayName)")
                            }
                        case let .failure(error):
                            accountErrors[accountId] = error.localizedDescription
                            if let account = enabledAccounts.first(where: { $0.id == accountId }) {
                                AppLogger.error
                                    .error(
                                        "Error fetching PRs from \(account.displayName): \(error.localizedDescription)"
                                    )
                            }
                        }
                    }
                }

                prs = sortAndFilterPRs(allPRs)
                lastUpdated = Date()
                AppLogger.refresh.info("Refresh completed: \(allPRs.count) total PRs from all accounts")
            }
        } catch {
            lastError = error.localizedDescription
            AppLogger.error.error("Top-level refresh error: \(error.localizedDescription)")
        }

        isRefreshing = false
        AppLogger.refresh.debug("Refresh finished, isRefreshing set to false")
    }

    func manualRefresh() async {
        AppLogger.refresh.info("Manual refresh triggered")
        await refreshPRCount()
    }

    func restartRefreshTimer() {
        AppLogger.refresh.info("Restarting refresh timer")
        startRefreshTimer()
    }

    func reloadAccounts() {
        let previousCount = accounts.count
        accounts = accountManager.getAccounts()
        AppLogger.app.info("Accounts reloaded: \(previousCount) -> \(self.accounts.count)")
        // Clear stale PRs from disabled/removed accounts and refresh
        prs = []
        Task { await refreshPRCount() }
    }

    func getAccountStatus(_ account: ProviderAccount) -> AccountStatus {
        if let error = accountErrors[account.id] {
            .error(error)
        } else if let lastFetch = accountLastFetch[account.id] {
            .success(lastFetch)
        } else if isRefreshing {
            .loading
        } else {
            .unknown
        }
    }

    enum AccountStatus {
        case loading
        case success(Date)
        case error(String)
        case unknown
    }

    // MARK: - Helpers
    private func sortAndFilterPRs(_ prs: [PullRequest]) -> [PullRequest] {
        // Note: Draft and label filtering is now done at the API level for GitHub/GitLab
        // Gitea performs filtering on the client side within its service implementation
        // This function now only handles sorting

        let sorted = prs.sorted { first, second in
            guard let firstDate = first.updatedDate, let secondDate = second.updatedDate else {
                return false
            }
            return UserDefaults.standard.sortNewestFirst ? firstDate > secondDate : firstDate < secondDate
        }

        return sorted
    }

    // MARK: - Refresh Timer
    private func startRefreshTimer() {
        refreshTask?.cancel()
        let interval = UserDefaults.standard.refreshInterval
        AppLogger.refresh.info("Starting refresh timer with interval: \(interval)s")

        refreshTask = Task { @MainActor in
            await refreshPRCount()

            while !Task.isCancelled {
                let currentInterval = UserDefaults.standard.refreshInterval
                do {
                    try await Task.sleep(for: .seconds(currentInterval))
                    if !Task.isCancelled {
                        await refreshPRCount()
                    }
                } catch {
                    AppLogger.error.error("Refresh timer sleep interrupted: \(error.localizedDescription)")
                    if Task.isCancelled {
                        AppLogger.refresh.info("Refresh timer cancelled")
                        break
                    }
                }
            }
        }
    }
}
