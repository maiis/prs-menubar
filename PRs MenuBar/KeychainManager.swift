import Foundation
import Security

enum KeychainManager {
  private static let service = "me.maiis.prsmenubar"
  private static let account = "github-token"

  static func saveToken(_ token: String) throws {
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

  static func getToken() -> String? {
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

  static func deleteToken() throws {
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
}

enum KeychainError: LocalizedError {
  case invalidData
  case unableToSave(OSStatus)
  case unableToDelete(OSStatus)

  var errorDescription: String? {
    switch self {
    case .invalidData:
      "Invalid token data"
    case let .unableToSave(status):
      "Unable to save token to Keychain (status: \(status))"
    case let .unableToDelete(status):
      "Unable to delete token from Keychain (status: \(status))"
    }
  }
}
