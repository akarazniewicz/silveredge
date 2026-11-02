import SwiftUI

/// A few short segments, lit up to the current level in its colour: memory and thermal pressure.
struct LevelGauge: View {
    @Environment(\.panelPalette) private var palette
    let steps: Int
    /// How many segments are lit, 1…steps.
    let lit: Int
    let color: Color
    var segmentWidth = PanelTheme.gaugeSegmentWidth

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<steps, id: \.self) { step in
                Capsule()
                    .fill(step < lit ? color : palette.track)
                    .frame(width: segmentWidth, height: PanelTheme.gaugeSegmentHeight)
            }
        }
        .accessibilityHidden(true)
    }
}
