import Foundation
import Domain

/// Runs the open panel's process-list read (`ProcessProbe`) every few seconds. The timer fires on the reader's own serial queue, so the main thread only
/// wakes for results.
@MainActor
package final class ProcessSampler {
    package var onUpdate: ([ProcessUsage]) -> Void = { _ in }

    private let queue = DispatchQueue(label: "com.silveredge.processes", qos: .utility)
    private var timer: DispatchSourceTimer?
    /// Bumped on every start and stop, so a result from a reader that's since been replaced is dropped.
    private var generation = 0

    package init() {}

    /// Reads at once, then every `seconds`. A rate list (CPU, energy) answers its first read with nothing —
    /// that read is its baseline — so it's read again after `warmUp`, not a whole interval later.
    /// `read` runs on this sampler's serial queue only.
    package func start(every seconds: Double, read: @escaping @Sendable () -> [ProcessUsage]) {
        stop()
        let generation = generation
        let deliver: @Sendable ([ProcessUsage]) -> Void = { [weak self] processes in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self, generation == self.generation else { return }
                    self.onUpdate(processes)
                }
            }
        }
        let warmUp = Self.warmUp
        queue.async {
            let first = read()
            guard first.isEmpty else { return deliver(first) }
            Thread.sleep(forTimeInterval: warmUp)
            deliver(read())
        }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        let milliseconds = Int(seconds * 1000)
        timer.schedule(deadline: .now() + .milliseconds(milliseconds), repeating: .milliseconds(milliseconds),
                       leeway: .milliseconds(milliseconds / 5))
        timer.setEventHandler { deliver(read()) }
        timer.activate()
        self.timer = timer
    }

    /// Long enough for a meaningful first rate, short enough not to be noticed.
    private static let warmUp = 0.4

    package func stop() {
        timer?.cancel()
        timer = nil
        generation += 1
    }
}
