extension Double {
    /// Clamped to 0…1, for fractions that drive bars and percentages.
    package var clampedToUnit: Double { Swift.min(Swift.max(self, 0), 1) }
}
