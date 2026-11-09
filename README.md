# SilverEdge

An ultra-light macOS menu-bar monitor for CPU and memory.

## Menu bar
- **CPU**: total usage. A yellow dot when macOS throttles the CPU to keep it cool, red when it throttles heavily.
- **RAM**: memory used. A yellow dot at elevated memory pressure, red when critical.

Click an item for its panel; right-click for the menu (themes, Activity Monitor, quit).

## Panels
- **CPU**: usage history, per-core load, load average and uptime, GPU, fans, battery, and the top processes
  by CPU or energy.
- **RAM**: usage over the last hour, memory breakdown, memory pressure, swap and compression, and the top
  processes by memory.

Six themes, light and dark, from the right-click menu.

## Install
Requires macOS 15 or later, Apple silicon or Intel. Download the matching archive (arm64 for Apple silicon,
x86_64 for Intel) from [Releases](https://github.com/akarazniewicz/silveredge/releases/latest), unzip it, and move
SilverEdge to Applications.

SilverEdge is self-signed and not notarized by Apple. After trying to open it, use
**System Settings → Privacy & Security → Open Anyway** if macOS blocks it.
See [Apple's instructions](https://support.apple.com/en-us/102445).

## Privacy
No network requests, no telemetry. See [PRIVACY.md](PRIVACY.md).

## Build from source
Requires Xcode 26 and SwiftLint (`brew install swiftlint`).
```
make signing-identity   # once: a stable local signing identity
make run                # build and open build/SilverEdge.app
make test               # package tests
make lint               # SwiftLint, module imports, localizations
```

## License
[MPL-2.0](LICENSE)
