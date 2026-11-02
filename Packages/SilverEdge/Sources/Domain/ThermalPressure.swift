/// The system's thermal pressure (`com.apple.system.thermalpressurelevel`): how hard
/// macOS is holding the CPU back to stay cool. The CPU side of memory pressure.
package enum ThermalPressure: Int, Equatable, Sendable {
    case nominal
    case moderate
    case heavy
    case trapping
    case sleeping

    /// macOS publishes 0…4 (`OSThermalPressureLevel`); anything else reads nominal.
    package init(notifyState: UInt64) {
        self = ThermalPressure(rawValue: Int(min(notifyState, 5))) ?? .nominal
    }
}

extension ThermalPressure {
    /// Hidden at nominal, yellow while mildly throttled, red beyond.
    package var indicator: MenuBarReading.Indicator? {
        switch self {
        case .nominal: nil
        case .moderate: .warning
        case .heavy, .trapping, .sleeping: .critical
        }
    }
}

extension MemoryPressure {
    package var indicator: MenuBarReading.Indicator? {
        switch self {
        case .normal: nil
        case .warning: .warning
        case .critical: .critical
        }
    }
}
