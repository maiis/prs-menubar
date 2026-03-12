import Foundation
import OSLog

/// Protocol for git service operations
protocol GitServiceProtocol: Sendable {
    func fetchReviewRequestedPRs(filterDrafts: Bool, excludedLabels: [String]) async throws -> [PullRequest]
}

/// Common HTTP response handling for all git services
extension GitServiceProtocol {
    /// Validates HTTP response and throws appropriate GitServiceError
    func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            switch httpResponse.statusCode {
            case 401:
                throw GitServiceError.unauthorized
            case 403:
                throw GitServiceError.forbidden
            case 429:
                let resetDate = extractRateLimitInfo(response)?.reset
                throw GitServiceError.rateLimited(resetDate: resetDate)
            default:
                throw GitServiceError.httpError(statusCode: httpResponse.statusCode)
            }
        }
    }

    /// Extracts rate limit information from response headers
    func extractRateLimitInfo(_ response: URLResponse) -> (remaining: Int?, limit: Int?, reset: Date?)? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }

        let headers = httpResponse.allHeaderFields

        // Convert all headers to lowercase dictionary for efficient lookup
        let lowercaseHeaders = headers.reduce(into: [String: String]()) { result, element in
            if let key = element.key as? String, let value = element.value as? String {
                result[key.lowercased()] = value
            }
        }

        // Look for rate limit headers with specific patterns
        // Common header names: X-RateLimit-Remaining, X-Rate-Limit-Remaining, RateLimit-Remaining
        var remaining: Int?
        var limit: Int?
        var resetTimestamp: TimeInterval?

        for (key, value) in lowercaseHeaders {
            // Only match headers containing 'ratelimit' or 'rate-limit'
            if key.contains("ratelimit") || key.contains("rate-limit") {
                // Match remaining: must end with 'remaining'
                if key.hasSuffix("remaining") {
                    remaining = Int(value)
                }
                // Match reset: must end with 'reset'
                else if key.hasSuffix("reset") {
                    resetTimestamp = TimeInterval(value)
                }
                // Match limit: must end with 'limit' but not 'remaining' or 'reset'
                else if key.hasSuffix("limit"), !key.hasSuffix("ratelimit"), !key.hasSuffix("rate-limit") {
                    limit = Int(value)
                }
            }
        }

        let reset = resetTimestamp.map { Date(timeIntervalSince1970: $0) }

        return (remaining, limit, reset)
    }

    /// Filters PRs by draft status and excluded labels (client-side)
    func filterPRs(_ prs: [PullRequest], filterDrafts: Bool, excludedLabels: [String]) -> [PullRequest] {
        var filtered = prs

        if filterDrafts {
            let beforeCount = filtered.count
            filtered = filtered.filter { !$0.isDraft }
            AppLogger.network.debug("Filtered drafts: \(beforeCount) -> \(filtered.count)")
        }

        if !excludedLabels.isEmpty {
            let excludedLabelsSet = Set(
                excludedLabels
                    .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                    .filter { !$0.isEmpty }
            )

            if !excludedLabelsSet.isEmpty {
                let beforeCount = filtered.count
                filtered = filtered.filter { pr in
                    !pr.labels.contains(where: { excludedLabelsSet.contains($0.lowercased()) })
                }
                AppLogger.network.debug("Filtered labels: \(beforeCount) -> \(filtered.count)")
            }
        }

        return filtered
    }

    /// Checks rate limit headers and logs warnings; throws if GitHub rate limit is exhausted
    func checkRateLimit(_ response: URLResponse, provider: String) throws {
        if let rateLimit = extractRateLimitInfo(response) {
            if let remaining = rateLimit.remaining, let limit = rateLimit.limit {
                AppLogger.network.debug("\(provider): Rate limit \(remaining)/\(limit)")
            }
            if let remaining = rateLimit.remaining, remaining < 10 {
                AppLogger.network.warning("\(provider): Low rate limit remaining: \(remaining)")
            }
            if let remaining = rateLimit.remaining, remaining == 0 {
                AppLogger.error.error("\(provider): Rate limit exceeded, reset: \(String(describing: rateLimit.reset))")
                throw GitServiceError.rateLimited(resetDate: rateLimit.reset)
            }
        }
    }

    /// Creates a stable, shortened identifier from a URL for use in IDs
    func normalizeURL(_ url: String) -> String {
        let normalized = url
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return String(normalized.prefix(12))
    }
}
