import Foundation
import OSLog

/// Manages provider accounts configuration
@MainActor
final class AccountManager {
    static let shared = AccountManager()

    private let accountsKey = "providerAccounts"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let hasMigratedLegacyAccountKey = "hasMigratedLegacyAccount"

    private init() {}

    // MARK: - Public API
    /// Get all configured accounts
    func getAccounts() -> [ProviderAccount] {
        guard let data = UserDefaults.standard.data(forKey: accountsKey),
              let accounts = try? JSONDecoder().decode([ProviderAccount].self, from: data) else
        {
            AppLogger.auth.debug("No accounts found, attempting legacy migration")
            return migrateLegacyAccount()
        }
        AppLogger.auth.debug("Retrieved \(accounts.count) accounts")
        return accounts
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

    /// Remove an account
    func removeAccount(_ account: ProviderAccount) {
        var accounts = getAccounts()
        accounts.removeAll { $0.id == account.id }
        saveAccounts(accounts)
        AppLogger.auth.info("Removed account: \(account.displayName)")

        do {
            try KeychainManager.deleteToken(for: account.keychainAccount)
        } catch {
            AppLogger.error.error("Failed to delete token for removed account: \(error.localizedDescription)")
        }
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

    // MARK: - Migration
    /// Migrate legacy GitHub token to new account system
    private func migrateLegacyAccount() -> [ProviderAccount] {
        guard !UserDefaults.standard.bool(forKey: hasMigratedLegacyAccountKey) else {
            AppLogger.auth.debug("Legacy account already migrated")
            return []
        }

        if let legacyToken = KeychainManager.getToken() {
            AppLogger.auth.info("Migrating legacy GitHub token to new account system")

            let account = ProviderAccount(
                provider: .github,
                name: "GitHub",
                baseURL: "https://api.github.com"
            )

            do {
                try KeychainManager.saveToken(legacyToken, for: account.keychainAccount)
                saveAccounts([account])
                hasCompletedOnboarding = true
                UserDefaults.standard.set(true, forKey: hasMigratedLegacyAccountKey)
                AppLogger.auth.info("Legacy account migration successful")
                return [account]
            } catch {
                AppLogger.error.error("Legacy account migration failed: \(error.localizedDescription)")
            }
        }

        UserDefaults.standard.set(true, forKey: hasMigratedLegacyAccountKey)
        AppLogger.auth.debug("No legacy account to migrate")
        return []
    }
}
