package struct FanStatus: Equatable, Sendable {
    package var rpm: Double
    package var minimum: Double
    package var maximum: Double

    package init(rpm: Double, minimum: Double, maximum: Double) {
        self.rpm = rpm
        self.minimum = minimum
        self.maximum = maximum
    }

    /// Apple silicon stops its fans when cool.
    package var isRunning: Bool { rpm >= 1 }

    package var fraction: Double {
        guard isRunning, maximum > minimum else { return 0 }
        return ((rpm - minimum) / (maximum - minimum)).clampedToUnit
    }
}
