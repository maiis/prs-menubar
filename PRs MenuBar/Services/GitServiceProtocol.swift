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
        
        // Convert all headers to lowercase dictionary for efficient lookup
        let lowercaseHeaders = headers.reduce(into: [String: String]()) { result, element in
            if let key = element.key as? String, let value = element.value as? String {
                result[key.lowercased()] = value
            }
        }

        // Look for rate limit headers with common patterns
        var remaining: Int?
        var limit: Int?
        var resetTimestamp: TimeInterval?
        
        for (key, value) in lowercaseHeaders {
            if key.contains("ratelimit") {
                if key.contains("remaining") {
                    remaining = Int(value)
                } else if key.contains("reset") {
                    resetTimestamp = TimeInterval(value)
                } else if key.contains("limit") {
                    limit = Int(value)
                }
            }
        }
        
        let reset = resetTimestamp.map { Date(timeIntervalSince1970: $0) }

        return (remaining, limit, reset)
    }
}
