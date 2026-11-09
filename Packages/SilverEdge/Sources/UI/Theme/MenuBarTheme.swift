import AppKit

package enum MenuBarTheme {
    package static let captionFont = NSFont.systemFont(ofSize: 9, weight: .semibold)
    package static let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 11.5, weight: .semibold)
    package static let textColor = NSColor.labelColor
    package static let lineGap: CGFloat = 2.5
    package static let dotDiameter: CGFloat = 6
    package static let dotGap: CGFloat = 3
    package static let warningColor = NSColor.systemYellow
    package static let criticalColor = NSColor.systemRed
}
