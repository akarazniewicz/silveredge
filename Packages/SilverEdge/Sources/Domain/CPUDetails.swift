/// What only the open CPU panel reads: cores, load, GPU, battery and fans.
package struct CPUDetails: Equatable, Sendable {
    package var cores: [CoreGroup]
    package var load: LoadAverage
    package var gpu: GPUStats?
    /// Nil on a Mac without a battery.
    package var battery: BatteryStatus?
    /// Empty on a fanless Mac.
    package var fans: [FanStatus]

    package init(cores: [CoreGroup], load: LoadAverage, gpu: GPUStats?, battery: BatteryStatus?, fans: [FanStatus]) {
        self.cores = cores
        self.load = load
        self.gpu = gpu
        self.battery = battery
        self.fans = fans
    }
}

package enum CoreKind: Equatable, Sendable {
    case performance
    case efficiency
    /// A CPU with one kind of core (Intel).
    case uniform
}

/// One kind of core and each core's busy share, 0…1.
package struct CoreGroup: Equatable, Sendable {
    package var kind: CoreKind
    package var loads: [Double]

    package var average: Double { loads.isEmpty ? 0 : loads.reduce(0, +) / Double(loads.count) }

    package init(kind: CoreKind, loads: [Double]) {
        self.kind = kind
        self.loads = loads
    }

    /// Apple silicon numbers its efficiency cores first. Performance cores are listed first.
    package static func groups(loads: [Double], efficiencyCount: Int) -> [CoreGroup] {
        guard efficiencyCount > 0, efficiencyCount < loads.count else { return [CoreGroup(kind: .uniform, loads: loads)] }
        return [CoreGroup(kind: .performance, loads: Array(loads[efficiencyCount...])),
                CoreGroup(kind: .efficiency, loads: Array(loads[..<efficiencyCount]))]
    }
}

package struct LoadAverage: Equatable, Sendable {
    package var one: Double
    package var five: Double
    package var fifteen: Double
    /// Seconds since boot, sleep included.
    package var uptime: Double

    package init(one: Double, five: Double, fifteen: Double, uptime: Double) {
        self.one = one
        self.five = five
        self.fifteen = fifteen
        self.uptime = uptime
    }
}

package struct GPUStats: Equatable, Sendable {
    package var name: String
    /// 0…1.
    package var utilization: Double?
    package var memoryInUse: UInt64?

    package init(name: String, utilization: Double?, memoryInUse: UInt64?) {
        self.name = name
        self.utilization = utilization
        self.memoryInUse = memoryInUse
    }
}
