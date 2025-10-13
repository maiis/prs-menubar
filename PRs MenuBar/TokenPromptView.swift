import SwiftUI

struct TokenPromptView: View {
    @State private var token = ""
    @State private var errorMessage: String?
    @Environment(\.dismissWindow) private var dismissWindow
    
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
                
                Spacer()
                
                Button("Save") {
                    saveToken()
                }
                .keyboardShortcut(.return)
                .disabled(token.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 450)
    }
    
    private func saveToken() {
        do {
            try KeychainManager.saveToken(token)
            dismissWindow(id: "token-prompt")
            Task { @MainActor in
                await AppState.shared.manualRefresh()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    TokenPromptView()
}
