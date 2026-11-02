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

## Baseline (Step 1, menu bar only; Apple silicon, Release)
| | |
|---|---|
| Footprint | 12 MB (peak 13 MB) |
| Idle CPU | ≈ 0.17 % (0.05 s of CPU per 30 s) |

## Baseline (Step 2, panels added)
| | |
|---|---|
| Footprint, no panel opened | 12–13 MB |
| Footprint after a panel has opened | ≈ 23 MB (SwiftUI loaded; stays after closing) |
| Idle CPU, panels closed | ≈ 0.19 % |

## Baseline (Step 3, CPU panel)
| | |
|---|---|
| Idle CPU, panels closed | ≈ 0.18 % (unchanged) |
| Footprint, panels closed | 14 MB |
| CPU panel open | per-core + GPU + load each second, process list every 2 s |

## Baseline (RAM panel redesign; graphs as shapes)
| | |
|---|---|
| Idle CPU, panels closed | ≈ 0.15 % |
| Footprint, never opened / after opening | 12 MB / ≈ 27 MB |
| CPU panel open | 26 MB, ≈ 2 % CPU (1 s sampling, `ps` or energy every 2 s) — before `ProcessProbe` |
| RAM panel open | 22 MB |
| Before the fix: either panel open | ≈ 160 MB (Canvas graphics memory) |

## Baseline (ProcessProbe: no `ps`/`top`)
| | |
|---|---|
| Process list read | ≈ 5–9 ms per 2 s (was `ps` ≈ 40 ms) |
| CPU panel open | 28 MB, ≈ 1.5 % CPU |
| RAM panel open | 33 MB, ≈ 2.8 % CPU (three hour graphs redrawn each second) |
| Idle, panels closed | ≈ 0.4 % with this Mac at ~13 % load (0.15 % measured earlier on a quieter Mac; idle path unchanged) |
