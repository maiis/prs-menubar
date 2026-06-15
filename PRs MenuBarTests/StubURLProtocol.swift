import Foundation
@testable import PRs_MenuBar

/// A `URLProtocol` that intercepts requests made through `URLSession.shared` (which the services
/// use) and serves a stubbed response, so the decode paths can be exercised end-to-end with
/// fixture JSON and no network. Use only inside `.serialized` suites — the responder is global.
final class StubURLProtocol: URLProtocol {
    struct Stub {
        let statusCode: Int
        let headers: [String: String]
        let body: Data

        init(statusCode: Int = 200, headers: [String: String] = [:], json: String) {
            self.statusCode = statusCode
            self.headers = headers
            body = Data(json.utf8)
        }
    }

    /// Maps a request to a stubbed response. Throwing simulates a transport-level failure.
    private nonisolated(unsafe) static var _responder: (@Sendable (URLRequest) throws -> Stub)?
    private static let lock = NSLock()

    static var responder: (@Sendable (URLRequest) throws -> Stub)? {
        get { lock.withLock { _responder } }
        set { lock.withLock { _responder = newValue } }
    }

    static func register() {
        URLProtocol.registerClass(StubURLProtocol.self)
    }

    static func unregister() {
        URLProtocol.unregisterClass(StubURLProtocol.self)
        responder = nil
    }

    // MARK: - URLProtocol

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let responder = Self.responder, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let stub = try responder(request)
            let response = HTTPURLResponse(
                url: url,
                statusCode: stub.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: stub.headers
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stub.body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
