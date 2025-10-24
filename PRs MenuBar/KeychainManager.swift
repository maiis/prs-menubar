import Foundation
import Security

enum KeychainManager {

    // MARK: - Constants
    private static let service = "me.maiis.prsmenubar"
    private static let legacyAccount = "github-token"

    // MARK: - Actions
    
    /// Save token for a specific account
    static func saveToken(_ token: String, for account: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }
    }
    
    /// Get token for a specific account
    static func getToken(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else
        {
            return nil
        }

        return token
    }
    
    /// Delete token for a specific account
    static func deleteToken(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status)
        }
    }
    
    // MARK: - Legacy Support (for backward compatibility)
    
    /// Save token using legacy account name (for backward compatibility)
    static func saveToken(_ token: String) throws {
        try saveToken(token, for: legacyAccount)
    }

    /// Get token using legacy account name (for backward compatibility)
    static func getToken() -> String? {
        getToken(for: legacyAccount)
    }

    /// Delete token using legacy account name (for backward compatibility)
    static func deleteToken() throws {
        try deleteToken(for: legacyAccount)
    }
}
