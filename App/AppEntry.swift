import Shell

/// The app: everything lives in the `Shell` module of `Packages/SilverEdge`;
/// this target only starts it and carries what makes it an app — the icon
/// (`Assets.xcassets`), `Info.plist` and the entitlements.
@main
enum AppEntry {
    static func main() {
        SilverEdgeApp.main()
    }
}
