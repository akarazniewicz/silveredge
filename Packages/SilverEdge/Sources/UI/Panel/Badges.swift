import SwiftUI

struct LowPowerBadge: View {
    @Environment(\.panelPalette) private var palette

    var body: some View {
        Label(L10n.tr("load.lowPower", "Low Power"), systemImage: "leaf.fill")
            .font(PanelTheme.captionFont)
            .labelStyle(.titleAndIcon)
            .foregroundStyle(palette.yellow)
            .padding(.horizontal, PanelTheme.badgePadding.width)
            .padding(.vertical, PanelTheme.badgePadding.height)
            .background(palette.yellow.opacity(0.15), in: Capsule())
    }
}

struct LegendDot: View {
    let color: Color

    var body: some View {
        Circle().fill(color).frame(width: PanelTheme.legendDot, height: PanelTheme.legendDot)
    }
}

struct CaptionValue: View {
    let label: String
    let value: String?
    var dot: Color?

    var body: some View {
        HStack(spacing: 4) {
            if let dot { LegendDot(color: dot) }
            Text(label).foregroundStyle(.secondary)
            Text(value ?? "—").monospacedDigit()
        }
        .font(PanelTheme.captionFont)
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}
