import Foundation

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
            return migrateLegacyAccount()
        }
        return accounts
    }

    /// Save accounts
    func saveAccounts(_ accounts: [ProviderAccount]) {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
    }

    /// Add a new account
    func addAccount(_ account: ProviderAccount) {
        var accounts = getAccounts()
        accounts.append(account)
        saveAccounts(accounts)
    }

    /// Update an existing account
    func updateAccount(_ account: ProviderAccount) {
        var accounts = getAccounts()
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts(accounts)
        }
    }

    /// Remove an account
    func removeAccount(_ account: ProviderAccount) {
        var accounts = getAccounts()
        accounts.removeAll { $0.id == account.id }
        saveAccounts(accounts)

        try? KeychainManager.deleteToken(for: account.keychainAccount)
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
            return []
        }

        if let legacyToken = KeychainManager.getToken() {
            let account = ProviderAccount(
                provider: .github,
                name: "GitHub",
                baseURL: "https://api.github.com"
            )

            try? KeychainManager.saveToken(legacyToken, for: account.keychainAccount)
            saveAccounts([account])
            hasCompletedOnboarding = true
            UserDefaults.standard.set(true, forKey: hasMigratedLegacyAccountKey)

            return [account]
        }

        UserDefaults.standard.set(true, forKey: hasMigratedLegacyAccountKey)
        return []
    }
}
