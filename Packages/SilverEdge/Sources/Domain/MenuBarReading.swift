package struct MenuBarReading: Hashable, Sendable {
    package enum Indicator: Hashable, Sendable {
        case warning
        case critical
    }

    package let percent: Int?
    package let indicator: Indicator?

    package static let placeholder = MenuBarReading(percent: nil, indicator: nil)

    package init(fraction: Double, indicator: Indicator? = nil) {
        percent = fraction.isFinite ? Int((fraction.clampedToUnit * 100).rounded()) : 0
        self.indicator = indicator
    }

    private init(percent: Int?, indicator: Indicator?) {
        self.percent = percent
        self.indicator = indicator
    }

    package var valueText: String { percent.map { "\($0)%" } ?? "–" }
}
