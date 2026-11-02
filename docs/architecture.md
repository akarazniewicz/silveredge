# Architecture

## Sampling
- `Sampler` (Platform): one `DispatchSourceTimer` on the main queue, 20 % leeway. The reads take microseconds;
  a worker thread would cost more in wake-ups than it saves. Every 2 s; 1 s while a panel is open.
- Each tick: `host_statistics(HOST_CPU_LOAD_INFO)` (delta against the last tick → `CPUUsage`) and
  `host_statistics64(HOST_VM_INFO64)` (→ `MemoryStats`). The first sample comes after 0.5 s.
- `mach_host_self()` is taken once (`SystemReaders.host`): each call hands out a new port right.
- Memory pressure: `PressureMonitor` listens to `DispatchSource.makeMemoryPressureSource` and reads
  `kern.memorystatus_vm_pressure_level` when it fires. Never polled.
- Thermal pressure: `ThermalMonitor` registers for the `com.apple.system.thermalpressurelevel` notification
  (`OSThermalPressureLevel`: nominal, moderate, heavy, trapping, sleeping) and Low Power Mode changes. Never polled.

## CPU panel readers (only while it's open)
- `AppDelegate.syncReaders()` sets every reader from what's shown (sampling interval, CPU details, the open panel's
  `ProcessMetric` list) whenever the panel or the CPU list switch changes.
- `Sampler.startDetails()` primes per-core ticks (`host_processor_info`), brings the next tick to 0.3 s, and returns zeroed cores, so the panel is
  built at its final height; each tick then adds `CPUDetails`: per-core loads, `getloadavg` + uptime (`kern.boottime`),
  and the GPU (`GPUReader`: the IOAccelerator entry's `model` and `PerformanceStatistics`).
- Core kinds: `hw.perflevel1.logicalcpu` efficiency cores, numbered first on Apple silicon (checked on an M4 Pro:
  CPUs 0–3 carry the idle load). One kind of core (Intel) is one "All Cores" group.
- Processes: `ProcessProbe` (Platform), every 2 s on `ProcessSampler`'s utility queue while a panel shows a list —
  no `ps` or `top`. Readable processes (this user's) via `proc_pid_rusage`: exact CPU time and footprint, Activity
  Monitor's figures. The others (root, other users) via their resource coalition (`ProcessRanking`, Domain, tested):
  exact when alone in it (most daemons), else one row "<lowest pid> + n" (WindowServer + its shader compiler).
  Measured: memory matches `top` to the MB; ≈ 5–9 ms per read for ~950 processes. Names: the executable's full name.
  Opening reads at once; a rate list (CPU, energy) takes its baseline then reads again after 0.4 s, so a panel
  fills within half a second instead of after a whole 2 s interval.
- `LiveStats.cpuHistory` keeps 120 samples always (cheap), so the graph has a past when the panel opens.

## Memory figures
- Used = App (internal − purgeable) + Wired + Compressed, as Activity Monitor's "Memory Used".
- Cached = external + purgeable. Free = physical − used − cached, so the breakdown bar adds up to physical memory.
- Compression = uncompressed size of compressed pages ÷ compressor size. Swap used/total from `vm.swapusage`;
  swap in/out per second from `swapins`/`swapouts` deltas over measured time (`SwapRate`).
- `LiveStats.memoryTimeline` (`MemoryTimeline`): the last hour in 120 slots of 30 s, filled from every sample
  (closed panels included, so a panel opens with its past). Each slot: mean used fraction, the **worst** pressure level
  (macOS gives levels only — shown as steps, never a percentage) and mean swap in/out rates. Time without samples
  (sleep; the clock is `CLOCK_MONOTONIC`, which runs through it) stays as empty slots. `memoryPeak`: most used since launch.
- RAM panel: Memory (pressure level + used, hour of usage, Available = cached + free, Peak), Breakdown (stacked bar;
  each part's bar against physical memory), Memory Pressure (hour of levels, `BarGraph` capped), Swap & Compression
  (Swap Used and Compression tiles without bars — no defensible scale; swap in up / out down over the hour against
  `SwapScale.top`, never under 1 MB/s, the scale printed), Top Processes (ranked by value in `ProcessUsage.parse`:
  the probe ranks by the value shown).
- `BarGraph` (UI) draws every history graph — CPU's included: a slot per bar, stacked, mirrored or capped; filled
  shapes, one path per colour (a `Canvas` cost ≈ 130 MB of graphics memory, `docs/ui.md`).
- Status items: left click or an accessibility press (VoiceOver) opens the panel; right or Control-click, the menu.

## Menu bar
- Two `NSStatusItem`s (`MetricStatusItem`), autosaved per bundle identifier. Each shows a `MenuBarReading`;
  an equal reading is never redrawn.
- `MetricItemRenderer` (UI) draws caption over value, sized for "99%" (monospaced digits: no shift while values tick);
  wider only at 100 % and while the dot shows.
  `cacheMode = .never` so dynamic label colours follow the menu bar's appearance.
- Dots: RAM — memory pressure, yellow at warning, red at critical. CPU — thermal pressure, yellow at moderate,
  red at heavy or beyond. Hidden otherwise, taking no room.

## Panels
- Left click on an item toggles its panel; right or Control-click opens the menu. One panel at a time.
- `PanelController` (Shell) builds a borderless, non-activating `NSPanel` on open — an `NSVisualEffectView`
  (`PanelPalette.material`, rounded by a stretchable mask image) hosting the SwiftUI panel — and drops it on close.
  Placement: centred under the item, clamped to the screen's visible frame (`PanelController.origin`).
- Closes on Esc or a click in another app (a global monitor; the app has no other windows); a click on a status item is its own toggle.
- Views (`CPUPanelView`, `MemoryPanelView` in UI) read `LiveStats` (Domain, `@Observable`). The delegate stores every
  sample there; with no panel open nothing observes it.

## Energy (CPU panel's list switch)
- Battery (`BatteryReader`): the `AppleSmartBattery` registry entry — charge, charging, time left (65535 = estimating),
  instant amperage (signed, handed over unsigned) × voltage = draw, `AppleRawMaxCapacity` ÷ `DesignCapacity` = health,
  cycles, temperature, the charger's watts. Read each tick while the CPU panel is open; no battery ⇒ no card.
- Energy list (`ProcessProbe`, Platform — **the only code using the private coalition interface**): Resource coalitions
  (`coalition_info_resource_usage`, resolved with `dlsym` — missing ⇒ no probe and no switch; `PROC_PIDCOALITIONINFO`;
  the `coalition_resource_usage` layout as word slots, read into an oversized buffer). One coalition ≈ one app with
  its helpers and children, as Activity Monitor's Energy tab groups them. Reads every coalition (system ones too,
  no root) in ≈ 2 ms, every 2 s (each pid's coalition cached), only while the CPU panel shows the Energy list.
- Score (`EnergyImpact.score`, Domain, tested): Activity Monitor's Energy Impact — QoS-weighted CPU time + wake-ups +
  disk bytes (+ GPU time) with the weights in `/usr/share/pmenergy/<board-id>.plist` or `default.plist`
  (`EnergyWeights`), in 10 ms per second (one busy core ≈ 100). Network packets aren't in coalitions and aren't counted.
- Shown as each app's share of all coalitions' total (bar + %), the bar coloured by the score's own level
  (`EnergyImpact.level`: < 10 light, < 50 moderate, < 100 high, more than a core beyond); the score in the row's tooltip.
- Names: an app's main executable (exactly one `.app/Contents/MacOS/` in its path), else the lowest pid; the kernel's
  short name when there's no path (kernel_task). Cached per coalition.
- Live check: `SILVEREDGE_LIVE_PROCESSES=1 swift test --filter ProcessProbeLiveTests` prints this Mac's three lists.

## Fans (Load & Thermal)
- `FanProbe` (Platform): **the only code talking to the SMC** — `AppleSMC` user client, struct method 2, its 80-byte
  parameter block as byte offsets, keys `FNum`, `F<n>Ac`/`Mn`/`Mx` (`flt `, `fpe2`, `ui8 `, `ui16`). No root.
  Opened with the CPU panel's details and closed with them; ranges read once, then one call per fan per tick.
- `FanStatus.fraction`: place in the fan's own min–max range; Apple silicon stops fans when cool ("Off").
  One row: a bar per fan (blue, orange past 40 %, red past 75 %), the fastest one's RPM; per-fan detail in the tooltip.
- Live check: `SILVEREDGE_LIVE_FANS=1 swift test --filter FanProbeLiveTests`.
