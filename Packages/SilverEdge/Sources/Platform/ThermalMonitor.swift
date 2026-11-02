import Darwin
import notify
import Foundation
import Domain

/// Thermal pressure and Low Power Mode, both pushed by the system — never polled.
@MainActor
package final class ThermalMonitor {
    package private(set) var pressure: ThermalPressure = .nominal
    package private(set) var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    private var token: Int32 = 0
    private var observer: NSObjectProtocol?

    package init(onChange: @escaping @MainActor () -> Void) {
        notify_register_dispatch("com.apple.system.thermalpressurelevel", &token, .main) { [weak self] token in
            MainActor.assumeIsolated {
                self?.pressure = Self.pressure(token)
                onChange()
            }
        }
        pressure = Self.pressure(token)
        observer = NotificationCenter.default.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
                onChange()
            }
        }
    }

    deinit {
        notify_cancel(token)
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    private static func pressure(_ token: Int32) -> ThermalPressure {
        var state: UInt64 = 0
        return notify_get_state(token, &state) == NOTIFY_STATUS_OK ? ThermalPressure(notifyState: state) : .nominal
    }
}
