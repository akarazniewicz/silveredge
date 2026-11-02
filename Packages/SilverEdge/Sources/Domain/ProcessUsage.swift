/// What a process list ranks by: %CPU (100 is one full core) or memory footprint per process,
/// or Energy Impact per app. Persisted by raw value (the CPU panel's switch).
package enum ProcessMetric: String, Sendable {
    case cpu
    case memory
    case energy
}

/// One process (or, for energy, one app's coalition) and its value.
package struct ProcessUsage: Equatable, Sendable, Identifiable {
    package var pid: Int32
    package var name: String
    package var value: Double
    /// Its part of the whole Mac's total, 0…1, where there is one (energy).
    package var share: Double?
    /// Processes counted with it that can't be read separately (a shared system group: "WindowServer + 1").
    package var others: Int

    package var id: Int32 { pid }

    package init(pid: Int32, name: String, value: Double, share: Double? = nil, others: Int = 0) {
        self.pid = pid
        self.name = name
        self.value = value
        self.share = share
        self.others = others
    }
}
