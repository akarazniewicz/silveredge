import SwiftUI
import Domain

/// Label, value, and a thin bar: the panels' basic row.
struct MeterRow: View {
    let label: String
    let value: String
    /// 0…1; nil hides the bar.
    var fraction: Double?
    var tint: Color?

    var body: some View {
        HStack(spacing: 8) {
            Text(label).lineLimit(1)
            Spacer(minLength: 8)
            Text(value).font(PanelTheme.valueFont).lineLimit(1).fixedSize()
            if let fraction {
                Meter(fraction: fraction, tint: tint)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A capsule track filled to `fraction`; `width` nil fills the space it's given.
struct Meter: View {
    @Environment(\.panelPalette) private var palette
    let fraction: Double
    var tint: Color?
    var width: CGFloat? = PanelTheme.meterWidth

    var body: some View {
        Capsule()
            .fill(palette.track)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(tint ?? palette.accent)
                        // At least a dot, so a near-zero value still shows where it is.
                        .frame(width: max(PanelTheme.meterHeight, proxy.size.width * fraction.clampedToUnit))
                }
            }
            .frame(width: width, height: PanelTheme.meterHeight)
    }
}
