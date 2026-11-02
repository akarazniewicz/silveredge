import Foundation
import IOKit
import Domain

/// The GPU's own statistics from its IOAccelerator registry entry. Only while the CPU panel is open.
package enum GPUReader {
    package static func read() -> GPUStats? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOAccelerator"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        func property(_ key: String) -> Any? {
            IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        }
        let statistics = property("PerformanceStatistics") as? [String: Any]
        return GPUStats(
            name: property("model") as? String ?? "GPU",
            utilization: (statistics?["Device Utilization %"] as? NSNumber).map { min(1, $0.doubleValue / 100) },
            memoryInUse: (statistics?["In use system memory"] as? NSNumber)?.uint64Value
        )
    }
}
