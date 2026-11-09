package enum ThemeID: String, CaseIterable, Sendable {
    case frost
    case system
    case opal
    case graphitePro = "graphite-pro"
    case oneDarkPro = "one-dark-pro"
    case quartzPro = "quartz-pro"

    package static let defaultID = ThemeID.frost

    package init(saved: String?) {
        self = saved.flatMap(ThemeID.init(rawValue:)) ?? .defaultID
    }
}
