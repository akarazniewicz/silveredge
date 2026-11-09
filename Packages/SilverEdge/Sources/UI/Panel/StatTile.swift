import SwiftUI

struct StatTile: View {
    @Environment(\.panelPalette) private var palette
    let value: String
    var fraction: Double?
    var tint: Color?
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(PanelTheme.headlineFont).lineLimit(1).minimumScaleFactor(0.8)
            if let fraction {
                Meter(fraction: fraction, tint: tint, width: nil)
            }
            Text(caption).font(PanelTheme.captionFont).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.tileFill, in: RoundedRectangle(cornerRadius: PanelTheme.tileRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
