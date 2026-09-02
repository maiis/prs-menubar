import SwiftUI

/// Dedicated URLSession + on-disk cache for author avatars.
///
/// A menu bar app re-renders its PR list on every refresh, so without a cache the same
/// handful of avatars would be re-downloaded repeatedly. macOS 27's `AsyncImage` honors
/// HTTP cache headers by default, and `asyncImageURLSession(_:)` lets us point it at a
/// bounded cache of our own instead of the shared session.
enum AvatarImageSession {
    static let shared: URLSession = {
        let cache = URLCache(
            memoryCapacity: 8 * 1024 * 1024,
            diskCapacity: 64 * 1024 * 1024,
            directory: nil
        )
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        // No requestCachePolicy override: the default revalidates per the response's
        // Cache-Control, so a changed avatar at a stable URL is picked up.
        return URLSession(configuration: configuration)
    }()
}

extension View {
    /// Routes `AsyncImage` requests in this subtree through the dedicated avatar cache
    /// on macOS 27+. No-op on earlier systems, which fall back to the shared session.
    @ViewBuilder
    func avatarImageCache() -> some View {
        if #available(macOS 27.0, *) {
            asyncImageURLSession(AvatarImageSession.shared)
        } else {
            self
        }
    }
}
