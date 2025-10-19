import SwiftUI

struct TokenPromptView: View {
    @State private var token = ""
    @State private var errorMessage: String?
    @State private var isValidating = false
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("GitHub Personal Access Token")
                    .font(.headline)
                
                Text("To use this app, you need a GitHub Personal Access Token.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Link("Create a token at GitHub Settings →", destination: URL(string: "https://github.com/settings/tokens")!)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Token Requirements:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("• Scope: repo (Full control of private repositories)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter your token:")
                    .font(.subheadline)
                
                SecureField("ghp_...", text: $token)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        saveToken()
                    }
                    .disabled(isValidating)

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
            }
            
            HStack {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .disabled(isValidating)

                Spacer()

                Button("Save") {
                    saveToken()
                }
                .keyboardShortcut(.return)
                .disabled(token.isEmpty || isValidating)
            }
        }
        .padding(24)
        .frame(width: 450)
    }
    
    private func saveToken() {
        guard !token.isEmpty else { return }

        isValidating = true
        errorMessage = nil

        Task { @MainActor in
            defer { isValidating = false }

            do {
                let isValid = await validateToken(token)

                if isValid {
                    try KeychainManager.saveToken(token)
                    dismissWindow(id: "token-prompt")
                    await appState.manualRefresh()
                } else {
                    errorMessage = "Invalid token. Please check and try again."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func validateToken(_ token: String) async -> Bool {
        let url = URL(string: "https://api.github.com/user")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
    TokenPromptView()
}
