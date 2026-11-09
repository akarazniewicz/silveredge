import Foundation

package struct CoalitionCounters: Equatable, Sendable {
    /// CPU nanoseconds per thread QoS, in the kernel's order: unspecified, maintenance, background,
    /// utility, legacy, user-initiated, user-interactive. Empty when the kernel doesn't split it.
    package var cpuByQoS: [UInt64]
    package var cpuTotal: UInt64
    package var wakeups: UInt64
    package var bytesRead: UInt64
    package var bytesWritten: UInt64
    package var gpuNanoseconds: UInt64

    package init(cpuByQoS: [UInt64], cpuTotal: UInt64, wakeups: UInt64, bytesRead: UInt64, bytesWritten: UInt64, gpuNanoseconds: UInt64) {
        self.cpuByQoS = cpuByQoS
        self.cpuTotal = cpuTotal
        self.wakeups = wakeups
        self.bytesRead = bytesRead
        self.bytesWritten = bytesWritten
        self.gpuNanoseconds = gpuNanoseconds
    }
}

/// Activity Monitor's Energy Impact weights (`energy_constants` in `/usr/share/pmenergy/*.plist`).
package struct EnergyWeights: Equatable, Sendable {
    package var cpuTime: Double
    package var wakeup: Double
    package var byteRead: Double
    package var byteWritten: Double
    package var gpuTime: Double
    package var qos: [Double]

    package static let standard = EnergyWeights(
        cpuTime: 1, wakeup: 0.0002, byteRead: 4.5e-10, byteWritten: 2.4e-10, gpuTime: 0, qos: [1, 0.8, 0.8, 1, 1, 1, 1]
    )

    package init(cpuTime: Double, wakeup: Double, byteRead: Double, byteWritten: Double, gpuTime: Double, qos: [Double]) {
        self.cpuTime = cpuTime
        self.wakeup = wakeup
        self.byteRead = byteRead
        self.byteWritten = byteWritten
        self.gpuTime = gpuTime
        self.qos = qos
    }

    package init(constants: [String: Double]) {
        let base = Self.standard
        func value(_ key: String, _ fallback: Double) -> Double { constants[key] ?? fallback }
        let background = value("kqos_background", base.qos[2])
        self.init(
            cpuTime: value("kcpu_time", base.cpuTime), wakeup: value("kcpu_wakeups", base.wakeup),
            byteRead: value("kdiskio_bytesread", base.byteRead), byteWritten: value("kdiskio_byteswritten", base.byteWritten),
            gpuTime: value("kgpu_time", base.gpuTime),
            qos: [value("kqos_default", base.qos[0]), background, background, value("kqos_utility", base.qos[3]),
                  value("kqos_legacy", base.qos[4]), value("kqos_user_initiated", base.qos[5]), value("kqos_user_interactive", base.qos[6])]
        )
    }
}

package enum EnergyImpact {
    /// Activity Monitor's Energy Impact over an interval: weighted CPU-equivalent time in units of 10 ms per second,
    /// so one fully busy core at default QoS reads 100. Network packets aren't in coalitions and aren't counted.
    package static func score(from old: CoalitionCounters, to new: CoalitionCounters, seconds: Double, weights: EnergyWeights) -> Double {
        guard seconds > 0 else { return 0 }
        func delta(_ old: UInt64, _ new: UInt64) -> Double { new >= old ? Double(new - old) : 0 }
        let cpu: Double
        if new.cpuByQoS.count == old.cpuByQoS.count, !new.cpuByQoS.isEmpty {
            cpu = zip(zip(old.cpuByQoS, new.cpuByQoS), weights.qos).reduce(0) { $0 + delta($1.0.0, $1.0.1) * $1.1 }
        } else {
            cpu = delta(old.cpuTotal, new.cpuTotal)
        }
        let nanoseconds = cpu * weights.cpuTime
            + delta(old.wakeups, new.wakeups) * weights.wakeup * 1e9
            + delta(old.bytesRead, new.bytesRead) * weights.byteRead * 1e9
            + delta(old.bytesWritten, new.bytesWritten) * weights.byteWritten * 1e9
            + delta(old.gpuNanoseconds, new.gpuNanoseconds) * weights.gpuTime
        return nanoseconds / seconds / 1e7
    }

    package enum Level: Equatable, Sendable {
        case light
        case moderate
        case high
        case extreme
    }

    package static func level(_ score: Double) -> Level {
        switch score {
        case ..<10: .light
        case ..<50: .moderate
        case ..<100: .high
        default: .extreme
        }
    }

    package static func share(_ score: Double, of total: Double) -> Double {
        total > 0 ? (score / total).clampedToUnit : 0
    }

    /// An app's main executable (exactly one `.app/Contents/MacOS/` in its path) names its coalition,
    /// else the lowest pid.
    package static func representative(of members: [(pid: Int32, path: String)]) -> (pid: Int32, name: String)? {
        let marker = ".app/Contents/MacOS/"
        let app = members.filter { $0.path.components(separatedBy: marker).count == 2 }.min { $0.pid < $1.pid }
        guard let chosen = app ?? members.min(by: { $0.pid < $1.pid }) else { return nil }
        return (chosen.pid, chosen.path.split(separator: "/").last.map(String.init) ?? "")
    }
}
