import SwiftUI

public struct PrivacyShieldView: View {
    public let biometryType: BiometryType
    public let onUnlockRequested: () -> Void
    public let onLogoutRequested: (() -> Void)?

    public init(
        biometryType: BiometryType = .none,
        onUnlockRequested: @escaping () -> Void = {},
        onLogoutRequested: (() -> Void)? = nil
    ) {
        self.biometryType = biometryType
        self.onUnlockRequested = onUnlockRequested
        self.onLogoutRequested = onLogoutRequested
    }

    public var body: some View {
        ZStack {
            VaultTheme.obsidian
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Shield Brand Graphic
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(VaultTheme.accentSubtle)
                            .frame(width: 90, height: 90)

                        Circle()
                            .strokeBorder(VaultTheme.accentBright.opacity(0.35), lineWidth: 1.5)
                            .frame(width: 90, height: 90)

                        if let path = Bundle.module.path(forResource: "LogoPicture", ofType: "png") ?? Bundle.module.path(forResource: "logo-image", ofType: "png"),
                           let uiImage = UIImage(contentsOfFile: path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                        } else {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 44))
                                .foregroundColor(VaultTheme.accentBright)
                        }
                    }

                    VStack(spacing: 6) {
                        Text("VaultScope")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(VaultTheme.textPrimary)

                        Text("Critical Infrastructure Shield Active")
                            .font(.subheadline)
                            .foregroundColor(VaultTheme.textMuted)
                    }
                }

                VStack(spacing: 8) {
                    Text("Session data and server telemetry are encrypted and protected by the Secure Enclave.")
                        .font(.caption)
                        .foregroundColor(VaultTheme.textFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }

                Button {
                    onUnlockRequested()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: biometryType.icon)
                            .font(.headline)
                        Text("Unlock with \(biometryType.rawValue)")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(VaultTheme.accent)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(VaultTheme.accentBright.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(.top, 10)

                if let onLogout = onLogoutRequested {
                    Button {
                        onLogout()
                    } label: {
                        Text("Sign Out of Session")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(VaultTheme.textMuted)
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: 440)
            .frame(maxWidth: .infinity)
        }
    }
}
