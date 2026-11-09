import SwiftUI
import Domain

struct CPUHistoryGraph: View {
    @Environment(\.panelPalette) private var palette
    let history: History<CPUUsage>

    var body: some View {
        BarGraph(capacity: history.capacity, bars: history.values.map { usage in
            GraphBar(up: [.init(fraction: usage.user, color: palette.accent), .init(fraction: usage.system, color: palette.system)])
        })
    }
}
