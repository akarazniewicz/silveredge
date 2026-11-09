import AppKit
import SwiftUI
import UI

@MainActor
final class PanelController {
    private(set) var shown: MetricStatusItem.Kind?
    /// Called before a panel is built, so its readers are primed, and after one closes.
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

    static func origin(for size: CGSize, below anchor: CGRect, in visibleFrame: CGRect) -> CGPoint {
        let margin = PanelTheme.screenMargin
        let x = min(max(anchor.midX - size.width / 2, visibleFrame.minX + margin), visibleFrame.maxX - margin - size.width)
        return CGPoint(x: x.rounded(), y: (anchor.minY - PanelTheme.anchorGap - size.height).rounded())
    }

    /// A global monitor sees only other apps' clicks; a click on a status item toggles on its own.
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

/// `.nonactivatingPanel`: takes Esc without activating the app or stealing focus.
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
