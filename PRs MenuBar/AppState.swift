import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    private(set) var prs: [PullRequest] = []
    private(set) var isRefreshing: Bool = false
    private(set) var lastError: String? = nil
    private(set) var lastUpdated: Date? = nil
    private(set) var isDemoMode: Bool = false

    var prCount: Int {
        prs.count
    }

    private var refreshTask: Task<Void, Never>?
    private var githubService: GitHubServiceProtocol

    init(githubService: GitHubServiceProtocol? = nil) {
        let isDemo = UserDefaults.standard.isDemoMode
        self.isDemoMode = isDemo
        self.githubService = githubService ?? (isDemo ? DemoGitHubService.shared : GitHubService.shared)
        startRefreshTimer()
    }

    func setDemoMode(_ enabled: Bool) {
        isDemoMode = enabled
        UserDefaults.standard.isDemoMode = enabled
        githubService = enabled ? DemoGitHubService.shared : GitHubService.shared
        Task {
            await refreshPRCount()
        }
    }

    func refreshPRCount() async {
        guard !isRefreshing else { return }

        isRefreshing = true
        lastError = nil

        do {
            let fetchedPRs = try await githubService.fetchReviewRequestedPRs()
            prs = fetchedPRs
            lastUpdated = Date()
        } catch {
            lastError = error.localizedDescription
        }

        isRefreshing = false
    }

    func cancelRefreshTimer() {
        refreshTask?.cancel()
    }

    private func startRefreshTimer() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            await refreshPRCount()

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(600))

                if !Task.isCancelled {
                    await refreshPRCount()
                }
            }
        }
    }

    func manualRefresh() async {
        await refreshPRCount()
    }
}
