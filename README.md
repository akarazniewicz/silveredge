# SilverEdge

An ultra-light macOS menu-bar monitor: CPU and RAM at a glance, with a frosted panel for each —
history graphs, cores, thermal and load, GPU, memory breakdown, swap and the top processes.

- **CPU** — total usage, with a yellow dot when macOS slows the CPU to keep it cool (red when heavily).
- **RAM** — memory used, with a yellow dot at elevated memory pressure (red when critical).

Native AppKit, macOS 15+, no network, no telemetry.

## Build
```
make run          # build and open build/SilverEdge.app
make test         # package tests
make lint         # SwiftLint (brew install swiftlint), module imports, localizations
make signing-identity   # once: a stable local signing identity
```
See `AGENTS.md` for the project guide.

## License
MPL-2.0
