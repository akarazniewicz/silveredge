import Foundation
import Domain

@MainActor
package final class ProcessSampler {
    package var onUpdate: ([ProcessUsage]) -> Void = { _ in }

    private let queue = DispatchQueue(label: "com.silveredge.processes", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var generation = 0

    package init() {}

    /// A rate list's first read is only its baseline and returns nothing, so it's read again after `warmUp`.
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

    private static let warmUp = 0.4

    package func stop() {
        timer?.cancel()
        timer = nil
        generation += 1
    }
}
