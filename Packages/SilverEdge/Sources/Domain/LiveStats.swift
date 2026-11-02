import Observation

/// One sample per tick: CPU since the last tick and memory now.
package struct Sample: Equatable, Sendable {
    package var cpu: CPUUsage
    package var memory: MemoryStats
    /// Seconds on a clock that keeps running through sleep.
    package var time: Double
    /// Nil on the first sample.
    package var swapRate: SwapRate?
    /// Only while the CPU panel is open.
    package var details: CPUDetails?

    package init(cpu: CPUUsage, memory: MemoryStats, time: Double, swapRate: SwapRate?, details: CPUDetails?) {
        self.cpu = cpu
        self.memory = memory
        self.time = time
        self.swapRate = swapRate
        self.details = details
    }
}

/// The latest readings, observed by open panels. With no panel open nothing
/// observes it, so updating it costs only the store.
@MainActor
@Observable
package final class LiveStats {
    package var sample: Sample?
    /// About two minutes of CPU at the closed-panel rate; kept always so an opened graph has a past.
    package var cpuHistory = History<CPUUsage>(capacity: 120)
    /// The last hour: usage, pressure and swap activity (`MemoryTimeline`).
    package var memoryTimeline = MemoryTimeline()
    /// The most memory used since SilverEdge started.
    package var memoryPeak: UInt64 = 0
    package var pressure: MemoryPressure = .normal
    package var thermal: ThermalPressure = .nominal
    package var lowPower = false
    /// Highest first, by the open panel's metric; empty with no panel open.
    package var processes: [ProcessUsage] = []
    /// What the CPU panel's list ranks by: `.cpu` or `.energy`.
    package var cpuListMetric: ProcessMetric = .cpu
    /// False when the system lacks what the energy list reads; the CPU panel then hides its switch.
    package var energyAvailable = false

    package init() {}
}
