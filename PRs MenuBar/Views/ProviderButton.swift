import SwiftUI

struct ProviderButton: View {

    // MARK: - Properties
    let provider: GitProvider
    let isSelected: Bool
    let action: () -> Void

    // MARK: - UI
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: provider.iconName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.displayName)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)

                    if provider == .gitea {
                        Text("Self-hosted")
                            .font(.caption)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 12) {
        ProviderButton(provider: .github, isSelected: true) {}
        ProviderButton(provider: .gitlab, isSelected: false) {}
        ProviderButton(provider: .gitea, isSelected: false) {}
    }
    .padding()
    .frame(width: 300)
}
