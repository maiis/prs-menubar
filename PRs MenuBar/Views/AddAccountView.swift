import SwiftUI

struct AddAccountView: View {

    // MARK: - Properties
    let provider: GitProvider
    let isOnboarding: Bool
    let existingAccount: ProviderAccount?

    // MARK: - State
    @State private var accountName = ""
    @State private var baseURL = ""
    @State private var token = ""
    @State private var errorMessage: String?
    @State private var isValidating = false
    @State private var isSaving = false

    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    // MARK: - Dependencies
    private let accountManager = AccountManager.shared

    // MARK: - Init
    init(provider: GitProvider, isOnboarding: Bool = false, existingAccount: ProviderAccount? = nil) {
        self.provider = provider
        self.isOnboarding = isOnboarding
        self.existingAccount = existingAccount

        _accountName = State(initialValue: existingAccount?.name ?? provider.displayName)
        _baseURL = State(initialValue: existingAccount?.baseURL ?? provider.defaultBaseURL)
    }

    // MARK: - UI
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(existingAccount == nil ? "Add \(provider.displayName) Account" : "Edit Account")
                    .font(.headline)

                Text("Configure your \(provider.displayName) account to track pull requests.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("Account Name:")
                    .font(.subheadline)

                TextField("e.g., Work GitHub, Personal GitLab", text: $accountName)
                    .roundedBorderTextField()
                    .disabled(isValidating)
            }

            if provider.requiresCustomURL {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server URL:")
                        .font(.subheadline)

                    TextField("https://gitea.example.com/api/v1", text: $baseURL)
                        .roundedBorderTextField()
                        .disabled(isValidating)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enter the base API URL for your \(provider.displayName) instance")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Requires: Gitea 1.22.0+ or Forgejo 10.0+")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Access Token:")
                        .font(.subheadline)

                    Spacer()

                    if let setupURL = URL(string: provider.tokenSetupURL) {
                        Link("Create Token →", destination: setupURL)
                            .font(.caption)
                    }
                }

                SecureField(tokenPlaceholder, text: $token)
                    .roundedBorderTextField()
                    .onSubmit { saveAccount() }
                    .disabled(isValidating)

                tokenRequirementsText

                Label(
                    "Stored in macOS Keychain. Only sent to \(provider.displayName) to fetch your pull requests.",
                    systemImage: "lock.fill"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if isValidating || isSaving {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(isSaving ? "Saving account..." : "Validating token...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .disabled(isValidating || isSaving)

                Spacer()

                Button(existingAccount == nil ? "Add Account" : "Save") {
                    saveAccount()
                }
                .keyboardShortcut(.return)
                .disabled(!isFormValid || isValidating || isSaving)
            }
        }
        .padding(24)
        .frame(width: 500)
        .presentationBackground(.regularMaterial)
    }

    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (!provider.requiresCustomURL || !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var tokenPlaceholder: String {
        switch provider {
        case .github:
            "ghp_..."
        case .gitlab:
            "glpat-..."
        case .gitea:
            "Enter your token"
        }
    }

    private var requiredScopes: String {
        switch provider {
        case .github: "repo"
        case .gitlab: "read_api"
        case .gitea: "read:issue, read:repository, and read:user"
        }
    }

    private var tokenRequirementsText: some View {
        VStack(alignment: .leading, spacing: 4) {
            if provider == .github {
                Text("• Use a Classic Personal Access Token")
            }
            Text("• Required scopes: \(requiredScopes)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    // MARK: - Actions
    private func saveAccount() {
        guard isFormValid else { return }

        let account = ProviderAccount(
            id: existingAccount?.id ?? UUID(),
            provider: provider,
            name: accountName,
            baseURL: baseURL.isEmpty ? provider.defaultBaseURL : baseURL,
            isEnabled: existingAccount?.isEnabled ?? true
        )
        guard let url = URL(string: account.baseURL), url.scheme == "https" || url.scheme == "http" else {
            errorMessage = "The server URL must start with https:// or http://."
            return
        }

        isValidating = true
        errorMessage = nil

        Task {
            defer { isValidating = false }

            // Validate by doing the real fetch, so a token passes only if it can do what the app needs.
            do {
                _ = try await account.makeService(token: token)
                    .fetchReviewRequestedPRs(filterDrafts: false, excludedLabels: [])
            } catch {
                let error = AppState.coerce(error)
                errorMessage = switch error {
                case .forbidden, .insufficientPermissions:
                    "\(error.localizedDescription) Required scopes: \(requiredScopes)."
                default:
                    error.localizedDescription
                }
                return
            }

            isSaving = true
            defer { isSaving = false }

            do {
                // Save token FIRST - if this fails, account won't be saved
                try accountManager.saveToken(token, for: account)

                if existingAccount != nil {
                    accountManager.updateAccount(account)
                } else {
                    accountManager.addAccount(account)
                }

                if isOnboarding {
                    accountManager.hasCompletedOnboarding = true
                }

                // reloadAccounts() already triggers a refresh internally
                appState.reloadAccounts()

                dismiss()
            } catch {
                errorMessage = "Failed to save token: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AddAccountView(provider: .github)
        .environment(AppState.shared)
}
