/// The kernel's cumulative CPU tick counters (`host_cpu_load_info`), all cores together.
package struct CPUTicks: Equatable, Sendable {
    package var user: UInt32
    package var system: UInt32
    package var idle: UInt32
    package var nice: UInt32

    package init(user: UInt32, system: UInt32, idle: UInt32, nice: UInt32) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }
}

/// Share of CPU time between two tick snapshots, each 0…1.
package struct CPUUsage: Equatable, Sendable {
    package var user: Double
    package var system: Double

    package var total: Double { user + system }

    package static let zero = CPUUsage(user: 0, system: 0)

    package init(user: Double, system: Double) {
        self.user = user
        self.system = system
    }

    /// Counters are 32-bit and wrap; wrapping subtraction keeps the delta right across it.
    package static func between(_ old: CPUTicks, _ new: CPUTicks) -> CPUUsage {
        // Niced time is user time, as Activity Monitor counts it.
        let user = Double(new.user &- old.user) + Double(new.nice &- old.nice)
        let system = Double(new.system &- old.system)
        let all = user + system + Double(new.idle &- old.idle)
        guard all > 0 else { return .zero }
        return CPUUsage(user: user / all, system: system / all)
    }
}
