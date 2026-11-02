import SwiftUI

/// The panels' metrics and type; colours come from the theme (`PanelPalette`).
package enum PanelTheme {
    package static let width: CGFloat = 300
    package static let cornerRadius: CGFloat = 16
    /// Gap between the status item and the panel's top edge.
    package static let anchorGap: CGFloat = 6
    /// Minimum distance from the screen's visible edges.
    package static let screenMargin: CGFloat = 8

    static let padding: CGFloat = 10
    static let cardSpacing: CGFloat = 8
    static let cardRadius: CGFloat = 11
    static let cardPadding = EdgeInsets(top: 9, leading: 12, bottom: 11, trailing: 12)

    static let headerFont = Font.system(size: 11, weight: .medium)
    static let rowFont = Font.system(size: 13)
    static let valueFont = Font.system(size: 13, weight: .medium).monospacedDigit()
    static let headlineFont = Font.system(size: 15, weight: .semibold).monospacedDigit()
    static let rowSpacing: CGFloat = 4

    static let meterWidth: CGFloat = 96
    static let meterHeight: CGFloat = 4

    static let graphHeight: CGFloat = 40
    static let graphBarGap: CGFloat = 0.5
    static let pressureGraphHeight: CGFloat = 26
    static let swapGraphHeight: CGFloat = 32
    static let axisFont = Font.system(size: 9.5, weight: .medium)
    static let coreBarHeight: CGFloat = 26
    static let coreBarSpacing: CGFloat = 3
    /// Rows in a process list; the readers are asked for as many.
    package static let processRows = 8
    static let iconSize: CGFloat = 16
    static let shareMeterWidth: CGFloat = 70
    static let placeholderBarHeight: CGFloat = 8
    static let placeholderValueWidth: CGFloat = 36
    /// Fits "100%", so the bars line up.
    static let shareValueWidth: CGFloat = 38

    static let tileRadius: CGFloat = 8
    static let captionFont = Font.system(size: 10.5, weight: .medium)
    static let gaugeSegmentWidth: CGFloat = 14
    static let gaugeSegmentHeight: CGFloat = 5

    static let fanMeterWidth: CGFloat = 34
    /// Fits "7 826 rpm", so the bars stay put as speeds change.
    static let fanValueWidth: CGFloat = 76

    static let breakdownHeight: CGFloat = 10
    static let legendDot: CGFloat = 7
    static let badgePadding = CGSize(width: 7, height: 2)
    static let partMeterWidth: CGFloat = 58

    static let footerIconSize: CGFloat = 14
}
