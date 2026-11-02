import AppKit

/// Type and colour of the menu-bar items: a small caption over a large value.
package enum MenuBarTheme {
    package static let captionFont = NSFont.systemFont(ofSize: 9, weight: .semibold)
    package static let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 11.5, weight: .semibold)
    /// Caption and value alike; dynamic, so it follows the menu bar's appearance.
    package static let textColor = NSColor.labelColor
    /// Space between the value's cap height and the caption's baseline.
    package static let lineGap: CGFloat = 2.5
    package static let dotDiameter: CGFloat = 6
    package static let dotGap: CGFloat = 3
    package static let warningColor = NSColor.systemYellow
    package static let criticalColor = NSColor.systemRed
}
