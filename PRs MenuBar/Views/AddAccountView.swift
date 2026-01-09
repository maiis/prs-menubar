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
                    .textFieldStyle(.roundedBorder)
                    .disabled(isValidating)
            }

            if provider.requiresCustomURL {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server URL:")
                        .font(.subheadline)

                    TextField("https://gitea.example.com/api/v1", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
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

                    if !provider.tokenSetupURL.isEmpty {
                        Link("Create Token →", destination: URL(string: provider.tokenSetupURL)!)
                            .font(.caption)
                    }
                }

                SecureField(tokenPlaceholder, text: $token)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveAccount() }
                    .disabled(isValidating)

                tokenRequirementsText
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

    private var tokenRequirementsText: some View {
        Group {
            switch provider {
            case .github:
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Use a Classic Personal Access Token")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("• Required scope: repo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .gitlab:
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Required scope: read_api")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .gitea:
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Required scopes: read:issue, read:repository, and read:user")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Actions
    private func saveAccount() {
        guard isFormValid else { return }

        isValidating = true
        errorMessage = nil

        Task { @MainActor in
            defer { isValidating = false }

            let isValid = await validateToken()

            if isValid {
                isSaving = true
                defer { isSaving = false }

                // Create account object (not saved yet)
                let account = if let existing = existingAccount {
                    ProviderAccount(
                        id: existing.id,
                        provider: provider,
                        name: accountName,
                        baseURL: baseURL.isEmpty ? provider.defaultBaseURL : baseURL,
                        isEnabled: existing.isEnabled
                    )
                } else {
                    ProviderAccount(
                        provider: provider,
                        name: accountName,
                        baseURL: baseURL.isEmpty ? provider.defaultBaseURL : baseURL
                    )
                }

                do {
                    // Save token FIRST - if this fails, account won't be saved
                    try accountManager.saveToken(token, for: account)

                    // Only save account after token is successfully saved
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
            } else if errorMessage == nil {
                // Only set generic message if validateToken() didn't set a specific one
                errorMessage = "Invalid token or server URL. Please check and try again."
            }
        }
    }

    private func validateToken() async -> Bool {
        let validationURL: String
        let authHeader: String
        let effectiveBaseURL: String

        switch provider {
        case .github:
            effectiveBaseURL = "https://api.github.com"
            validationURL = "\(effectiveBaseURL)/user"
            authHeader = "Bearer \(token)"
        case .gitlab:
            effectiveBaseURL = baseURL.isEmpty ? provider.defaultBaseURL : baseURL
            validationURL = "\(effectiveBaseURL)/user"
            authHeader = "Bearer \(token)"
        case .gitea:
            if baseURL.isEmpty { return false }
            effectiveBaseURL = baseURL
            validationURL = "\(effectiveBaseURL)/user"
            authHeader = "token \(token)"
        }

        guard let url = URL(string: validationURL),
              url.scheme == "https" || url.scheme == "http" else
        {
            return false
        }

        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request, retryPolicy: .default)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid server response"
                return false
            }

            if httpResponse.statusCode == 401 {
                errorMessage = "Invalid token. Please check your access token."
                return false
            }

            guard httpResponse.statusCode == 200 else {
                errorMessage = "Server error (HTTP \(httpResponse.statusCode))"
                return false
            }

            return await validatePermissions(effectiveBaseURL: effectiveBaseURL, authHeader: authHeader, userData: data)
        } catch let urlError as URLError {
            errorMessage = "Network error: \(urlError.localizedDescription)"
            return false
        } catch {
            errorMessage = "Validation failed: \(error.localizedDescription)"
            return false
        }
    }

    private func validatePermissions(effectiveBaseURL: String, authHeader: String, userData: Data) async -> Bool {
        switch provider {
        case .github:
            guard let url = URL(string: "https://api.github.com/graphql") else { return false }
            let testQuery = """
            {
              viewer {
                login
              }
            }
            """
            let graphqlBody: [String: Any] = ["query": testQuery]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: graphqlBody) else { return false }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 10

            do {
                let (_, response) = try await URLSession.shared.data(for: request, retryPolicy: .default)
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                if statusCode == 200 {
                    return true
                }
                errorMessage = "Missing required 'repo' scope. Please create a Classic Personal Access Token with 'repo' scope."
                return false
            } catch let urlError as URLError {
                errorMessage = "Network error: \(urlError.localizedDescription)"
                return false
            } catch {
                errorMessage = "Permission validation failed: \(error.localizedDescription)"
                return false
            }

        case .gitlab:
            guard let userId = try? JSONSerialization.jsonObject(with: userData) as? [String: Any],
                  let userIdInt = userId["id"] as? Int,
                  let url =
                  URL(
                      string: "\(effectiveBaseURL)/merge_requests?scope=all&state=opened&reviewer_id=\(userIdInt)&per_page=1"
                  ) else
            {
                return false
            }

            var request = URLRequest(url: url)
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10

            do {
                let (_, response) = try await URLSession.shared.data(for: request, retryPolicy: .default)
                if (response as? HTTPURLResponse)?.statusCode == 403 {
                    errorMessage = "Missing required 'read_api' scope"
                    return false
                }
                return (response as? HTTPURLResponse)?.statusCode == 200
            } catch let urlError as URLError {
                errorMessage = "Network error: \(urlError.localizedDescription)"
                return false
            } catch {
                errorMessage = "Permission validation failed: \(error.localizedDescription)"
                return false
            }

        case .gitea:
            guard let url = URL(string: "\(effectiveBaseURL)/user/repos?page=1&limit=1") else {
                return false
            }

            var request = URLRequest(url: url)
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10

            do {
                let (_, response) = try await URLSession.shared.data(for: request, retryPolicy: .default)
                if (response as? HTTPURLResponse)?.statusCode == 403 {
                    errorMessage = "Missing required 'read:repository' scope"
                    return false
                }
                return (response as? HTTPURLResponse)?.statusCode == 200
            } catch let urlError as URLError {
                errorMessage = "Network error: \(urlError.localizedDescription)"
                return false
            } catch {
                errorMessage = "Permission validation failed: \(error.localizedDescription)"
                return false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AddAccountView(provider: .github)
        .environment(AppState.shared)
}
