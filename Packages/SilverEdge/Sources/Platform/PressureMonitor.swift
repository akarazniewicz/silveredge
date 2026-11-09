import Dispatch
import Domain

@MainActor
package final class PressureMonitor {
    package private(set) var level = SystemReaders.memoryPressure()
    private let source = DispatchSource.makeMemoryPressureSource(eventMask: [.normal, .warning, .critical], queue: .main)

    package init(onChange: @escaping @MainActor (MemoryPressure) -> Void) {
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                // The event says a level was crossed; the sysctl says which level holds now.
                let level = SystemReaders.memoryPressure()
                guard level != self.level else { return }
                self.level = level
                onChange(level)
            }
        }
        source.activate()
    }

    deinit {
        source.cancel()
    }
}
