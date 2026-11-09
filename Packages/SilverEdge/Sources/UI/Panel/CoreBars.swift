import SwiftUI
import Domain

struct CoreBars: View {
    @Environment(\.panelPalette) private var palette
    let group: CoreGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(PanelFormat.cores(group.kind)) + Text(verbatim: " · \(group.loads.count)").foregroundStyle(.secondary)
                Spacer()
                Text(PanelFormat.percent(group.average)).font(PanelTheme.valueFont)
            }
            .accessibilityElement(children: .combine)
            HStack(spacing: PanelTheme.coreBarSpacing) {
                ForEach(group.loads.indices, id: \.self) { index in
                    CoreBar(load: group.loads[index], tint: group.kind == .efficiency ? palette.efficiency : palette.accent)
                }
            }
            .frame(height: PanelTheme.coreBarHeight)
            .accessibilityHidden(true)
        }
    }
}

private struct CoreBar: View {
    @Environment(\.panelPalette) private var palette
    let load: Double
    let tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(palette.track)
            .overlay(alignment: .bottom) {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(tint)
                        .frame(height: max(2, proxy.size.height * load.clampedToUnit))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
    }
}
