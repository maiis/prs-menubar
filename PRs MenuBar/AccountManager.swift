import Foundation
import OSLog

/// Manages provider accounts configuration
@MainActor
final class AccountManager {
    static let shared = AccountManager()

    private let accountsKey = "providerAccounts"
    private let corruptedAccountsBackupKey = "providerAccountsCorruptedBackup"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    private init() {}

    // MARK: - Public API
    /// Get all configured accounts
    func getAccounts() -> [ProviderAccount] {
        guard let data = UserDefaults.standard.data(forKey: accountsKey) else {
            AppLogger.auth.debug("No accounts data found")
            return []
        }

        do {
            let accounts = try JSONDecoder().decode([ProviderAccount].self, from: data)
            AppLogger.auth.debug("Retrieved \(accounts.count) accounts")
            return accounts
        } catch {
            // Decoding failed — likely a schema change or corruption. Returning `[]` here would
            // cause the next `addAccount`/`saveAccounts` call to overwrite the user's data with a
            // single new entry, silently losing all existing accounts. Stash the raw bytes under a
            // backup key (once, so we don't keep overwriting a known-good backup with the same
            // corrupted bytes) and log at fault level so the user can recover manually.
            AppLogger.error
                .fault("Failed to decode accounts (\(data.count) bytes): \(error.localizedDescription)")
            if UserDefaults.standard.data(forKey: corruptedAccountsBackupKey) == nil {
                UserDefaults.standard.set(data, forKey: corruptedAccountsBackupKey)
                AppLogger.error.fault("Corrupted accounts data backed up under \(self.corruptedAccountsBackupKey)")
            }
            return []
        }
    }

    /// Save accounts
    func saveAccounts(_ accounts: [ProviderAccount]) {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: accountsKey)
            AppLogger.auth.info("Saved \(accounts.count) accounts")
        } else {
            AppLogger.error.error("Failed to encode accounts for saving")
        }
    }

    /// Add a new account
    func addAccount(_ account: ProviderAccount) {
        var accounts = getAccounts()
        accounts.append(account)
        saveAccounts(accounts)
        AppLogger.auth.info("Added account: \(account.displayName)")
    }

    /// Update an existing account
    func updateAccount(_ account: ProviderAccount) {
        var accounts = getAccounts()
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts(accounts)
            AppLogger.auth.info("Updated account: \(account.displayName)")
        } else {
            AppLogger.error.error("Failed to update account: account not found")
        }
    }

    /// Remove an account (deletes token first to ensure atomicity)
    func removeAccount(_ account: ProviderAccount) throws {
        // Delete token first - if this fails, account stays intact
        try KeychainManager.deleteToken(for: account.keychainAccount)

        var accounts = getAccounts()
        accounts.removeAll { $0.id == account.id }
        saveAccounts(accounts)
        AppLogger.auth.info("Removed account: \(account.displayName)")
    }

    /// Get token for an account
    func getToken(for account: ProviderAccount) -> String? {
        KeychainManager.getToken(for: account.keychainAccount)
    }

    /// Save token for an account
    func saveToken(_ token: String, for account: ProviderAccount) throws {
        try KeychainManager.saveToken(token, for: account.keychainAccount)
    }

    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey) }
    }
}
