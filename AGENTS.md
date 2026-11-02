# SilverEdge — agent guide

Native macOS menu-bar CPU and memory monitor. AppKit first; SwiftUI only inside panels (cards, shape-drawn graphs — never `Canvas`, `docs/ui.md`). macOS 15+. MPL-2.0.
Canonical instructions; `CLAUDE.md` points here. Details per area in `docs/`.

## Principles
- Ultra light: always running, so near-zero idle CPU and a small, flat footprint. The menu bar is plain AppKit. Panels exist only while open.
  Anything heavier than the two kernel reads (per-core, processes, GPU) runs only while its panel is open. Measure every change (`docs/ui.md`).
- KISS: smallest change, plainest code. No speculative abstraction, options or fallbacks. Delete, don't deprecate.
- Modular: a file goes in the lowest module that has what it needs.
- Apple-like: native controls and menus, minimal.
- Private: no network, no telemetry (`PRIVACY.md`).
- Private Apple interfaces stay inside one self-contained Platform type that degrades without them (`ProcessProbe`, `FanProbe`).

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
- `Platform`: kernel/IOKit/process readers, pressure monitor, sampler. No UI.
- `UI`: theme tokens, menu-bar renderer, panel views, cards and graphs. Never Platform.
- `Shell`: app delegate, status items, panel windows. Only `Shell` imports `Platform`.

## Rules
- Cross-target API is `package`, never `public` (except `SilverEdgeApp`).
- Colours: `PanelPalette` from the environment; fonts and metrics: `PanelTheme` / `MenuBarTheme`. Never hard-coded.
- No `print` / `NSLog` / `debugPrint` / `dump` (lint error). Failures → `os.Logger` at error level.
- Every user-facing string localized via `L10n.tr`: English + Polish.
- Persisted state must not collide between SilverEdge and SilverEdge Dev (key by bundle identifier).
- Comments: rare, short, explain why.

## Tests
- Small, one behaviour per test, deterministic. Test pure logic in `Domain` — keep it out of views and readers.
- New logic ⇒ new tests. Bug fix ⇒ a test that fails without it.
- Live tests are opt-in: `SILVEREDGE_LIVE_PROCESSES=1` reads this Mac's process lists, `SILVEREDGE_LIVE_FANS=1` its fans.

## Commands
```
make build | make build CONFIGURATION=Debug | make run | make test | make lint | make memory ARGS=…
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift build --package-path Packages/SilverEdge --scratch-path /tmp/silveredge-clt
```

## Done means
- `make test` passes, `make lint` clean, CLT build passes, `make build` with no new warnings.
- Long-lived or UI change: idle CPU and memory compared before/after (`docs/ui.md`).
- Docs made wrong by the change are fixed in the same change.
- Don't commit or bump the version unless asked.

## Docs
`architecture.md` sampling, readers, panels · `ui.md` resource cost and baselines · `theming.md` themes and palette
