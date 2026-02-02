import Foundation
import OSLog

// MARK: - RetryPolicy Configuration

/// Configuration for network request retry behavior
let defaultRetryPolicy = RetryPolicy(
    maxAttempts: 3,
    baseDelay: 1.0,
    maxDelay: 30.0,
    retryableStatusCodes: [408, 429, 500, 502, 503, 504]
)

struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let retryableStatusCodes: Set<Int>

    static var `default`: RetryPolicy {
        defaultRetryPolicy
    }

    nonisolated func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))
        let jitter = Double.random(in: 0 ... 0.3) * exponentialDelay
        return min(exponentialDelay + jitter, maxDelay)
    }
}

// MARK: - Retry Decision

private enum RetryDecision: Sendable {
    case retry(delay: TimeInterval)
    case retryAfterRateLimit(delay: TimeInterval)
    case doNotRetry(reason: String)
}

// MARK: - URLSession Extension

extension URLSession {
    func data(
        for request: URLRequest,
        retryPolicy: RetryPolicy
    ) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 1 ... retryPolicy.maxAttempts {
            do {
                let (data, response) = try await data(for: request)

                let decision = shouldRetry(
                    response: response,
                    attempt: attempt,
                    policy: retryPolicy
                )

                switch decision {
                case .doNotRetry:
                    return (data, response)

                case let .retry(delay):
                    AppLogger.network.warning(
                        "Retry attempt \(attempt)/\(retryPolicy.maxAttempts) after \(String(format: "%.1f", delay))s"
                    )
                    try await Task.sleep(for: .seconds(delay))

                case let .retryAfterRateLimit(delay):
                    AppLogger.network.warning(
                        "Rate limited, waiting \(String(format: "%.1f", delay))s before retry"
                    )
                    try await Task.sleep(for: .seconds(delay))
                }
            } catch let error as URLError {
                lastError = error

                // URLError.cancelled (-999) is not a real error, it's a cancellation
                // Treat it like CancellationError and rethrow as-is
                if error.code == .cancelled {
                    AppLogger.network.info("Request cancelled")
                    throw CancellationError()
                }

                if isTransientError(error), attempt < retryPolicy.maxAttempts {
                    let delay = retryPolicy.delay(for: attempt)
                    AppLogger.network.warning(
                        "Network error (\(error.code.rawValue)): retry \(attempt)/\(retryPolicy.maxAttempts) in \(String(format: "%.1f", delay))s"
                    )
                    try await Task.sleep(for: .seconds(delay))
                } else {
                    AppLogger.network.error(
                        "Network error (\(error.code.rawValue)) not retryable or max attempts reached"
                    )
                    // Convert URLError to GitServiceError for better error messages
                    throw convertURLError(error)
                }
            } catch {
                // CancellationError or other non-URLError - don't retry
                throw error
            }
        }

        // Convert last URLError to GitServiceError if present
        if let urlError = lastError as? URLError {
            throw convertURLError(urlError)
        }
        throw lastError ?? URLError(.unknown)
    }

    private func shouldRetry(
        response: URLResponse,
        attempt: Int,
        policy: RetryPolicy
    ) -> RetryDecision {
        guard let httpResponse = response as? HTTPURLResponse else {
            return .doNotRetry(reason: "Non-HTTP response")
        }

        let statusCode = httpResponse.statusCode

        // Success - no retry needed
        if (200 ..< 300).contains(statusCode) {
            return .doNotRetry(reason: "Success")
        }

        // Permanent failures - never retry
        if [400, 401, 403, 404, 422].contains(statusCode) {
            return .doNotRetry(reason: "Permanent failure: \(statusCode)")
        }

        // Max attempts reached
        if attempt >= policy.maxAttempts {
            return .doNotRetry(reason: "Max attempts reached")
        }

        // Rate limited - respect reset header
        if statusCode == 429 {
            if let resetDelay = extractRateLimitDelay(from: httpResponse) {
                return .retryAfterRateLimit(delay: min(resetDelay, policy.maxDelay))
            }
            return .retry(delay: policy.delay(for: attempt))
        }

        // Other retryable status codes
        if policy.retryableStatusCodes.contains(statusCode) {
            return .retry(delay: policy.delay(for: attempt))
        }

        return .doNotRetry(reason: "Non-retryable status: \(statusCode)")
    }

    private func isTransientError(_ error: URLError) -> Bool {
        let transientCodes: [URLError.Code] = [
            .timedOut,
            .cannotConnectToHost,
            .networkConnectionLost,
            .dnsLookupFailed,
            .notConnectedToInternet,
            .internationalRoamingOff,
            .callIsActive,
            .dataNotAllowed
        ]
        return transientCodes.contains(error.code)
    }

    private func extractRateLimitDelay(from response: HTTPURLResponse) -> TimeInterval? {
        let headers = response.allHeaderFields

        // Check for Retry-After header first (standard)
        if let retryAfter = headers["Retry-After"] as? String,
           let seconds = TimeInterval(retryAfter)
        {
            return seconds
        }

        // Fall back to X-RateLimit-Reset (GitHub, GitLab, Gitea)
        for (key, value) in headers {
            guard let keyString = key as? String,
                  let valueString = value as? String else { continue }

            let lowercaseKey = keyString.lowercased()
            if lowercaseKey.contains("ratelimit") || lowercaseKey.contains("rate-limit"),
               lowercaseKey.hasSuffix("reset")
            {
                if let resetTimestamp = TimeInterval(valueString) {
                    let now = Date().timeIntervalSince1970
                    let delay = resetTimestamp - now
                    return delay > 0 ? delay : 1.0
                }
            }
        }

        return nil
    }

    private func convertURLError(_ error: URLError) -> GitServiceError {
        switch error.code {
        case .notConnectedToInternet, .internationalRoamingOff, .dataNotAllowed, .callIsActive:
            .noInternet

        case .timedOut:
            .timeout

        case .cannotFindHost, .dnsLookupFailed:
            .dnsFailure

        case .cannotConnectToHost, .networkConnectionLost:
            .connectionFailed

        case .secureConnectionFailed, .serverCertificateHasBadDate, .serverCertificateUntrusted,
             .serverCertificateHasUnknownRoot, .serverCertificateNotYetValid, .clientCertificateRejected,
             .clientCertificateRequired:
            .sslError

        default:
            .networkError(error.localizedDescription)
        }
    }
}
