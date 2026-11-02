import AppKit

/// Started by the app target's `AppEntry`. Plain AppKit: no SwiftUI scene graph to keep alive.
public enum SilverEdgeApp {
    @MainActor
    public static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}
