import Foundation
import IOKit
import Domain

/// The internal battery from the smart battery's registry entry. Nil without one (desktop Macs).
/// Only while the CPU panel is open; reads just the keys it shows (the whole entry is ~9 KB, 5× slower).
package enum BatteryReader {
    package static func read() -> BatteryStatus? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        func property(_ key: String) -> Any? {
            IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        }
        func int(_ key: String) -> Int? { (property(key) as? NSNumber)?.intValue }
        func flag(_ key: String) -> Bool { (property(key) as? NSNumber)?.boolValue ?? false }
        guard let percent = int("CurrentCapacity") else { return nil }
        let charging = flag("IsCharging")
        // 65535 means "still estimating".
        let minutes = int(charging ? "AvgTimeToFull" : "AvgTimeToEmpty").flatMap { $0 > 0 && $0 < 65_535 ? $0 : nil }
        let adapter = property("AdapterDetails") as? [String: Any]
        return BatteryStatus(
            percent: percent, isCharging: charging, externalPower: flag("ExternalConnected"), fullyCharged: flag("FullyCharged"),
            minutesRemaining: minutes,
            // A signed value the registry hands over as unsigned.
            milliamps: (property("InstantAmperage") as? NSNumber).map { Int(Int64(bitPattern: $0.uint64Value)) } ?? 0,
            millivolts: int("Voltage") ?? 0,
            maxCapacity: int("AppleRawMaxCapacity") ?? 0, designCapacity: int("DesignCapacity") ?? 0, cycles: int("CycleCount") ?? 0,
            celsius: Double(int("Temperature") ?? 0) / 100,
            adapterWatts: (adapter?["Watts"] as? NSNumber)?.intValue
        )
    }
}
