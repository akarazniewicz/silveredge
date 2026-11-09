# UI

## Resource cost — check before adding anything
- Always running: every feature costs CPU, memory or battery. Justify it; small beats complete.
- Menu bar: AppKit only, no SwiftUI. Redraw only when the shown text changes.
- Panels: window and views built on open, released on close. Heavier readers run only while their panel is open.
- No timers or `TimelineView` redrawing unchanged content.
- No SwiftUI `Canvas` in panels: one 280 × 40 pt history graph held ≈ 130 MB of graphics memory while open
  (measured). Graphs are filled shapes, one path per colour (`BarGraph`).
- App icons are shrunk once to a 32 px bitmap (`ProcessIcons`); drawn as is, each goes to the GPU at full size.
- Measure: `make memory ARGS=--launch`, and idle CPU as process CPU time over a minute (`ps -o time`).

## Baseline (Apple silicon, Release)
| | |
|---|---|
| Idle CPU, panels closed | ≈ 0.15 % |
| Footprint, no panel opened yet | 12 MB |
| Footprint after a panel has opened | ≈ 27 MB (SwiftUI stays loaded after closing) |
| CPU panel open | 28 MB, ≈ 1.5 % CPU |
| RAM panel open | 33 MB, ≈ 2.8 % CPU (three hour graphs redrawn each second) |
| Process list read | ≈ 5–9 ms every 2 s |
