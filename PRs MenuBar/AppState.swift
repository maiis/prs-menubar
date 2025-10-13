import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    static let shared = AppState()
    
    var prs: [PullRequest] = []
    var isRefreshing: Bool = false
    var lastError: String? = nil
    var lastUpdated: Date? = nil

    var prCount: Int {
        prs.count
    }

    private var refreshTask: Task<Void, Never>?

    init() {
        startRefreshTimer()
    }

    func refreshPRCount() async {
        isRefreshing = true
        lastError = nil

        do {
            let fetchedPRs = try await GitHubService.shared.fetchReviewRequestedPRs()
            prs = fetchedPRs
            lastUpdated = Date()
        } catch {
            lastError = error.localizedDescription
        }

        isRefreshing = false
    }

    private func startRefreshTimer() {
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
