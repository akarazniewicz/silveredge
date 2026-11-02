import SwiftUI
import Domain

/// The RAM item's panel: how much is used, by what, whether pressure is healthy, whether it's swapping, and who uses it.
package struct MemoryPanelView: View {
    @Environment(\.panelPalette) private var palette
    let stats: LiveStats
    let actions: PanelActions

    package init(stats: LiveStats, actions: PanelActions) {
        self.stats = stats
        self.actions = actions
    }

    package var body: some View {
        let memory = stats.sample?.memory
        let slots = stats.memoryTimeline.slots
        PanelContainer(actions: actions, tab: .memory) {
            PanelCard(title: L10n.tr("memory.title", "Memory"), symbol: "memorychip",
                      trailing: memory.map { PanelFormat.percent($0.usedFraction) }) {
                VStack(alignment: .leading, spacing: 8) {
                    usageRow(memory)
                    MemoryUsageGraph(slots: slots)
                    secondaryRow(memory)
                }
            }
            PanelCard(title: L10n.tr("memory.breakdown", "Breakdown"), symbol: "chart.bar.xaxis") {
                MemoryBreakdown(memory: memory)
            }
            PanelCard(title: L10n.tr("memory.pressureTitle", "Memory Pressure"), symbol: "gauge.with.dots.needle.33percent") {
                pressureLabel
            } content: {
                VStack(alignment: .leading, spacing: 4) {
                    MemoryPressureGraph(slots: slots)
                    HourAxis()
                }
            }
            PanelCard(title: L10n.tr("memory.swap", "Swap & Compression"), symbol: "arrow.left.arrow.right") {
                swapContent(memory, slots: slots)
            }
            PanelCard(title: L10n.tr("memory.processes", "Top Processes"), symbol: "list.number") {
                ProcessList(processes: stats.processes, metric: .memory)
            }
        }
    }

    /// Pressure level (not utilisation: a full Mac is normal) and how much is used of how much.
    private func usageRow(_ memory: MemoryStats?) -> some View {
        HStack(spacing: 8) {
            LevelGauge(steps: 3, lit: stats.pressure.rawValue + 1, color: palette.pressure(stats.pressure))
            Text(PanelFormat.pressure(stats.pressure)).font(PanelTheme.valueFont)
            Spacer(minLength: 6)
            Text(memory.map { PanelFormat.gigabytes($0.used, of: $0.physical) } ?? "—")
                .font(PanelTheme.valueFont).lineLimit(1).fixedSize()
        }
        .accessibilityElement(children: .combine)
    }

    private func secondaryRow(_ memory: MemoryStats?) -> some View {
        HStack {
            CaptionValue(label: L10n.tr("memory.available", "Available"), value: memory.map { PanelFormat.gigabytes($0.available) })
                .help(L10n.tr("memory.availableHelp", "Cached files and free memory: what apps can have without swapping."))
            Spacer()
            CaptionValue(label: L10n.tr("memory.peak", "Peak"), value: stats.memoryPeak > 0 ? PanelFormat.gigabytes(stats.memoryPeak) : nil)
                .help(L10n.tr("memory.peakHelp", "The most memory used since SilverEdge started."))
        }
    }

    private var pressureLabel: some View {
        HStack(spacing: 5) {
            LegendDot(color: palette.pressure(stats.pressure))
            Text(PanelFormat.pressure(stats.pressure)).font(PanelTheme.captionFont)
        }
        .accessibilityElement(children: .combine)
    }

    private func swapContent(_ memory: MemoryStats?, slots: [MemorySlot?]) -> some View {
        let rate = stats.sample?.swapRate
        let scale = SwapScale.top(of: slots)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                StatTile(value: memory.map { PanelFormat.gigabytes($0.swap.used) } ?? "—",
                         caption: L10n.tr("swap.used", "Swap Used"))
                StatTile(value: memory?.compressionRatio.map(PanelFormat.ratio) ?? "—",
                         caption: L10n.tr("swap.compression", "Compression"))
                    .help(L10n.tr("swap.compressionHelp", "How much memory the compressor holds, against the space it takes."))
            }
            VStack(alignment: .leading, spacing: 4) {
                SwapActivityGraph(slots: slots, scale: scale)
                HStack(spacing: 10) {
                    CaptionValue(label: L10n.tr("swap.in", "In"), value: rate.map { PanelFormat.bytesPerSecond($0.inPerSecond) },
                                 dot: palette.accent)
                    CaptionValue(label: L10n.tr("swap.out", "Out"), value: rate.map { PanelFormat.bytesPerSecond($0.outPerSecond) },
                                 dot: palette.orange)
                    Spacer()
                    Text(L10n.tr("swap.scale", "Scale \(PanelFormat.bytesPerSecond(scale))"))
                        .font(PanelTheme.axisFont).foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
        }
    }
}
