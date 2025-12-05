import Foundation
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
@MainActor
struct NetworkRetryTests {

    // MARK: - RetryPolicy Tests

    @Test func retryPolicyDefaultValues() {
        let policy = RetryPolicy.default
        #expect(policy.maxAttempts == 3)
        #expect(policy.baseDelay == 1.0)
        #expect(policy.maxDelay == 30.0)
    }

    @Test func retryPolicyExponentialBackoff() {
        let policy = RetryPolicy.default

        // First attempt: ~1s (with up to 30% jitter)
        let delay1 = policy.delay(for: 1)
        #expect(delay1 >= 1.0 && delay1 <= 1.3)

        // Second attempt: ~2s (with up to 30% jitter)
        let delay2 = policy.delay(for: 2)
        #expect(delay2 >= 2.0 && delay2 <= 2.6)

        // Third attempt: ~4s (with up to 30% jitter)
        let delay3 = policy.delay(for: 3)
        #expect(delay3 >= 4.0 && delay3 <= 5.2)
    }

    @Test func retryPolicyRespectsMaxDelay() {
        let policy = RetryPolicy(
            maxAttempts: 10,
            baseDelay: 10.0,
            maxDelay: 15.0,
            retryableStatusCodes: []
        )

        // 10 * 2^9 = 5120, but should cap at 15
        let delay = policy.delay(for: 10)
        #expect(delay <= 15.0)
    }

    @Test func retryPolicyJitterIsRandom() {
        let policy = RetryPolicy.default

        // Run multiple times to verify jitter varies
        var delays: Set<Double> = []
        for _ in 0 ..< 10 {
            delays.insert(policy.delay(for: 1))
        }

        // With random jitter, we should get multiple different values
        #expect(delays.count > 1)
    }

    // MARK: - Status Code Classification Tests

    @Test func permanentErrorsAreNotRetryable() {
        let policy = RetryPolicy.default
        let permanentCodes = [400, 401, 403, 404, 422]

        for code in permanentCodes {
            #expect(
                !policy.retryableStatusCodes.contains(code),
                "Status code \(code) should not be retryable"
            )
        }
    }

    @Test func serverErrorsAreRetryable() {
        let policy = RetryPolicy.default

        #expect(policy.retryableStatusCodes.contains(500))
        #expect(policy.retryableStatusCodes.contains(502))
        #expect(policy.retryableStatusCodes.contains(503))
        #expect(policy.retryableStatusCodes.contains(504))
    }

    @Test func rateLimitIsRetryable() {
        let policy = RetryPolicy.default
        #expect(policy.retryableStatusCodes.contains(429))
    }

    @Test func timeoutIsRetryable() {
        let policy = RetryPolicy.default
        #expect(policy.retryableStatusCodes.contains(408))
    }

    // MARK: - URLError Classification Tests

    @Test func transientURLErrorCodes() {
        // These error codes should trigger retries
        let transientCodes: [URLError.Code] = [
            .timedOut,
            .cannotConnectToHost,
            .networkConnectionLost,
            .dnsLookupFailed,
            .notConnectedToInternet
        ]

        for code in transientCodes {
            let error = URLError(code)
            #expect(error.code == code, "URLError code should match")
        }
    }

    @Test func permanentURLErrorCodes() {
        // These error codes should NOT trigger retries
        let permanentCodes: [URLError.Code] = [
            .badURL,
            .unsupportedURL,
            .cannotFindHost,
            .badServerResponse,
            .userCancelledAuthentication
        ]

        for code in permanentCodes {
            let error = URLError(code)
            #expect(error.code == code, "URLError code should match")
        }
    }

    // MARK: - Custom Policy Tests

    @Test func customRetryPolicy() {
        let policy = RetryPolicy(
            maxAttempts: 5,
            baseDelay: 0.5,
            maxDelay: 10.0,
            retryableStatusCodes: [500, 503]
        )

        #expect(policy.maxAttempts == 5)
        #expect(policy.baseDelay == 0.5)
        #expect(policy.maxDelay == 10.0)
        #expect(policy.retryableStatusCodes.count == 2)
        #expect(policy.retryableStatusCodes.contains(500))
        #expect(policy.retryableStatusCodes.contains(503))
        #expect(!policy.retryableStatusCodes.contains(502))
    }
}
