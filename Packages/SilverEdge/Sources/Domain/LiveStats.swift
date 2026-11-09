import Observation

package struct Sample: Equatable, Sendable {
    package var cpu: CPUUsage
    package var memory: MemoryStats
    package var time: Double
    package var swapRate: SwapRate?
    package var details: CPUDetails?

    package init(cpu: CPUUsage, memory: MemoryStats, time: Double, swapRate: SwapRate?, details: CPUDetails?) {
        self.cpu = cpu
        self.memory = memory
        self.time = time
        self.swapRate = swapRate
        self.details = details
    }
}

@MainActor
@Observable
package final class LiveStats {
    package var sample: Sample?
    package var cpuHistory = History<CPUUsage>(capacity: 120)
    package var memoryTimeline = MemoryTimeline()
    package var memoryPeak: UInt64 = 0
    package var pressure: MemoryPressure = .normal
    package var thermal: ThermalPressure = .nominal
    package var lowPower = false
    package var processes: [ProcessUsage] = []
    package var cpuListMetric: ProcessMetric = .cpu
    package var energyAvailable = false

    package init() {}
}
