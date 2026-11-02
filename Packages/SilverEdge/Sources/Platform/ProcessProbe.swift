import Darwin
import Foundation
import IOKit
import Domain

/// The process lists: per process by CPU or memory, per app by Energy Impact — without `ps` or `top`.
///
/// Readable processes (this user's) come from `proc_pid_rusage`: exact CPU time and footprint, the figures
/// Activity Monitor shows. The rest (root and other users') are counted through the kernel's resource
/// coalitions, which can be read without root: a daemon alone in its coalition exactly, a few sharing one
/// as a group (`ProcessRanking`). Energy Impact is per coalition, as Activity Monitor's Energy tab groups it.
///
/// The only code that touches the private coalition interface: `coalition_info_resource_usage` (resolved at
/// run time — without it only readable processes are listed and there's no energy), `PROC_PIDCOALITIONINFO`,
/// and the layout of `struct coalition_resource_usage` (xnu `osfmk/mach/coalition.h`) as word slots. The struct
/// only grows at its end and the kernel copies no more than the buffer it's given, so a larger buffer stays safe.
///
/// Stateful (previous counters for CPU and energy): use from one serial queue.
package final class ProcessProbe: @unchecked Sendable {
    private typealias ResourceUsage = @convention(c) (UInt64, UnsafeMutableRawPointer, Int) -> Int32

    /// `proc_pidinfo` flavor: `struct proc_pidcoalitioninfo { uint64_t coalition_id[2]; uint64_t reserved[3]; }`.
    private static let pidCoalitionInfo: Int32 = 20
    /// Slots of `struct coalition_resource_usage`, as 64-bit words.
    private enum Slot {
        static let cpuTime = 3
        static let interruptWakeups = 4
        static let idleWakeups = 5
        static let bytesRead = 6
        static let bytesWritten = 7
        static let gpuTime = 8
        static let qosCount = 23
        static let qosTimes = 24
        static let maxQoS = 7
        static let physFootprint = 40
    }
    /// Room for today's ~50 words and whatever later releases append.
    private static let bufferWords = 128
    /// A longer gap than this (the list was off) starts a fresh baseline instead of averaging over it.
    private static let maxInterval = 10.0

    private let resourceUsage: ResourceUsage?
    private let weights: EnergyWeights
    /// Mach ticks to nanoseconds.
    private let timebase: Double
    /// Reused for every coalition read; the kernel fills what it knows and leaves the rest.
    private var words = [UInt64](repeating: 0, count: bufferWords)

    /// A process never changes coalition, so each pid is asked once; exited pids drop out.
    private var coalitions: [Int32: UInt64] = [:]
    private var processNames: [Int32: String] = [:]
    private var appNames: [UInt64: (pid: Int32, name: String)] = [:]

    // The last sample, for rates.
    private var lastMetric: ProcessMetric?
    private var lastTime: UInt64 = 0
    private var lastProcessCPU: [Int32: UInt64] = [:]
    private var lastCoalitionCPU: [UInt64: UInt64] = [:]
    private var lastEnergy: [UInt64: CoalitionCounters] = [:]

    /// False when this macOS lacks the coalition interface: no energy list, and only readable processes.
    package var energyAvailable: Bool { resourceUsage != nil }

    package init() {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        timebase = Double(info.numer) / Double(info.denom)
        weights = Self.loadWeights()
        // RTLD_DEFAULT: search every loaded image (the call lives in libsystem_kernel).
        let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "coalition_info_resource_usage")
        resourceUsage = symbol.map { unsafeBitCast($0, to: ResourceUsage.self) }.flatMap(Self.ifItWorks)
    }

    /// The call, if it answers for this app's own coalition; a macOS that has it but refuses gets none.
    private static func ifItWorks(_ call: ResourceUsage) -> ResourceUsage? {
        guard let own = coalition(of: getpid()) else { return nil }
        var words = [UInt64](repeating: 0, count: bufferWords)
        return words.withUnsafeMutableBytes { call(own, $0.baseAddress!, $0.count) } == 0 ? call : nil
    }

    /// The `limit` highest rows by `metric`, highest first. CPU and energy are rates: the first call after a
    /// switch or a long gap sets the baseline and returns nothing.
    package func sample(_ metric: ProcessMetric, limit: Int) -> [ProcessUsage] {
        let now = mach_absolute_time()
        let seconds = Double(now - lastTime) * timebase / 1e9
        let continues = lastMetric == metric && lastTime > 0 && seconds <= Self.maxInterval
        lastMetric = metric
        lastTime = now
        let processes = readProcesses()
        let rows: [ProcessUsage]
        switch metric {
        case .memory:
            rows = ProcessRanking.rows(processes.map { ProcessReading(pid: $0.pid, coalition: $0.coalition, value: $0.usage.map { Double($0.footprint) }) },
                                       coalitionTotal: { self.read($0).map { Double($0[Slot.physFootprint]) } }, limit: limit)
        case .cpu:
            rows = cpuRows(processes, seconds: continues ? seconds : nil, limit: limit)
        case .energy:
            rows = energyRows(processes, seconds: continues ? seconds : nil, limit: limit)
        }
        return rows.map { row in
            var named = row
            if named.name.isEmpty { named.name = name(of: row.pid) }
            return named
        }
    }

    // MARK: - CPU

    /// %CPU (100 is one core) per readable process, and per unreadable group from its coalition's CPU time.
    private func cpuRows(_ processes: [ProcessRecord], seconds: Double?, limit: Int) -> [ProcessUsage] {
        var processCPU: [Int32: UInt64] = [:]
        var coalitionCPU: [UInt64: UInt64] = [:]
        for process in processes {
            if let usage = process.usage {
                processCPU[process.pid] = usage.cpuNanoseconds
            } else if coalitionCPU[process.coalition] == nil, let words = read(process.coalition) {
                coalitionCPU[process.coalition] = ticks(words[Slot.cpuTime])
            }
        }
        defer {
            lastProcessCPU = processCPU
            lastCoalitionCPU = coalitionCPU
        }
        guard let seconds else { return [] }
        func percent(_ now: UInt64, _ before: UInt64?) -> Double? {
            guard let before, now >= before else { return nil }
            return Double(now - before) / (seconds * 1e9) * 100
        }
        let readings = processes.map { process in
            ProcessReading(pid: process.pid, coalition: process.coalition,
                           value: process.usage.map { _ in percent(processCPU[process.pid] ?? 0, lastProcessCPU[process.pid]) ?? 0 })
        }
        return ProcessRanking.rows(readings, coalitionTotal: { coalition in
            coalitionCPU[coalition].flatMap { percent($0, self.lastCoalitionCPU[coalition]) }
        }, limit: limit)
    }

    // MARK: - Energy

    /// Activity Monitor's Energy Impact per coalition (one app with its helpers), with each one's share of all.
    private func energyRows(_ processes: [ProcessRecord], seconds: Double?, limit: Int) -> [ProcessUsage] {
        var members: [UInt64: [Int32]] = [:]
        for process in processes { members[process.coalition, default: []].append(process.pid) }
        var current: [UInt64: CoalitionCounters] = [:]
        for id in members.keys {
            if let words = read(id) { current[id] = counters(words) }
        }
        let old = lastEnergy
        lastEnergy = current
        appNames = appNames.filter { members[$0.key] != nil }
        guard let seconds else { return [] }
        let scored = current.compactMap { id, counters -> (id: UInt64, score: Double)? in
            guard let before = old[id] else { return nil }
            return (id, EnergyImpact.score(from: before, to: counters, seconds: seconds, weights: weights))
        }
        // Every coalition counts toward the whole, not just the ones listed.
        let total = scored.reduce(0) { $0 + $1.score }
        return scored.sorted { $0.score > $1.score }.prefix(limit).compactMap { entry in
            guard let app = appName(entry.id, members: members[entry.id] ?? []) else { return nil }
            return ProcessUsage(pid: app.pid, name: app.name, value: entry.score, share: EnergyImpact.share(entry.score, of: total))
        }
    }

    private func counters(_ words: [UInt64]) -> CoalitionCounters {
        let qosCount = min(Int(words[Slot.qosCount]), Slot.maxQoS)
        return CoalitionCounters(
            cpuByQoS: (0..<qosCount).map { ticks(words[Slot.qosTimes + $0]) },
            cpuTotal: ticks(words[Slot.cpuTime]),
            wakeups: words[Slot.interruptWakeups] + words[Slot.idleWakeups],
            bytesRead: words[Slot.bytesRead],
            bytesWritten: words[Slot.bytesWritten],
            gpuNanoseconds: words[Slot.gpuTime]
        )
    }

    // MARK: - Reading

    private struct Usage {
        let cpuNanoseconds: UInt64
        let footprint: UInt64
    }

    private struct ProcessRecord {
        let pid: Int32
        let coalition: UInt64
        /// Nil when this app may not read it.
        let usage: Usage?
    }

    /// Every process with its coalition, and its own usage where readable. ~1,000 processes in a few ms.
    private func readProcesses() -> [ProcessRecord] {
        // Room for a few more than exist now, in case some start between the two calls.
        var pids = [pid_t](repeating: 0, count: Int(proc_listallpids(nil, 0)) + 64)
        let count = Int(proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size)))
        var known: [Int32: UInt64] = [:]
        var processes: [ProcessRecord] = []
        processes.reserveCapacity(count)
        for pid in pids.prefix(max(0, count)) {
            guard let coalition = coalitions[pid] ?? Self.coalition(of: pid) else { continue }
            known[pid] = coalition
            processes.append(ProcessRecord(pid: pid, coalition: coalition, usage: usage(of: pid)))
        }
        coalitions = known
        processNames = processNames.filter { known[$0.key] != nil }
        return processes
    }

    private func usage(of pid: Int32) -> Usage? {
        var info = rusage_info_v4()
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { proc_pid_rusage(pid, RUSAGE_INFO_V4, $0) }
        }
        guard result == 0 else { return nil }
        return Usage(cpuNanoseconds: ticks(info.ri_user_time + info.ri_system_time), footprint: info.ri_phys_footprint)
    }

    /// A coalition's counters as raw words; nil without the interface or when refused.
    private func read(_ coalition: UInt64) -> [UInt64]? {
        guard let resourceUsage else { return nil }
        let result = words.withUnsafeMutableBytes { resourceUsage(coalition, $0.baseAddress!, $0.count) }
        return result == 0 ? words : nil
    }

    private func ticks(_ value: UInt64) -> UInt64 { UInt64(Double(value) * timebase) }

    private static func coalition(of pid: Int32) -> UInt64? {
        var ids = [UInt64](repeating: 0, count: 5)
        let size = Int32(ids.count * MemoryLayout<UInt64>.size)
        let read = ids.withUnsafeMutableBytes { proc_pidinfo(pid, pidCoalitionInfo, 0, $0.baseAddress, size) }
        return read == size && ids[0] != 0 ? ids[0] : nil
    }

    // MARK: - Names

    /// The executable's file name in full (the kernel's short name when there's no path, as for kernel_task).
    private func name(of pid: Int32) -> String {
        if let known = processNames[pid] { return known }
        let path = Self.path(pid)
        let name = path.isEmpty ? Self.command(pid) : String(path.split(separator: "/").last ?? "")
        processNames[pid] = name
        return name
    }

    /// Cached per coalition: the paths are read once, when it first ranks.
    private func appName(_ coalition: UInt64, members: [Int32]) -> (pid: Int32, name: String)? {
        if let known = appNames[coalition] { return known }
        let named = EnergyImpact.representative(of: members.map { ($0, Self.path($0)) })
            .map { ($0.pid, $0.name.isEmpty ? Self.command($0.pid) : $0.name) }
        appNames[coalition] = named
        return named
    }

    private static func path(_ pid: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return "" }
        return String(cString: buffer)
    }

    /// The kernel's short command name, readable for every process.
    private static func command(_ pid: Int32) -> String {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return "" }
        return withUnsafeBytes(of: info.kp_proc.p_comm) { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
    }

    // MARK: - Weights

    /// This Mac's coefficients (`/usr/share/pmenergy/<board-id>.plist`), else the default file, else built-in.
    private static func loadWeights() -> EnergyWeights {
        let folder = URL(fileURLWithPath: "/usr/share/pmenergy")
        let files = [boardID().map { "\($0).plist" }, "default.plist"].compactMap { $0 }
        for file in files {
            guard let data = try? Data(contentsOf: folder.appendingPathComponent(file)),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let constants = plist["energy_constants"] as? [String: NSNumber] else { continue }
            return EnergyWeights(constants: constants.mapValues(\.doubleValue))
        }
        return .standard
    }

    /// Intel Macs have a board id; Apple silicon has none and uses the default file.
    private static func boardID() -> String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        guard let data = IORegistryEntryCreateCFProperty(service, "board-id" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? Data else { return nil }
        return String(bytes: data.prefix { $0 != 0 }, encoding: .utf8)
    }
}
