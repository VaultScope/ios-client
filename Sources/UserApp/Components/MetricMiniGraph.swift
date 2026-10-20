import SwiftUI

public struct MetricMiniGraph: View {
    public let title: String
    public let currentValue: String
    public let data: [Double]
    public let color: Color
    public let unit: String

    public init(
        title: String,
        currentValue: String,
        data: [Double],
        color: Color = VaultTheme.emerald,
        unit: String = "%"
    ) {
        self.title = title
        self.currentValue = currentValue
        self.data = data.isEmpty ? [10, 15, 20, 18, 25, 30] : data
        self.color = color
        self.unit = unit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 3) {
                        Text(currentValue)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)
                        Text(unit)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(color)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .liquidGlass(cornerRadius: 10, tint: color.opacity(0.15))
            }

            // Clean Native Sparkline
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let minVal = (data.min() ?? 0) * 0.8
                let maxVal = max(1.0, (data.max() ?? 100) * 1.1)

                let points = data.enumerated().map { index, val -> CGPoint in
                    let x = width * CGFloat(index) / CGFloat(max(1, data.count - 1))
                    let normalizedY = CGFloat((val - minVal) / (maxVal - minVal))
                    let y = height - (normalizedY * height)
                    return CGPoint(x: x, y: y)
                }

                ZStack {
                    // Line
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for pt in points.dropFirst() {
                            path.addLine(to: pt)
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Gradient fill
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: CGPoint(x: first.x, y: height))
                        path.addLine(to: first)
                        for pt in points.dropFirst() {
                            path.addLine(to: pt)
                        }
                        if let last = points.last {
                            path.addLine(to: CGPoint(x: last.x, y: height))
                        }
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // End point
                    if let last = points.last {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .position(last)
                    }
                }
            }
            .frame(height: 60)
        }
        .padding(14)
        .liquidGlass(cornerRadius: 16)
    }
}
