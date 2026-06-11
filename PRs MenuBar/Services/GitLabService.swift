import Foundation
import os
import OSLog

/// GitLab API service implementation
/// Uses GitLab REST API v4 to fetch merge requests where the current user is a reviewer
/// API Documentation: https://docs.gitlab.com/ee/api/merge_requests.html
final class GitLabService: GitServiceProtocol, Sendable {

    // MARK: - Constants
    private static let perPage = 100

    // MARK: - Properties
    private let baseURL: String
    private let token: String
    /// Cached user ID — GitLab requires it for the reviewer_id query but it never changes
    /// for a given token, so we only fetch it once per service instance.
    private let cachedUserId = OSAllocatedUnfairLock<Int?>(initialState: nil)

    // MARK: - Init
    nonisolated init(baseURL: String, token: String) {
        self.baseURL = baseURL
        self.token = token
    }

    // MARK: - Public API
    func fetchReviewRequestedPRs(
        filterDrafts: Bool = false,
        excludedLabels: [String] = []
    ) async throws -> [PullRequest] {
        AppLogger.network
            .info("GitLab: Starting MR fetch (filterDrafts: \(filterDrafts), excludedLabels: \(excludedLabels.count))")

        let currentUserId = try await fetchCurrentUserId()
        AppLogger.network.debug("GitLab: Current user ID: \(currentUserId)")

        var urlString =
            "\(baseURL)/merge_requests?scope=all&state=opened&reviewer_id=\(currentUserId)&per_page=\(Self.perPage)&page=1"

        if filterDrafts {
            urlString += "&wip=no"
        }

        if !excludedLabels.isEmpty {
            var allowedCharacters = CharacterSet.urlQueryAllowed
            allowedCharacters.remove(charactersIn: ",")

            let encodedLabels = excludedLabels
                .filter { !$0.isEmpty }
                .compactMap { $0.addingPercentEncoding(withAllowedCharacters: allowedCharacters) }
                .joined(separator: ",")

            if !encodedLabels.isEmpty {
                urlString += "&not[labels]=\(encodedLabels)"
            }
        }

        guard let url = URL(string: urlString) else {
            throw GitServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let mrs: [FailableDecodable<GitLabMR>] = try await performJSON(
            request,
            provider: "GitLab",
            decoder: snakeCaseDecoder
        )

        let normalizedURL = normalizeURL(baseURL)
        var prs: [PullRequest] = []
        for failable in mrs {
            guard let mr = failable.value else {
                AppLogger.network.warning("GitLab: Skipped MR due to missing fields")
                continue
            }
            prs.append(mr.toPullRequest(normalizedURL: normalizedURL))
        }

        AppLogger.network.info("GitLab: Fetched \(prs.count) MRs")
        return prs
    }

    // MARK: - Helpers
    /// Fetches the current user's ID from GitLab API. Cached per service instance after first call.
    private func fetchCurrentUserId() async throws -> Int {
        if let cached = cachedUserId.withLock({ $0 }) {
            return cached
        }

        guard let url = URL(string: "\(baseURL)/user") else {
            throw GitServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let user: GitLabUser = try await performJSON(request, provider: "GitLab")
        cachedUserId.withLock { $0 = user.id }
        return user.id
    }
}

// MARK: - GitLab DTOs

private struct GitLabUser: Decodable {
    let id: Int
}

private struct GitLabMR: Decodable {
    let iid: Int
    let projectId: Int
    let title: String
    let webUrl: String
    let state: String
    let createdAt: String
    let updatedAt: String
    let author: GitLabAuthor
    let labels: [String]?
    let draft: Bool?
    let workInProgress: Bool?

    func toPullRequest(normalizedURL: String) -> PullRequest {
        let apiDraft = draft ?? workInProgress
        let isDraft = apiDraft
            ?? (title.hasPrefix("Draft:") || title.hasPrefix("WIP:"))

        return PullRequest(
            id: "gitlab-\(normalizedURL)-\(projectId)-\(iid)",
            number: iid,
            title: title,
            htmlURL: webUrl,
            state: state.lowercased(),
            isDraft: isDraft,
            user: User(login: author.username),
            createdAt: createdAt,
            updatedAt: updatedAt,
            labels: labels ?? []
        )
    }
}

private struct GitLabAuthor: Decodable {
    let username: String
}
