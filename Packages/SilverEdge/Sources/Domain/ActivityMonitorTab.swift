/// Activity Monitor's tabs, as its `SelectedTab` preference numbers them.
package enum ActivityMonitorTab: Int, Sendable {
    case cpu = 0
    case memory = 1
    case energy = 2

    /// The tab that shows what a list ranks by.
    package init(_ metric: ProcessMetric) {
        switch metric {
        case .cpu: self = .cpu
        case .memory: self = .memory
        case .energy: self = .energy
        }
    }
}
