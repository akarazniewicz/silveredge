/// The panel themes, in menu order. Persisted by raw value.
package enum ThemeID: String, CaseIterable, Sendable {
    case frost
    case system
    case opal
    case graphitePro = "graphite-pro"
    case oneDarkPro = "one-dark-pro"
    case quartzPro = "quartz-pro"

    package static let defaultID = ThemeID.frost

    /// A saved id that no longer exists reads as the default.
    package init(saved: String?) {
        self = saved.flatMap(ThemeID.init(rawValue:)) ?? .defaultID
    }
}
