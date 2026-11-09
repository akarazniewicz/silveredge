import AppKit
import Domain
import UI

@MainActor
final class MetricStatusItem: NSObject {
    enum Kind: String {
        case cpu
        case memory

        var caption: String {
            switch self {
            case .cpu: L10n.tr("menuBar.cpu", "CPU")
            case .memory: L10n.tr("menuBar.memory", "RAM")
            }
        }
    }

    var onOpen: () -> Void = {}
    var theme: () -> ThemeID = { .defaultID }
    var onTheme: (ThemeID) -> Void = { _ in }

    let kind: Kind
    private let renderer: MetricItemRenderer
    private var statusItem: NSStatusItem?
    private var reading: MenuBarReading?

    init(kind: Kind) {
        self.kind = kind
        renderer = MetricItemRenderer(caption: kind.caption)
    }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "\(Bundle.main.bundleIdentifier ?? "com.silveredge.app").status.\(kind.rawValue)"
        if let button = item.button {
            button.imageScaling = .scaleNone
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        show(.placeholder)
    }

    func show(_ reading: MenuBarReading) {
        guard reading != self.reading, let button = statusItem?.button else { return }
        self.reading = reading
        button.image = renderer.image(for: reading)
        button.setAccessibilityLabel(accessibilityLabel(for: reading))
    }

    private func accessibilityLabel(for reading: MenuBarReading) -> String {
        let caption = kind.caption
        guard let percent = reading.percent else { return caption }
        let value = L10n.tr("menuBar.accessibility.value", "\(caption) \(percent) percent")
        switch reading.indicator {
        case nil: return value
        case .warning where kind == .cpu: return L10n.tr("menuBar.accessibility.thermalWarning", "\(value), CPU throttled by heat")
        case .critical where kind == .cpu: return L10n.tr("menuBar.accessibility.thermalCritical", "\(value), CPU heavily throttled by heat")
        case .warning: return L10n.tr("menuBar.accessibility.pressureWarning", "\(value), memory pressure elevated")
        case .critical: return L10n.tr("menuBar.accessibility.pressureCritical", "\(value), memory pressure critical")
        }
    }

    var anchorFrame: (frame: CGRect, screen: NSScreen)? {
        guard let button = statusItem?.button, let window = button.window, let screen = window.screen else { return nil }
        return (window.convertToScreen(button.convert(button.bounds, to: nil)), screen)
    }

    // MARK: - Clicks

    /// An accessibility press (VoiceOver) comes with no `NSApp.currentEvent`: treat it as a left click.
    @objc private func clicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            onOpen()
        }
    }

    private func showMenu() {
        guard let button = statusItem?.button else { return }
        let menu = NSMenu()
        menu.addItem(withTitle: L10n.tr("menu.openActivityMonitor", "Open Activity Monitor"),
                     action: #selector(openActivityMonitor), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(themeItem())
        menu.addItem(.separator())
        menu.addItem(withTitle: L10n.tr("menu.quit", "Quit SilverEdge"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    private func themeItem() -> NSMenuItem {
        let item = NSMenuItem(title: L10n.tr("menu.theme", "Theme"), action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let current = theme()
        for id in ThemeID.allCases {
            let choice = submenu.addItem(withTitle: Self.title(id), action: #selector(chooseTheme(_:)), keyEquivalent: "")
            choice.target = self
            choice.representedObject = id.rawValue
            choice.state = id == current ? .on : .off
        }
        item.submenu = submenu
        return item
    }

    @objc private func chooseTheme(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let id = ThemeID(rawValue: raw) else { return }
        onTheme(id)
    }

    private static func title(_ id: ThemeID) -> String {
        switch id {
        case .frost: L10n.tr("theme.frost", "Frost")
        case .system: L10n.tr("theme.system", "System")
        case .opal: L10n.tr("theme.opal", "Opal")
        case .graphitePro: L10n.tr("theme.graphitePro", "Graphite Pro")
        case .oneDarkPro: L10n.tr("theme.oneDarkPro", "One Dark Pro")
        case .quartzPro: L10n.tr("theme.quartzPro", "Quartz Pro")
        }
    }

    @objc private func openActivityMonitor() {
        ActivityMonitor.open(kind == .cpu ? .cpu : .memory)
    }
}
