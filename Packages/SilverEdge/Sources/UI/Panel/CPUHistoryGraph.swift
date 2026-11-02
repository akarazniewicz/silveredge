import SwiftUI
import Domain

/// The CPU's recent past: user below, system stacked on it.
struct CPUHistoryGraph: View {
    @Environment(\.panelPalette) private var palette
    let history: History<CPUUsage>

    var body: some View {
        BarGraph(capacity: history.capacity, bars: history.values.map { usage in
            GraphBar(up: [.init(fraction: usage.user, color: palette.accent), .init(fraction: usage.system, color: palette.system)])
        })
    }
}
