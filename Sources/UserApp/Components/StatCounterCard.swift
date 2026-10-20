import SwiftUI

public struct StatCounterCard: View {
    public let title: String
    public let value: String
    public let subtitle: String
    public let icon: String
    public let accentColor: Color

    public init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        accentColor: Color = .accentColor
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .liquidGlass(cornerRadius: 16)
    }
}
