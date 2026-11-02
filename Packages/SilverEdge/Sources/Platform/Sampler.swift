import Darwin
import Dispatch
import Domain

/// Ticks on the main queue: the reads take microseconds, so a worker
/// thread would cost more in wake-ups than it saves.
@MainActor
package final class Sampler {
    package var onSample: (Sample) -> Void = { _ in }
    /// Seconds between samples; the timer allows 20 % leeway so the system can coalesce wake-ups.
    package var interval: Double = 2 {
        didSet { if interval != oldValue, timer != nil { schedule(firstAfter: 0.3) } }
    }

    private var timer: DispatchSourceTimer?
    private var previous: CPUTicks?
    private var previousSwap: (swap: MemoryStats.Swap, time: UInt64)?
    private var previousCores: [CPUTicks]?
    /// Open only while details are read.
    private var fanProbe: FanProbe?

    package init() {}

    package func start() {
        previous = SystemReaders.cpuTicks()
        schedule(firstAfter: 0.5)
    }

    /// The first sample after `firstAfter` seconds, so a new item or panel doesn't wait a whole interval.
    private func schedule(firstAfter: Double) {
        timer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        let milliseconds = Int(interval * 1000)
        timer.schedule(deadline: .now() + firstAfter, repeating: .milliseconds(milliseconds), leeway: .milliseconds(milliseconds / 5))
        timer.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.activate()
        self.timer = timer
    }

    /// Starts reading cores, load and GPU each tick, and returns them now (cores at zero until the next tick
    /// has a delta) so the panel opens at its full size. That next tick comes soon, not a whole interval later.
    package func startDetails() -> CPUDetails {
        previousCores = SystemReaders.coreTicks()
        fanProbe = FanProbe()
        schedule(firstAfter: 0.3)
        return details(cores: previousCores.map { [Double](repeating: 0, count: $0.count) } ?? [])
    }

    package func stopDetails() {
        previousCores = nil
        fanProbe = nil
    }

    private func tick() {
        guard let ticks = SystemReaders.cpuTicks(), let memory = SystemReaders.memory() else { return }
        let cpu = previous.map { CPUUsage.between($0, ticks) } ?? .zero
        previous = ticks
        let now = DispatchTime.now().uptimeNanoseconds
        let swapRate = previousSwap.flatMap { SwapRate.between($0.swap, memory.swap, seconds: Double(now - $0.time) / 1e9) }
        previousSwap = (memory.swap, now)
        // CLOCK_MONOTONIC keeps counting through sleep on macOS, so the timeline shows the gap.
        let time = Double(clock_gettime_nsec_np(CLOCK_MONOTONIC)) / 1e9
        onSample(Sample(cpu: cpu, memory: memory, time: time, swapRate: swapRate, details: readDetails()))
    }

    private func readDetails() -> CPUDetails? {
        guard let old = previousCores, let new = SystemReaders.coreTicks() else { return nil }
        previousCores = new
        return details(cores: zip(old, new).map { CPUUsage.between($0, $1).total })
    }

    private func details(cores loads: [Double]) -> CPUDetails {
        CPUDetails(cores: CoreGroup.groups(loads: loads, efficiencyCount: SystemReaders.efficiencyCoreCount),
                   load: SystemReaders.loadAverage(), gpu: GPUReader.read(), battery: BatteryReader.read(),
                   fans: fanProbe?.read() ?? [])
    }
}
