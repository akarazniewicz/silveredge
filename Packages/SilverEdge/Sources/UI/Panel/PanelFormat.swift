import Foundation
import Domain

enum PanelFormat {
    private static let gigabyte = 1_073_741_824.0

    private static func decimal(_ value: Double, digits: Int) -> String {
        value.formatted(.number.precision(.fractionLength(digits)))
    }

    static func percent(_ fraction: Double) -> String {
        fraction.formatted(.percent.precision(.fractionLength(0)))
    }

    static func gigabytes(_ part: UInt64, of whole: UInt64) -> String {
        let part = decimal(Double(part) / gigabyte, digits: 1)
        let whole = (Double(whole) / gigabyte).formatted(.number.precision(.fractionLength(0...1)))
        return L10n.tr("format.gigabytesOf", "\(part) / \(whole) GB")
    }

    static func gigabytes(_ bytes: UInt64) -> String {
        L10n.tr("format.gigabytes", "\(decimal(Double(bytes) / gigabyte, digits: 1)) GB")
    }

    static func memoryPart(_ part: MemoryPart) -> String {
        switch part {
        case .app: L10n.tr("breakdown.app", "App")
        case .wired: L10n.tr("breakdown.wired", "Wired")
        case .compressed: L10n.tr("breakdown.compressed", "Compressed")
        case .cached: L10n.tr("breakdown.cached", "Cached")
        case .free: L10n.tr("breakdown.free", "Free")
        }
    }

    static func processPercent(_ percent: Double) -> String {
        (percent / 100).formatted(.percent.precision(.fractionLength(1)))
    }

    static func duration(_ seconds: Double) -> String {
        (seconds >= 86_400 ? daysFormatter : hoursFormatter).string(from: seconds) ?? ""
    }

    private static let daysFormatter = durationFormatter([.day, .hour])
    private static let hoursFormatter = durationFormatter([.hour, .minute])

    private static func durationFormatter(_ units: NSCalendar.Unit) -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .abbreviated
        return formatter
    }

    static func load(_ load: Double) -> String {
        decimal(load, digits: 2)
    }

    static func bytes(_ bytes: UInt64) -> String {
        byteFormatter.string(fromByteCount: Int64(clamping: bytes))
    }

    static func bytes(_ bytes: Double) -> String {
        Self.bytes(UInt64(max(0, bytes)))
    }

    /// `allowsNonnumericFormatting = false`, or zero prints as "Zero KB".
    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowsNonnumericFormatting = false
        return formatter
    }()

    static func bytesPerSecond(_ rate: Double) -> String {
        L10n.tr("format.perSecond", "\(bytes(rate))/s")
    }

    static func ratio(_ ratio: Double) -> String {
        L10n.tr("format.ratio", "\(decimal(ratio, digits: 1))×")
    }

    static func watts(_ watts: Double) -> String {
        L10n.tr("format.watts", "\(decimal(watts, digits: 1)) W")
    }

    static func celsius(_ celsius: Double) -> String {
        L10n.tr("format.celsius", "\(Int(celsius.rounded())) °C")
    }

    static func energy(_ score: Double) -> String {
        decimal(score, digits: 1)
    }

    static func number(_ value: Double) -> String {
        decimal(value, digits: 0)
    }

    static func process(_ value: Double, _ metric: ProcessMetric) -> String {
        switch metric {
        case .cpu: processPercent(value)
        case .memory: bytes(value)
        case .energy: energy(value)
        }
    }

    static func rpm(_ rpm: Double) -> String {
        L10n.tr("format.rpm", "\(number(rpm)) rpm")
    }

    static func thermal(_ pressure: ThermalPressure) -> String {
        switch pressure {
        case .nominal: L10n.tr("thermal.nominal", "Nominal")
        case .moderate: L10n.tr("thermal.moderate", "Moderate")
        case .heavy: L10n.tr("thermal.heavy", "Heavy")
        case .trapping: L10n.tr("thermal.trapping", "Trapping")
        case .sleeping: L10n.tr("thermal.sleeping", "Sleeping")
        }
    }

    static func cores(_ kind: CoreKind) -> String {
        switch kind {
        case .performance: L10n.tr("cores.performance", "Performance")
        case .efficiency: L10n.tr("cores.efficiency", "Efficiency")
        case .uniform: L10n.tr("cores.all", "All Cores")
        }
    }

    static func pressure(_ pressure: MemoryPressure) -> String {
        switch pressure {
        case .normal: L10n.tr("pressure.normal", "Normal")
        case .warning: L10n.tr("pressure.warning", "Elevated")
        case .critical: L10n.tr("pressure.critical", "Critical")
        }
    }
}
