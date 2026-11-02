import SwiftUI
import Domain

/// Physical memory as one stacked bar, then each part: its name, and a bar against physical memory with its size —
/// the parts don't overlap and add up to physical memory.
struct MemoryBreakdown: View {
    @Environment(\.panelPalette) private var palette
    let memory: MemoryStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            bar
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                GridRow {
                    part(.app)
                    part(.wired)
                }
                GridRow {
                    part(.compressed)
                    part(.cached)
                }
            }
            freeRow
        }
    }

    private var bar: some View {
        GeometryReader { proxy in
            HStack(spacing: 1.5) {
                if let memory, memory.physical > 0 {
                    ForEach(MemoryPart.allCases, id: \.self) { part in
                        Rectangle()
                            .fill(palette.breakdown(part))
                            .frame(width: proxy.size.width * memory.fraction(part))
                    }
                }
            }
            .frame(width: proxy.size.width, alignment: .leading)
            .background(palette.track)
            .clipShape(Capsule())
        }
        .frame(height: PanelTheme.breakdownHeight)
        .accessibilityHidden(true)
    }

    /// Name on its own line, so it's never cut; the bar and size under it.
    private func part(_ part: MemoryPart) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                dot(part)
                Text(PanelFormat.memoryPart(part)).lineLimit(1)
            }
            HStack(spacing: 6) {
                Meter(fraction: memory?.fraction(part) ?? 0, tint: palette.breakdown(part), width: PanelTheme.partMeterWidth)
                Spacer(minLength: 0)
                value(part)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var freeRow: some View {
        HStack(spacing: 6) {
            dot(.free)
            Text(PanelFormat.memoryPart(.free))
            Spacer(minLength: 6)
            value(.free)
        }
        .accessibilityElement(children: .combine)
    }

    private func dot(_ part: MemoryPart) -> some View {
        LegendDot(color: part == .free ? palette.secondaryText.opacity(0.5) : palette.breakdown(part))
    }

    private func value(_ part: MemoryPart) -> some View {
        Text(memory.map { PanelFormat.gigabytes($0.bytes(part)) } ?? "—").font(PanelTheme.valueFont).lineLimit(1).fixedSize()
    }
}
