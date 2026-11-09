import AppKit
import Domain

@MainActor
package struct MetricItemRenderer {
    private let caption: NSAttributedString
    private let captionWidth: CGFloat
    private let usualWidth: CGFloat
    private let height = NSStatusBar.system.thickness
    private let valueBaseline: CGFloat
    private let captionBaseline: CGFloat

    package init(caption: String) {
        self.caption = NSAttributedString(string: caption, attributes: [.font: MenuBarTheme.captionFont, .foregroundColor: MenuBarTheme.textColor])
        captionWidth = self.caption.size().width
        usualWidth = max(Self.value("99%").size().width, captionWidth)
        let valueCap = MenuBarTheme.valueFont.capHeight
        let block = valueCap + MenuBarTheme.lineGap + MenuBarTheme.captionFont.capHeight
        valueBaseline = ((height - block) / 2).rounded()
        captionBaseline = valueBaseline + valueCap + MenuBarTheme.lineGap
    }

    package func image(for reading: MenuBarReading) -> NSImage {
        let (caption, captionWidth, valueBaseline, captionBaseline) = (caption, captionWidth, valueBaseline, captionBaseline)
        let value = Self.value(reading.valueText)
        let valueWidth = value.size().width
        let indicatorWidth = reading.indicator == nil ? 0 : MenuBarTheme.dotDiameter + MenuBarTheme.dotGap
        let size = NSSize(width: ceil(indicatorWidth + max(usualWidth, valueWidth)), height: height)
        let image = NSImage(size: size, flipped: false) { bounds in
            let column = bounds.width - indicatorWidth
            // Without `.usesLineFragmentOrigin`, a rect's origin is the first baseline.
            let valueX = indicatorWidth + (column - valueWidth) / 2
            value.draw(with: NSRect(x: valueX, y: valueBaseline, width: valueWidth + 1, height: 0), options: [])
            caption.draw(with: NSRect(x: indicatorWidth + (column - captionWidth) / 2, y: captionBaseline, width: captionWidth + 1, height: 0),
                         options: [])
            if let indicator = reading.indicator {
                let diameter = MenuBarTheme.dotDiameter
                let dot = NSRect(x: valueX - MenuBarTheme.dotGap - diameter,
                                 y: valueBaseline + (MenuBarTheme.valueFont.capHeight - diameter) / 2, width: diameter, height: diameter)
                (indicator == .critical ? MenuBarTheme.criticalColor : MenuBarTheme.warningColor).setFill()
                NSBezierPath(ovalIn: dot).fill()
            }
            return true
        }
        // `cacheMode = .never`: redrawn per display, so label colours follow the menu bar's appearance.
        image.cacheMode = .never
        return image
    }

    private static func value(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.font: MenuBarTheme.valueFont, .foregroundColor: MenuBarTheme.textColor])
    }
}
