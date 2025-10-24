import Foundation

/// Represents a configured account for a Git service provider
struct ProviderAccount: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let provider: GitProvider
    let name: String // User-provided name for this account
    let baseURL: String // API base URL
    let isEnabled: Bool
    
    init(
        id: UUID = UUID(),
        provider: GitProvider,
        name: String,
        baseURL: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.provider = provider
        self.name = name
        self.baseURL = baseURL ?? provider.defaultBaseURL
        self.isEnabled = isEnabled
    }
    
    /// Keychain account identifier for storing the token
    var keychainAccount: String {
        "token-\(id.uuidString)"
    }
    
    var displayName: String {
        "\(name) (\(provider.displayName))"
    }
}
