import SwiftUI
import Domain

struct MeterRow: View {
    let label: String
    let value: String
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
                        .frame(width: max(PanelTheme.meterHeight, proxy.size.width * fraction.clampedToUnit))
                }
            }
            .frame(width: width, height: PanelTheme.meterHeight)
    }
}
