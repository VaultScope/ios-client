import SwiftUI

public struct BannerToastView: View {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(VaultTheme.emerald)
                .font(.system(size: 16, weight: .semibold))

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 24)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}
