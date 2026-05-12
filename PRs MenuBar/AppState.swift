import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class AppState {

    // MARK: - Singleton
    static let shared = AppState()

    // MARK: - State

    /// All properties that change during a refresh are grouped into a single struct.
    /// Replacing this struct is ONE @Observable notification per assignment. A refresh cycle
    /// emits 2-3 (start, end-or-error, optional cleanup) instead of the 8+ that caused the
    /// recursive render→menuItemsChanged→render loop crashing the menu bar in v1.8.
    private(set) var refreshState = RefreshState()

    private(set) var isDemoMode = false
    private(set) var accounts: [ProviderAccount] = []

    private var refreshTimerTask: Task<Void, Never>?
    private var activeRefreshTask: Task<Void, Error>?
    private var retryTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var transientRetryCount = 0
    private var refreshGeneration = 0
    private var githubService: GitServiceProtocol
    /// When true, AppState fetches via `githubService` directly and skips the multi-account
    /// fan-out. Used for demo mode and tests that inject a single service.
    private var useSingleServiceMode: Bool
    private let accountManager = AccountManager.shared

    /// NetworkMonitor must be non-private so SwiftUI can observe its changes
    /// When networkMonitor.isConnected changes, views observing isOffline will update
    let networkMonitor = NetworkMonitor.shared

    // MARK: - Computed Properties

    /// These forward from refreshState so views continue to work unchanged.
    /// With @Observable, accessing these computed properties tracks refreshState as the
    /// dependency — so replacing refreshState atomically notifies all observers at once.
    var prs: [PullRequest] {
        refreshState.prs
    }

    var groupedPRs: [(String, [PullRequest])] {
        refreshState.groupedPRs
    }

    var isRefreshing: Bool {
        refreshState.isRefreshing
    }

    var lastError: GitServiceError? {
        refreshState.lastError
    }

    var accountErrors: [UUID: GitServiceError] {
        refreshState.accountErrors
    }

    var accountLastFetch: [UUID: Date] {
        refreshState.accountLastFetch
    }

    var isOffline: Bool {
        !networkMonitor.isConnected
    }

    var hasEnabledAccounts: Bool {
        !isDemoMode && accounts.contains(where: \.isEnabled)
    }

    var hasAccountErrors: Bool {
        let enabledAccountIds = Set(accounts.filter(\.isEnabled).map(\.id))
        return accountErrors.contains { enabledAccountIds.contains($0.key) }
    }

    /// Single typed error to show in the menu bar, plus how many extra accounts are affected.
    /// Falls through from refresh-wide error → first per-account error (sorted by description
    /// for stable ordering).
    var displayError: DisplayError? {
        if let lastError = refreshState.lastError {
            return DisplayError(error: lastError, additionalAccountsAffected: 0)
        }
        let enabledAccountIds = Set(accounts.filter(\.isEnabled).map(\.id))
        let enabledErrors = refreshState.accountErrors
            .filter { enabledAccountIds.contains($0.key) }
        guard !enabledErrors.isEmpty else { return nil }
        let sorted = enabledErrors.values.sorted {
            ($0.errorDescription ?? "") < ($1.errorDescription ?? "")
        }
        return DisplayError(
            error: sorted.first!,
            additionalAccountsAffected: enabledErrors.count - 1
        )
    }

    // MARK: - Init
    init(githubService: GitServiceProtocol? = nil) {
        let isDemo = UserDefaults.standard.isDemoMode
        self.isDemoMode = isDemo
        if let provided = githubService {
            self.githubService = provided
            self.useSingleServiceMode = true
        } else {
            self.githubService = isDemo ? DemoGitHubService.shared : GitHubService.shared
            self.useSingleServiceMode = isDemo
        }
        self.accounts = accountManager.getAccounts()
        // Use .notice so this is persisted in system logs
        AppLogger.app.notice("AppState initialized with \(self.accounts.count) accounts, demoMode: \(isDemo)")

        // Wire reconnect handling: NWPathMonitor reports .satisfied before DNS/DHCP are fully ready,
        // so wait briefly before triggering a refresh. Cancel any pending reconnect refresh if the
        // network flaps again.
        networkMonitor.onReconnect = { [weak self] in
            guard let self else { return }
            AppLogger.network.info("Network reconnected, scheduling refresh in 3s")
            self.reconnectTask?.cancel()
            self.reconnectTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled, let self else { return }
                await self.manualRefresh()
            }
        }

        startRefreshTimer()
    }

    // Note: deinit cannot use MainActor-isolated properties in Swift 6
    // The refreshTask will be automatically cancelled when AppState is deallocated

    var prCount: Int {
        prs.count
    }

    // MARK: - Actions
    func setDemoMode(_ enabled: Bool) {
        AppLogger.app.info("Demo mode set to: \(enabled)")
        isDemoMode = enabled
        UserDefaults.standard.isDemoMode = enabled
        githubService = enabled ? DemoGitHubService.shared : GitHubService.shared
        useSingleServiceMode = enabled
        Task { [weak self] in
            await self?.refreshPRCount()
        }
    }

    func refreshPRCount() async {
        guard useSingleServiceMode || accounts.contains(where: \.isEnabled) else { return }

        activeRefreshTask?.cancel()

        refreshGeneration += 1
        let generation = refreshGeneration

        let task = Task {
            try await performRefresh(generation: generation)
        }
        activeRefreshTask = task

        // Start: ONE atomic notification (isRefreshing + lastError together)
        var startState = refreshState
        startState.isRefreshing = true
        startState.lastError = nil
        refreshState = startState
        AppLogger.refresh.info("Starting PR refresh")

        do {
            try await task.value
            // Success: performRefresh already committed the final state atomically
        } catch is CancellationError {
            AppLogger.refresh.info("Refresh cancelled")
        } catch {
            if refreshGeneration == generation {
                // Error: ONE atomic notification (isRefreshing + lastError together)
                var errorState = refreshState
                errorState.isRefreshing = false
                errorState.lastError = Self.coerce(error)
                refreshState = errorState
            }
            AppLogger.error.error("Refresh task error: \(error.localizedDescription)")
        }

        if refreshGeneration == generation {
            // For cancellation: isRefreshing is still true, clear it now
            // For success/error: isRefreshing is already false, this is a no-op
            if refreshState.isRefreshing {
                var s = refreshState
                s.isRefreshing = false
                refreshState = s
            }
            activeRefreshTask = nil

            if refreshState.lastError != nil, !isOffline {
                scheduleTransientRetry()
            } else {
                transientRetryCount = 0
            }

            AppLogger.refresh.debug("Refresh finished, isRefreshing set to false")
        }
    }

    private func performRefresh(generation: Int) async throws {
        let filterDrafts = UserDefaults.standard.filterDrafts
        let excludedLabelsString = UserDefaults.standard.excludedLabels
        let excludedLabels = excludedLabelsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if useSingleServiceMode {
            AppLogger.refresh.debug("Fetching PRs in demo/test mode")
            let fetchedPRs = try await githubService.fetchReviewRequestedPRs(
                filterDrafts: filterDrafts,
                excludedLabels: excludedLabels
            )
            let newPRs = sortAndFilterPRs(fetchedPRs)
            // Guard: if a newer refresh has started, drop our results.
            guard refreshGeneration == generation else { return }
            // ONE atomic notification for all result state
            var newState = refreshState
            if newPRs != newState.prs {
                newState.prs = newPRs
                newState.groupedPRs = buildGroupedPRs(from: newPRs)
            }
            newState.isRefreshing = false
            refreshState = newState
            AppLogger.refresh.info("Demo/test refresh completed: \(fetchedPRs.count) PRs")
        } else {
            let enabledAccounts = accountManager.getAccounts().filter(\.isEnabled)
            let accountById = Dictionary(uniqueKeysWithValues: enabledAccounts.map { ($0.id, $0) })
            AppLogger.refresh.info("Fetching PRs from \(enabledAccounts.count) enabled accounts")
            var allPRs: [PullRequest] = []

            var newAccountErrors: [UUID: GitServiceError] = [:]
            var clearedAccountIds: Set<UUID> = []
            var newAccountLastFetch: [UUID: Date] = [:]

            await withTaskGroup(of: (UUID, Result<[PullRequest], Error>).self) { group in
                for account in enabledAccounts {
                    guard let token = accountManager.getToken(for: account) else {
                        newAccountErrors[account.id] = .tokenNotConfigured
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
                    let accountName = accountById[accountId]?.displayName ?? "Unknown"
                    switch result {
                    case let .success(fetchedPRs):
                        allPRs.append(contentsOf: fetchedPRs)
                        clearedAccountIds.insert(accountId)
                        newAccountLastFetch[accountId] = Date()
                        AppLogger.refresh.info("Fetched \(fetchedPRs.count) PRs from \(accountName)")
                    case let .failure(error):
                        // Don't store cancellation errors - they're not real errors
                        let errorMessage = error.localizedDescription.lowercased()
                        if error is CancellationError || errorMessage.contains("cancelled") {
                            AppLogger.refresh.info("Fetch cancelled for \(accountName)")
                            clearedAccountIds.insert(accountId)
                        } else {
                            newAccountErrors[accountId] = Self.coerce(error)
                            AppLogger.error
                                .error("Error fetching PRs from \(accountName): \(error.localizedDescription)")
                        }
                    }
                }
            }

            // Guard: if a newer refresh has started, drop our results.
            guard refreshGeneration == generation else { return }
            // Build entire new state locally, then assign ONCE → ONE @Observable notification
            var newState = refreshState

            var updatedErrors = newState.accountErrors
            for accountId in clearedAccountIds {
                updatedErrors[accountId] = nil
            }
            for (accountId, error) in newAccountErrors {
                updatedErrors[accountId] = error
            }
            newState.accountErrors = updatedErrors

            var updatedLastFetch = newState.accountLastFetch
            for (accountId, date) in newAccountLastFetch {
                updatedLastFetch[accountId] = date
            }
            newState.accountLastFetch = updatedLastFetch

            let newPRs = sortAndFilterPRs(allPRs)
            if newPRs != newState.prs {
                newState.prs = newPRs
                newState.groupedPRs = buildGroupedPRs(from: newPRs)
            }
            newState.isRefreshing = false
            refreshState = newState
            AppLogger.refresh.info("Refresh completed: \(allPRs.count) total PRs from all accounts")
        }
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
        let previousEnabledIds = Set(accounts.filter(\.isEnabled).map(\.id))

        accounts = accountManager.getAccounts()

        let currentEnabledIds = Set(accounts.filter(\.isEnabled).map(\.id))
        let newlyEnabledIds = currentEnabledIds.subtracting(previousEnabledIds)
        let newlyDisabledIds = previousEnabledIds.subtracting(currentEnabledIds)

        // Build updated account state locally, then assign ONCE → ONE @Observable notification
        var newState = refreshState
        newState.accountErrors = newState.accountErrors.filter { currentEnabledIds.contains($0.key) }
        newState.accountLastFetch = newState.accountLastFetch.filter { currentEnabledIds.contains($0.key) }
        for accountId in newlyEnabledIds {
            newState.accountErrors[accountId] = nil
            newState.accountLastFetch[accountId] = nil
        }
        refreshState = newState

        if !newlyEnabledIds.isEmpty {
            AppLogger.app.info("Cleared stale errors for \(newlyEnabledIds.count) newly enabled account(s)")
        }
        if !newlyDisabledIds.isEmpty {
            AppLogger.app.info("Cleared state for \(newlyDisabledIds.count) newly disabled account(s)")
        }

        AppLogger.app.info("Accounts reloaded: \(previousCount) -> \(self.accounts.count)")
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
        case error(GitServiceError)
        case unknown
    }

    struct DisplayError: Equatable {
        let error: GitServiceError
        let additionalAccountsAffected: Int
    }

    /// Coerces an arbitrary `Error` thrown from a service into our typed error.
    /// Non-GitServiceError values become `.networkError(...)` so the view layer
    /// always sees a typed value.
    static func coerce(_ error: Error) -> GitServiceError {
        if let typed = error as? GitServiceError { return typed }
        return .networkError(error.localizedDescription)
    }

    // MARK: - Test Helpers
    #if DEBUG
        func setAccountError(_ accountId: UUID, error: GitServiceError?) {
            var newState = refreshState
            newState.accountErrors[accountId] = error
            refreshState = newState
        }

        func setAccounts(_ accounts: [ProviderAccount]) {
            self.accounts = accounts
        }
    #endif

    // MARK: - Helpers
    private func scheduleTransientRetry() {
        guard transientRetryCount < 3 else {
            transientRetryCount = 0
            return
        }
        transientRetryCount += 1
        retryTask?.cancel()
        AppLogger.refresh.info("Scheduling transient retry \(self.transientRetryCount)/3 in 15s")
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled, let self else { return }
            await self.refreshPRCount()
        }
    }

    func updateGroupedPRs() {
        let newValue = buildGroupedPRs(from: prs)
        guard !groupedPRsEqual(groupedPRs, newValue) else { return }
        var newState = refreshState
        newState.groupedPRs = newValue
        refreshState = newState
    }

    private func buildGroupedPRs(from prs: [PullRequest]) -> [(String, [PullRequest])] {
        if UserDefaults.standard.groupByRepo {
            let grouped = Dictionary(grouping: prs) { $0.repositoryName }
            return grouped.sorted { $0.key < $1.key }
        } else {
            return [("", prs)]
        }
    }

    private func groupedPRsEqual(
        _ lhs: [(String, [PullRequest])],
        _ rhs: [(String, [PullRequest])]
    ) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for (l, r) in zip(lhs, rhs) {
            if l.0 != r.0 || l.1 != r.1 { return false }
        }
        return true
    }

    private func sortAndFilterPRs(_ prs: [PullRequest]) -> [PullRequest] {
        // Note: Draft and label filtering is now done at the API level for GitHub/GitLab
        // Gitea performs filtering on the client side within its service implementation
        // This function now only handles sorting

        prs.sorted { first, second in
            guard let firstDate = first.updatedDate, let secondDate = second.updatedDate else {
                return false
            }
            return UserDefaults.standard.sortNewestFirst ? firstDate > secondDate : firstDate < secondDate
        }
    }

    // MARK: - Refresh Timer
    private func startRefreshTimer() {
        refreshTimerTask?.cancel()
        let interval = UserDefaults.standard.refreshInterval
        AppLogger.refresh.info("Starting refresh timer with interval: \(interval)s")

        refreshTimerTask = Task { [weak self] in
            await self?.refreshPRCount()

            while !Task.isCancelled {
                let currentInterval = UserDefaults.standard.refreshInterval
                do {
                    try await Task.sleep(for: .seconds(currentInterval))
                    if !Task.isCancelled {
                        await self?.refreshPRCount()
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

// MARK: - RefreshState

extension AppState {
    /// All properties that change during a refresh cycle, grouped for atomic updates.
    /// Replacing this struct triggers ONE @Observable notification instead of one per property,
    /// preventing the recursive render loop that crashes the menu bar.
    struct RefreshState {
        var prs: [PullRequest] = []
        var groupedPRs: [(String, [PullRequest])] = []
        var isRefreshing = false
        var lastError: GitServiceError?
        var accountErrors: [UUID: GitServiceError] = [:]
        var accountLastFetch: [UUID: Date] = [:]
    }
}
