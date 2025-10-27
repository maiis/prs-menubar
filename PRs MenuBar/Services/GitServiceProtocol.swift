import Foundation

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

        let remainingKey = headers.keys.first { key in
            let keyStr = (key as? String)?.lowercased() ?? ""
            return keyStr.contains("ratelimit") && keyStr.contains("remaining")
        }

        let limitKey = headers.keys.first { key in
            let keyStr = (key as? String)?.lowercased() ?? ""
            return keyStr.contains("ratelimit") && keyStr.contains("limit") && !keyStr.contains("remaining")
        }

        let resetKey = headers.keys.first { key in
            let keyStr = (key as? String)?.lowercased() ?? ""
            return keyStr.contains("ratelimit") && keyStr.contains("reset")
        }

        let remaining = remainingKey.flatMap { headers[$0] as? String }.flatMap(Int.init)
        let limit = limitKey.flatMap { headers[$0] as? String }.flatMap(Int.init)
        let resetTimestamp = resetKey.flatMap { headers[$0] as? String }.flatMap(TimeInterval.init)
        let reset = resetTimestamp.map { Date(timeIntervalSince1970: $0) }

        return (remaining, limit, reset)
    }
}
