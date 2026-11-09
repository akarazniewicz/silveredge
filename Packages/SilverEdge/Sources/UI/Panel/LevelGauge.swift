import SwiftUI

struct LevelGauge: View {
    @Environment(\.panelPalette) private var palette
    let steps: Int
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
