import AppKit
import SwiftUI
import UI

/// Shows one panel at a time under its status item. The window and its
/// SwiftUI content are built on open and released on close, so a closed
/// panel costs nothing.
@MainActor
final class PanelController {
    /// The panel shown, or nil.
    private(set) var shown: MetricStatusItem.Kind?
    /// When `shown` changes: before a panel is built (so its readers are primed) and after one closes.
    var onShow: (MetricStatusItem.Kind?) -> Void = { _ in }

    private var window: PanelWindow?
    private var monitor: Any?

    func toggle(_ kind: MetricStatusItem.Kind, palette: PanelPalette, content: () -> some View, anchor: CGRect, screen: NSScreen) {
        if shown == kind {
            close()
            return
        }
        close()
        shown = kind
        onShow(kind)
        let window = PanelWindow(palette: palette, content: content())
        window.onCancel = { [weak self] in self?.close() }
        window.setFrameOrigin(Self.origin(for: window.frame.size, below: anchor, in: screen.visibleFrame))
        window.makeKeyAndOrderFront(nil)
        window.invalidateShadow()
        self.window = window
        installMonitors()
    }

    func close() {
        guard let window else { return }
        removeMonitors()
        window.orderOut(nil)
        // Drops the hosting view now rather than whenever the window is freed.
        window.contentView = nil
        self.window = nil
        shown = nil
        onShow(nil)
    }

    /// Centred under the item, kept inside the screen's visible frame.
    static func origin(for size: CGSize, below anchor: CGRect, in visibleFrame: CGRect) -> CGPoint {
        let margin = PanelTheme.screenMargin
        let x = min(max(anchor.midX - size.width / 2, visibleFrame.minX + margin), visibleFrame.maxX - margin - size.width)
        return CGPoint(x: x.rounded(), y: (anchor.minY - PanelTheme.anchorGap - size.height).rounded())
    }

    /// Clicks in other apps close the panel. The app has no other windows, and a click on a status item is its own toggle.
    private func installMonitors() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }

    private func removeMonitors() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

/// A borderless frosted panel that takes keys (Esc) without activating the app.
private final class PanelWindow: NSPanel {
    var onCancel: () -> Void = {}

    init(palette: PanelPalette, content: some View) {
        let hosting = NSHostingView(rootView: content.environment(\.panelPalette, palette))
        let size = hosting.fittingSize
        super.init(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .statusBar
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        appearance = palette.appearance.flatMap(NSAppearance.init(named:))

        let surface = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        surface.material = palette.material
        surface.blendingMode = .behindWindow
        surface.state = .active
        surface.maskImage = Self.mask(radius: PanelTheme.cornerRadius)
        hosting.frame = surface.bounds
        hosting.autoresizingMask = [.width, .height]
        surface.addSubview(hosting)
        contentView = surface
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancel()
    }

    /// A stretchable rounded rectangle: the material's corners and the window's shadow follow it.
    private static func mask(radius: CGFloat) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}
