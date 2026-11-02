/// The kernel's memory pressure level.
package enum MemoryPressure: Int, Comparable, Sendable {
    case normal
    case warning
    case critical

    /// Ordered by severity, so the worst of an interval is its `max`.
    package static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// `kern.memorystatus_vm_pressure_level`: 1 normal, 2 warning, 4 critical.
    package init(kernelLevel: Int32) {
        switch kernelLevel {
        case 4: self = .critical
        case 2: self = .warning
        default: self = .normal
        }
    }
}
