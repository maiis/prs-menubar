import Foundation
import Testing
@testable import PRs_MenuBar

/// Covers `AccountManager`'s corrupted-data recovery: rather than returning `[]` (which the next
/// save would overwrite, losing all accounts), it backs up the raw bytes once for manual recovery.
@Suite(.serialized)
@MainActor
struct AccountManagerTests {

    // Storage keys are private in AccountManager; reference the stable string keys directly.
    private let accountsKey = "providerAccounts"
    private let backupKey = "providerAccountsCorruptedBackup"

    init() {
        cleanup()
    }

    private func cleanup() {
        UserDefaults.standard.removeObject(forKey: accountsKey)
        UserDefaults.standard.removeObject(forKey: backupKey)
    }

    @Test func corruptedAccountsAreBackedUpOnceAndReturnEmpty() {
        let garbage = Data([0x00, 0x01, 0x02, 0xFF, 0xFE])
        UserDefaults.standard.set(garbage, forKey: accountsKey)

        let manager = AccountManager.shared
        #expect(manager.getAccounts().isEmpty)
        #expect(UserDefaults.standard.data(forKey: backupKey) == garbage)

        // A later read with DIFFERENT corrupted bytes must not clobber the existing backup.
        UserDefaults.standard.set(Data([0x10, 0x11]), forKey: accountsKey)
        _ = manager.getAccounts()
        #expect(UserDefaults.standard.data(forKey: backupKey) == garbage)

        cleanup()
    }

    @Test func validAccountsRoundTripWithoutBackup() {
        let account = ProviderAccount(provider: .github, name: "Test", baseURL: "https://api.github.com")
        AccountManager.shared.saveAccounts([account])

        let loaded = AccountManager.shared.getAccounts()
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == account.id)
        #expect(UserDefaults.standard.data(forKey: backupKey) == nil)

        cleanup()
    }
}
