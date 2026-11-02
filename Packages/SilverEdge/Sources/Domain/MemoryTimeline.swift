/// One stretch of the memory timeline.
package struct MemorySlot: Equatable, Sendable {
    /// Mean over the stretch, 0…1 of physical memory.
    package var usedFraction: Double
    /// The worst level seen: macOS reports only levels, so that's what's kept — never a percentage.
    package var pressure: MemoryPressure
    /// Mean bytes per second.
    package var swapIn: Double
    package var swapOut: Double

    package init(usedFraction: Double, pressure: MemoryPressure, swapIn: Double, swapOut: Double) {
        self.usedFraction = usedFraction
        self.pressure = pressure
        self.swapIn = swapIn
        self.swapOut = swapOut
    }
}

/// The last hour of memory in fixed slots, oldest first: samples average into their slot,
/// and time with no samples (sleep) stays as empty slots rather than closing up.
package struct MemoryTimeline: Sendable {
    package static let slotSeconds = 30.0
    package static let slotCount = 120

    /// The slot still filling: its index on the clock, its running sums and how many samples they hold.
    private struct OpenSlot {
        var index: Int
        var sum: MemorySlot
        var count: Int
    }

    private var closed = History<MemorySlot?>(capacity: slotCount)
    private var open: OpenSlot?

    package init() {}

    /// `time`: seconds on a clock that keeps running through sleep.
    package mutating func add(usedFraction: Double, pressure: MemoryPressure, swapRate: SwapRate?, at time: Double) {
        let index = Int(time / Self.slotSeconds)
        let swapIn = swapRate?.inPerSecond ?? 0
        let swapOut = swapRate?.outPerSecond ?? 0
        if let current = open, current.index == index {
            open = OpenSlot(index: index, sum: MemorySlot(usedFraction: current.sum.usedFraction + usedFraction,
                                                          pressure: max(current.sum.pressure, pressure),
                                                          swapIn: current.sum.swapIn + swapIn, swapOut: current.sum.swapOut + swapOut),
                            count: current.count + 1)
            return
        }
        if let current = open {
            closed.append(Self.mean(current.sum, current.count))
            // Whole slots without a sample, up to an hour's worth.
            for _ in 0..<min(max(0, index - current.index - 1), Self.slotCount) { closed.append(nil) }
        }
        open = OpenSlot(index: index, sum: MemorySlot(usedFraction: usedFraction, pressure: pressure, swapIn: swapIn, swapOut: swapOut), count: 1)
    }

    /// Up to `slotCount` slots, oldest first, the one still filling last; nil where nothing was sampled.
    package var slots: [MemorySlot?] {
        let all = closed.values + [open.map { Self.mean($0.sum, $0.count) }].compactMap { $0 }
        return Array(all.suffix(Self.slotCount))
    }

    private static func mean(_ sum: MemorySlot, _ count: Int) -> MemorySlot {
        let n = Double(max(count, 1))
        return MemorySlot(usedFraction: sum.usedFraction / n, pressure: sum.pressure, swapIn: sum.swapIn / n, swapOut: sum.swapOut / n)
    }
}

package enum SwapScale {
    /// The swap graph's full height: its busiest slot, but never under 1 MB/s, so a quiet hour stays flat
    /// instead of blowing a few kilobytes up to full height.
    package static func top(of slots: [MemorySlot?]) -> Double {
        max(1_048_576, slots.compactMap { $0.map { max($0.swapIn, $0.swapOut) } }.max() ?? 0)
    }
}
