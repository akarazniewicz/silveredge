import AppKit
import Domain

/// Opens Activity Monitor on a tab. It has no interface for that; it restores the tab saved in its
/// `SelectedTab` preference at launch, so that's set first. A copy already running is only brought forward:
/// switching its tab would need Accessibility access.
enum ActivityMonitor {
    private static let bundleID = "com.apple.ActivityMonitor"

    static func open(_ tab: ActivityMonitorTab) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        if NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty {
            CFPreferencesSetAppValue("SelectedTab" as CFString, tab.rawValue as CFNumber, bundleID as CFString)
            CFPreferencesAppSynchronize(bundleID as CFString)
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
