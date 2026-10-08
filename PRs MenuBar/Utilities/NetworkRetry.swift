import Foundation
import OSLog

// MARK: - RetryPolicy Configuration

/// Per-request timeout for provider API calls. Generous enough for a slow-but-alive
/// self-hosted instance, while ensuring an unreachable host fails in seconds rather than
/// stacking full-length timeouts across retries.
let defaultRequestTimeout: TimeInterval = 15

/// Honestly identifies this app to provider APIs, rather than sending no header at all.
let defaultUserAgent: String = {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    return "PRsMenuBar/\(version) (me.maiis.prsmenubar)"
}()

struct RetryPolicy {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let retryableStatusCodes: Set<Int>

    static let `default` = RetryPolicy(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 30.0,
        retryableStatusCodes: [408, 429, 500, 502, 503, 504]
    )

    nonisolated func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))
        let jitter = Double.random(in: 0 ... 0.3) * exponentialDelay
        return min(exponentialDelay + jitter, maxDelay)
    }
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

                guard let delay = retryDelay(response: response, attempt: attempt, policy: retryPolicy) else {
                    return (data, response)
                }
                AppLogger.network.warning(
                    "Retry attempt \(attempt)/\(retryPolicy.maxAttempts) after \(String(format: "%.1f", delay))s"
                )
                try await Task.sleep(for: .seconds(delay))
            } catch let error as URLError {
                lastError = error

                // URLError.cancelled (-999) is not a real error, it's a cancellation
                // Treat it like CancellationError and rethrow as-is
                if error.code == .cancelled {
                    AppLogger.network.info("Request cancelled")
                    throw CancellationError()
                }

                // A timeout already consumed the full request timeout, so retrying it
                // in-request just waits the same interval again — the main cause of a long
                // spinner when one account is unreachable. Fail fast here and let AppState's
                // transient retry re-attempt the whole refresh instead.
                if isTransientError(error), error.code != .timedOut, attempt < retryPolicy.maxAttempts {
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

    /// Delay before retrying this response, or nil to return it as-is. A 429 waits for the
    /// provider's rate-limit reset when it sends one.
    private func retryDelay(response: URLResponse, attempt: Int, policy: RetryPolicy) -> TimeInterval? {
        guard let httpResponse = response as? HTTPURLResponse,
              attempt < policy.maxAttempts,
              policy.retryableStatusCodes.contains(httpResponse.statusCode) else { return nil }
        if httpResponse.statusCode == 429, let resetDelay = rateLimitDelay(httpResponse) {
            return min(resetDelay, policy.maxDelay)
        }
        return policy.delay(for: attempt)
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

    private func rateLimitDelay(_ response: HTTPURLResponse) -> TimeInterval? {
        if let retryAfter = response.value(forHTTPHeaderField: "Retry-After"),
           let seconds = TimeInterval(retryAfter)
        {
            return seconds
        }
        return response.rateLimitInfo.reset.map { max($0.timeIntervalSinceNow, 1.0) }
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

extension HTTPURLResponse {
    /// Rate-limit headers in any provider's spelling (X-RateLimit-*, X-Rate-Limit-*, RateLimit-*).
    var rateLimitInfo: (remaining: Int?, limit: Int?, reset: Date?) {
        var remaining: Int?
        var limit: Int?
        var reset: Date?
        for (key, value) in allHeaderFields {
            guard let key = (key as? String)?.lowercased(), let value = value as? String,
                  key.contains("ratelimit") || key.contains("rate-limit") else { continue }
            if key.hasSuffix("remaining") {
                remaining = Int(value)
            } else if key.hasSuffix("reset") {
                reset = TimeInterval(value).map { Date(timeIntervalSince1970: $0) }
            } else if key.hasSuffix("limit"), !key.hasSuffix("ratelimit"), !key.hasSuffix("rate-limit") {
                limit = Int(value)
            }
        }
        return (remaining, limit, reset)
    }
}
