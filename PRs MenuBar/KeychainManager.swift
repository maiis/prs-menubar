import Foundation
import OSLog
import Security

enum KeychainManager {

    // MARK: - Constants
    private static let service = "me.maiis.prsmenubar"

    // MARK: - Public API
    /// Save token for a specific account (uses atomic update pattern)
    static func saveToken(_ token: String, for account: String) throws {
        AppLogger.keychain.debug("Saving token for account: \(account)")

        guard let data = token.data(using: .utf8) else {
            AppLogger.error.error("Keychain: Invalid token data for account: \(account)")
            throw KeychainError.invalidData
        }

        let searchQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        // Try to update existing item first
        var status = SecItemUpdate(searchQuery as CFDictionary, updateAttributes as CFDictionary)

        if status == errSecItemNotFound {
            // Item doesn't exist, add it
            var addQuery = searchQuery
            addQuery[kSecValueData as String] = data
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            AppLogger.error.error("Keychain: Failed to save token for account \(account), status: \(status)")
            throw KeychainError.unableToSave(status)
        }

        AppLogger.keychain.info("Token saved successfully for account: \(account)")
    }

    /// Get token for a specific account
    static func getToken(for account: String) -> String? {
        AppLogger.keychain.debug("Retrieving token for account: \(account)")

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
            if status != errSecItemNotFound {
                AppLogger.error.error("Keychain: Failed to retrieve token for account \(account), status: \(status)")
            } else {
                AppLogger.keychain.debug("Keychain: No token found for account: \(account)")
            }
            return nil
        }

        AppLogger.keychain.debug("Token retrieved successfully for account: \(account)")
        return token
    }

    /// Delete token for a specific account
    static func deleteToken(for account: String) throws {
        AppLogger.keychain.debug("Deleting token for account: \(account)")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            AppLogger.error.error("Keychain: Failed to delete token for account \(account), status: \(status)")
            throw KeychainError.unableToDelete(status)
        }

        AppLogger.keychain.info("Token deleted successfully for account: \(account)")
    }
}
