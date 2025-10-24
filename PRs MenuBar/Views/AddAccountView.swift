import SwiftUI

struct AddAccountView: View {
    let provider: GitProvider
    let isOnboarding: Bool
    let existingAccount: ProviderAccount?
    
    @State private var accountName = ""
    @State private var baseURL = ""
    @State private var token = ""
    @State private var errorMessage: String?
    @State private var isValidating = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(AppState.self) private var appState
    
    private let accountManager = AccountManager.shared
    
    init(provider: GitProvider, isOnboarding: Bool = false, existingAccount: ProviderAccount? = nil) {
        self.provider = provider
        self.isOnboarding = isOnboarding
        self.existingAccount = existingAccount
        
        // Initialize state
        _accountName = State(initialValue: existingAccount?.name ?? provider.displayName)
        _baseURL = State(initialValue: existingAccount?.baseURL ?? provider.defaultBaseURL)
    }
    
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
            
            // Account Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Account Name:")
                    .font(.subheadline)
                
                TextField("e.g., Work GitHub, Personal GitLab", text: $accountName)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isValidating)
            }
            
            // Base URL (for custom providers)
            if provider.requiresCustomURL {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server URL:")
                        .font(.subheadline)
                    
                    TextField("https://gitea.example.com/api/v1", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isValidating)
                    
                    Text("Enter the base API URL for your \(provider.displayName) instance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Token Section
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
            
            if isValidating {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Validating token...")
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
                    if isOnboarding {
                        dismissWindow(id: "onboarding")
                    }
                }
                .disabled(isValidating)
                
                Spacer()
                
                Button(existingAccount == nil ? "Add Account" : "Save") {
                    saveAccount()
                }
                .keyboardShortcut(.return)
                .disabled(!isFormValid || isValidating)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !accountName.isEmpty && !token.isEmpty && (!provider.requiresCustomURL || !baseURL.isEmpty)
    }
    
    private var tokenPlaceholder: String {
        switch provider {
        case .github:
            return "ghp_..."
        case .gitlab:
            return "glpat-..."
        case .gitea:
            return "Enter your token"
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
                    Text("• Required scope: read:repository")
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
            
            // Validate token
            let isValid = await validateToken()
            
            if isValid {
                // Create or update account
                let account: ProviderAccount
                if let existing = existingAccount {
                    account = ProviderAccount(
                        id: existing.id,
                        provider: provider,
                        name: accountName,
                        baseURL: baseURL.isEmpty ? provider.defaultBaseURL : baseURL,
                        isEnabled: existing.isEnabled
                    )
                    accountManager.updateAccount(account)
                } else {
                    account = ProviderAccount(
                        provider: provider,
                        name: accountName,
                        baseURL: baseURL.isEmpty ? provider.defaultBaseURL : baseURL
                    )
                    accountManager.addAccount(account)
                }
                
                // Save token
                do {
                    try accountManager.saveToken(token, for: account)
                    
                    // Mark onboarding as complete if this is onboarding
                    if isOnboarding {
                        accountManager.hasCompletedOnboarding = true
                        dismissWindow(id: "onboarding")
                    }
                    
                    dismiss()
                    
                    // Reload accounts and refresh
                    appState.reloadAccounts()
                    await appState.manualRefresh()
                } catch {
                    errorMessage = "Failed to save token: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Invalid token or server URL. Please check and try again."
            }
        }
    }
    
    private func validateToken() async -> Bool {
        let validationURL: String
        let authHeader: String
        
        switch provider {
        case .github:
            validationURL = "https://api.github.com/user"
            authHeader = "Bearer \(token)"
        case .gitlab:
            let base = baseURL.isEmpty ? provider.defaultBaseURL : baseURL
            validationURL = "\(base)/user"
            authHeader = "Bearer \(token)"
        case .gitea:
            if baseURL.isEmpty { return false }
            validationURL = "\(baseURL)/user"
            authHeader = "token \(token)"
        }
        
        guard let url = URL(string: validationURL) else { return false }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

#Preview {
    AddAccountView(provider: .github)
        .environment(AppState.shared)
}
