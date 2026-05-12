import Foundation

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
