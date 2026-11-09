package struct ProcessReading: Equatable, Sendable {
    package var pid: Int32
    package var coalition: UInt64
    package var value: Double?

    package init(pid: Int32, coalition: UInt64, value: Double?) {
        self.pid = pid
        self.coalition = coalition
        self.value = value
    }
}

package enum ProcessRanking {
    /// Unreadable processes are counted as their coalition's total less its readable members: exact when
    /// alone in it (most daemons), else one row "<lowest pid> + n" (WindowServer and its shader compiler).
    package static func rows(_ readings: [ProcessReading], coalitionTotal: (UInt64) -> Double?, limit: Int) -> [ProcessUsage] {
        var rows: [ProcessUsage] = []
        var readableTotals: [UInt64: Double] = [:]
        var hidden: [UInt64: [ProcessReading]] = [:]
        for reading in readings {
            if let value = reading.value {
                rows.append(ProcessUsage(pid: reading.pid, name: "", value: value))
                readableTotals[reading.coalition, default: 0] += value
            } else {
                hidden[reading.coalition, default: []].append(reading)
            }
        }
        for (coalition, members) in hidden {
            guard let total = coalitionTotal(coalition), let lead = members.min(by: { $0.pid < $1.pid }) else { continue }
            let value = max(0, total - (readableTotals[coalition] ?? 0))
            rows.append(ProcessUsage(pid: lead.pid, name: "", value: value, others: members.count - 1))
        }
        return Array(rows.sorted { $0.value > $1.value }.prefix(limit))
    }
}
