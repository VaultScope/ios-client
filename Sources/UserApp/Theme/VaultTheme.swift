import SwiftUI
import UIKit

// MARK: - VaultScope Architectural Obsidian Design System & Native Liquid Glass
public enum VaultTheme {
    // Obsidian Dark Surface Foundation (matching website /src/index.css)
    public static let obsidian = Color(red: 0.012, green: 0.012, blue: 0.016) // #030304
    public static let card = Color(red: 0.035, green: 0.035, blue: 0.043)     // #09090B
    public static let cardElevated = Color(red: 0.055, green: 0.055, blue: 0.065) // #0E0E11
    public static let subtle = Color(red: 0.067, green: 0.067, blue: 0.078)   // #111114

    // Borders & Hairline Dividers
    public static let line = Color(red: 0.118, green: 0.118, blue: 0.141)     // #1E1E24
    public static let lineStrong = Color(red: 0.180, green: 0.180, blue: 0.212) // #2E2E36

    // Dominant Solid Brand Accent — VaultScope Purple
    public static let primary = Color(red: 0.427, green: 0.157, blue: 0.851)   // #6D28D9
    public static let accent = Color(red: 0.427, green: 0.157, blue: 0.851)    // #6D28D9
    public static let accentBright = Color(red: 0.608, green: 0.365, blue: 0.898) // #9B5DE5
    public static let accentSubtle = Color(red: 0.427, green: 0.157, blue: 0.851).opacity(0.15)
    public static let accentGlow = Color(red: 0.486, green: 0.227, blue: 0.929).opacity(0.20)

    // Operational Status Tokens
    public static let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)  // #10B981 (OK)
    public static let ok = Color(red: 0.063, green: 0.725, blue: 0.506)
    public static let amber = Color(red: 0.961, green: 0.620, blue: 0.043)    // #F59E0B (WARN)
    public static let warn = Color(red: 0.961, green: 0.620, blue: 0.043)
    public static let rose = Color(red: 0.973, green: 0.443, blue: 0.443)     // #F87171 (ERR)
    public static let err = Color(red: 0.973, green: 0.443, blue: 0.443)
    public static let cyan = Color(red: 0.024, green: 0.714, blue: 0.831)     // #06B6D4
    public static let purple = Color(red: 0.608, green: 0.365, blue: 0.898)

    // High-Contrast Alabaster Typography (WCAG 2.2 AA verified)
    public static let textPrimary = Color(red: 0.973, green: 0.980, blue: 0.988) // #F8FAFC
    public static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.667) // #A1A1AA
    public static let textMuted = Color(red: 0.631, green: 0.631, blue: 0.667)     // #A1A1AA
    public static let textFaint = Color(red: 0.545, green: 0.545, blue: 0.584)     // #8B8B95

    public static let background = obsidian
    public static let cardBackground = card
}

// MARK: - Native UIGlassEffect Wrapper (iOS 26+ Liquid Glass)
@available(iOS 26.0, *)
public struct NativeUIGlassRepresentable: UIViewRepresentable {
    public var style: UIGlassEffect.Style
    public var tintColor: UIColor?
    public var isInteractive: Bool

    public init(style: UIGlassEffect.Style = .regular, tintColor: UIColor? = nil, isInteractive: Bool = false) {
        self.style = style
        self.tintColor = tintColor
        self.isInteractive = isInteractive
    }

    public func makeUIView(context: Context) -> UIVisualEffectView {
        let glass = UIGlassEffect(style: style)
        glass.tintColor = tintColor
        glass.isInteractive = isInteractive
        let effectView = UIVisualEffectView(effect: glass)
        effectView.layer.masksToBounds = true
        return effectView
    }

    public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        if let glass = uiView.effect as? UIGlassEffect {
            glass.tintColor = tintColor
            glass.isInteractive = isInteractive
        }
    }
}

// MARK: - Liquid Glass Background
public struct LiquidGlassBackground: View {
    public var cornerRadius: CGFloat
    public var tint: Color?
    public var isInteractive: Bool

    public init(cornerRadius: CGFloat = 14, tint: Color? = nil, isInteractive: Bool = false) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.isInteractive = isInteractive
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            NativeUIGlassRepresentable(
                style: .regular,
                tintColor: tint != nil ? UIColor(tint!) : nil,
                isInteractive: isInteractive
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(VaultTheme.line, lineWidth: 1)
            )
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(VaultTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(VaultTheme.line, lineWidth: 1)
                )
        }
    }
}

// MARK: - Obsidian Card ViewModifier
public struct ObsidianCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var padding: CGFloat

    public init(cornerRadius: CGFloat = 14, padding: CGFloat = 16) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(VaultTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(VaultTheme.line, lineWidth: 1)
            )
    }
}

// MARK: - View Modifiers
public extension View {
    func liquidGlass(cornerRadius: CGFloat = 14, tint: Color? = nil, isInteractive: Bool = false) -> some View {
        self.background(
            LiquidGlassBackground(cornerRadius: cornerRadius, tint: tint, isInteractive: isInteractive)
        )
    }

    func vaultCard(cornerRadius: CGFloat = 14) -> some View {
        self.liquidGlass(cornerRadius: cornerRadius)
    }

    func obsidianCard(cornerRadius: CGFloat = 14, padding: CGFloat = 16) -> some View {
        self.modifier(ObsidianCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}
