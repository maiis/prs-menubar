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

    // MARK: - Reordering
    /// Four accounts named A/B/C/D, so a reorder can be asserted as a name string.
    private func makeAccounts() -> [ProviderAccount] {
        ["A", "B", "C", "D"].map {
            ProviderAccount(provider: .github, name: $0, baseURL: "https://api.github.com")
        }
    }

    private func order(_ accounts: [ProviderAccount]) -> String {
        accounts.map(\.name).joined()
    }

    @Test func reorderingMovesAnAccountBeforeAnother() {
        let accounts = makeAccounts()

        // Drag D in front of B.
        let moved = AccountManager.reordering(accounts, moving: [accounts[3].id], before: accounts[1].id)
        #expect(order(moved) == "ADBC")

        // Drag A in front of C: removing A first must not shift the destination lookup.
        let forward = AccountManager.reordering(accounts, moving: [accounts[0].id], before: accounts[2].id)
        #expect(order(forward) == "BACD")
    }

    @Test func reorderingToTheEndAndWithMultipleSources() {
        let accounts = makeAccounts()

        let toEnd = AccountManager.reordering(accounts, moving: [accounts[0].id], before: nil)
        #expect(order(toEnd) == "BCDA")

        // Multiple rows keep their existing relative order regardless of the order dragged.
        let multiple = AccountManager.reordering(
            accounts,
            moving: [accounts[2].id, accounts[0].id],
            before: accounts[1].id
        )
        #expect(order(multiple) == "ACBD")
    }

    @Test func reorderingIsANoOpForUnknownOrEmptySources() {
        let accounts = makeAccounts()
        let stranger = ProviderAccount(provider: .gitlab, name: "Z", baseURL: "https://gitlab.com/api/v4")

        #expect(order(AccountManager.reordering(accounts, moving: [], before: accounts[1].id)) == "ABCD")
        #expect(order(AccountManager.reordering(accounts, moving: [stranger.id], before: nil)) == "ABCD")

        // An unknown destination falls back to the end rather than dropping the account.
        let unknownDestination = AccountManager.reordering(accounts, moving: [accounts[0].id], before: stranger.id)
        #expect(order(unknownDestination) == "BCDA")
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
