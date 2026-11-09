extension Double {
    package var clampedToUnit: Double { Swift.min(Swift.max(self, 0), 1) }
}
