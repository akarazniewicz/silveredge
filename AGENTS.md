# SilverEdge — agent guide

Native macOS menu-bar CPU and memory monitor. AppKit menu bar; SwiftUI only inside panels. macOS 15+. MPL-2.0.
Canonical instructions; `CLAUDE.md` points here. Details per area in `docs/` — read the relevant one first.

## Principles
- Ultra light: always running, so near-zero idle CPU and a small, flat footprint. Measure every change (`docs/ui.md`).
- KISS: smallest change, plainest code. No speculative abstraction, options or fallbacks. Delete, don't deprecate.
- Modular: a file goes in the lowest module that has what it needs.
- Apple-like: native controls and menus, minimal.
- Private: no network, no telemetry (`PRIVACY.md`).

## Layout
```
SilverEdge.xcodeproj      thin app target: App/ (AppEntry → SilverEdgeApp.main(), icon, Info.plist, entitlements)
Packages/SilverEdge       Domain, Platform, UI, Shell + SilverEdgeTests
```
- Release: `SilverEdge.app`, `com.silveredge.app`. Debug: `SilverEdge Dev.app`, `com.silveredge.app.dev`.
- Hardened runtime, no sandbox.

```
Shell ─┬─ Platform ─→ Domain
       └─ UI ───────→ Domain
```
- `Domain`: sample values and pure logic. Foundation and Observation only.
- `Platform`: kernel, IOKit and process readers, pressure monitors, samplers. No UI.
- `UI`: theme tokens, menu-bar renderer, panel views, cards and graphs. Never Platform.
- `Shell`: app delegate, status items, panel windows. Only `Shell` imports `Platform` (`scripts/check-modules.sh`).
- Private Apple interfaces stay inside one self-contained Platform type that works without them (`ProcessProbe`, `FanProbe`).

## Rules
- Swift 5 language mode, `MainActor` default isolation. Cross-target API is `package`, never `public` (except `SilverEdgeApp`).
- Menu bar: plain AppKit, redrawn only when the shown text changes.
- Panels: window and views built on open, released on close. Readers heavier than the two kernel reads
  (per-core, processes, GPU, fans, battery) run only while their panel is open.
- No `Canvas`, no timers or `TimelineView` redrawing unchanged content. Graphs are filled shapes, one path per colour (`BarGraph`).
  Images are shrunk to their drawn size before showing (`ProcessIcons`).
- Colours: `PanelPalette` from the environment; fonts and metrics: `PanelTheme` / `MenuBarTheme`. Never hard-coded.
- No `print` / `NSLog` / `debugPrint` / `dump` (lint error). Failures → `os.Logger` at error level.
- Every user-facing string localized via `L10n.tr`: English + Polish.
- Persisted state keyed by bundle identifier, so SilverEdge and SilverEdge Dev don't collide.
- Comments: rare, short, explain why.

## Tests
- Small, one behaviour per test, deterministic. Test pure logic in `Domain`; keep it out of views and readers.
- New logic ⇒ new tests. Bug fix ⇒ a test that fails without it.
- Live tests are opt-in: `SILVEREDGE_LIVE_PROCESSES=1` reads this Mac's process lists, `SILVEREDGE_LIVE_FANS=1` its fans.

## Commands
```
make build | make build CONFIGURATION=Debug | make run | make test | make lint | make memory ARGS=…
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift build --package-path Packages/SilverEdge --scratch-path /tmp/silveredge-clt
```
- `make signing-identity` once: a stable local signing identity. Without it `make build` signs ad hoc.

## Done means
- `make test` passes, `make lint` clean, CLT build passes, `make build` with no new warnings.
- UI or long-lived change: idle CPU and memory compared before/after (`make memory ARGS=--launch`, `docs/ui.md`).
- Docs made wrong by the change are fixed in the same change.
- Don't commit or bump the version unless asked.

## Docs
`architecture.md` sampling, readers, panels, menu bar · `ui.md` resource cost and baseline · `theming.md` themes and palette · `release.md` versioning, signing, GitHub release
