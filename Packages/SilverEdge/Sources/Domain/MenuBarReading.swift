/// What one menu-bar item shows. Equal readings draw the same image, so an
/// unchanged reading never redraws the item.
package struct MenuBarReading: Hashable, Sendable {
    package enum Indicator: Hashable, Sendable {
        case warning
        case critical
    }

    /// 0…100; nil before the first sample.
    package let percent: Int?
    /// Shown only while pressure (memory or thermal) is elevated.
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
