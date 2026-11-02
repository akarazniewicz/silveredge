/// One fan: its speed and the range the system drives it in.
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

    /// How far into its range it's spinning, 0…1; 0 when stopped.
    package var fraction: Double {
        guard isRunning, maximum > minimum else { return 0 }
        return ((rpm - minimum) / (maximum - minimum)).clampedToUnit
    }
}
