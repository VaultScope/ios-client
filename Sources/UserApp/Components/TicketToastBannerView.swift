import SwiftUI

public struct TicketToastBannerView: View {
    public let item: TicketToastItem
    public let onTap: () -> Void
    public let onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0

    public init(
        item: TicketToastItem,
        onTap: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.item = item
        self.onTap = onTap
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Leading Icon with Ambient Glow
                ZStack {
                    Circle()
                        .fill(item.accentColor.opacity(0.18))
                        .frame(width: 40, height: 40)

                    Image(systemName: item.iconName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(item.accentColor)
                }

                // Middle Content
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.ticketNumber)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(item.accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(item.accentColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                        Text(item.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(VaultTheme.textPrimary)
                            .lineLimit(1)
                    }

                    Text(item.message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(VaultTheme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                // Trailing Actions
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(VaultTheme.textMuted)

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(VaultTheme.textFaint)
                            .padding(6)
                            .background(VaultTheme.subtle)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .liquidGlass(cornerRadius: 18, tint: item.accentColor.opacity(0.08), isInteractive: true)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(item.accentColor.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: item.accentColor.opacity(0.15), radius: 12, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { val in
                    if val.translation.height < 0 {
                        dragOffset = val.translation.height
                    }
                }
                .onEnded { val in
                    if val.translation.height < -20 {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
}
