package enum ProcessMetric: String, Sendable {
    case cpu
    case memory
    case energy
}

package struct ProcessUsage: Equatable, Sendable, Identifiable {
    package var pid: Int32
    package var name: String
    package var value: Double
    package var share: Double?
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
