import SwiftUI
import Domain

/// Memory used over the last hour, as a share of physical memory.
struct MemoryUsageGraph: View {
    @Environment(\.panelPalette) private var palette
    let slots: [MemorySlot?]

    var body: some View {
        BarGraph(capacity: MemoryTimeline.slotCount, bars: slots.map { slot in
            slot.map { GraphBar(up: [.init(fraction: $0.usedFraction, color: palette.accent)]) }
        })
    }
}

/// Memory pressure over the last hour: each slot's worst level, as a step — macOS reports levels, not a percentage.
struct MemoryPressureGraph: View {
    @Environment(\.panelPalette) private var palette
    let slots: [MemorySlot?]

    var body: some View {
        BarGraph(capacity: MemoryTimeline.slotCount, bars: slots.map { slot in
            slot.map { GraphBar(up: [.init(fraction: Self.height($0.pressure), color: palette.pressure($0.pressure))]) }
        }, height: PanelTheme.pressureGraphHeight, capped: true)
    }

    /// A third per level, so normal still shows as a low green band.
    private static func height(_ pressure: MemoryPressure) -> Double {
        Double(pressure.rawValue + 1) / 3
    }
}

/// Swap in (up) and out (down) over the last hour, both against `scale` bytes per second.
struct SwapActivityGraph: View {
    @Environment(\.panelPalette) private var palette
    let slots: [MemorySlot?]
    let scale: Double

    var body: some View {
        BarGraph(capacity: MemoryTimeline.slotCount, bars: slots.map { slot in
            slot.map {
                GraphBar(up: [.init(fraction: $0.swapIn / scale, color: palette.accent)],
                         down: .init(fraction: $0.swapOut / scale, color: palette.orange))
            }
        }, height: PanelTheme.swapGraphHeight, mirrored: true)
    }
}

/// "60 min" at the left, "now" at the right: the time scale under an hour's graph.
struct HourAxis: View {
    var body: some View {
        HStack {
            Text(L10n.tr("axis.hour", "60 min"))
            Spacer()
            Text(L10n.tr("axis.now", "now"))
        }
        .font(PanelTheme.axisFont)
        .foregroundStyle(.tertiary)
        .accessibilityHidden(true)
    }
}
