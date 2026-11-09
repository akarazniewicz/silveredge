import AppKit
import Domain
import Platform
import SwiftUI
import UI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let cpuItem = MetricStatusItem(kind: .cpu)
    private let memoryItem = MetricStatusItem(kind: .memory)
    private let sampler = Sampler()
    private let processSampler = ProcessSampler()
    private let processProbe = ProcessProbe()
    private let stats = LiveStats()
    private let panels = PanelController()
    private var pressureMonitor: PressureMonitor?
    private var thermalMonitor: ThermalMonitor?
    private var theme = ThemeID(saved: UserDefaults.standard.string(forKey: AppDelegate.themeKey)) {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.themeKey) }
    }

    private static let themeKey = "appearance.theme"
    private static let cpuListKey = "cpu.listMode"

    func applicationDidFinishLaunching(_ notification: Notification) {
        cpuItem.install()
        memoryItem.install()
        pressureMonitor = PressureMonitor { [weak self] level in
            self?.stats.pressure = level
            self?.showMemory()
        }
        stats.pressure = pressureMonitor?.level ?? .normal
        thermalMonitor = ThermalMonitor { [weak self] in self?.thermalChanged() }
        thermalChanged()
        sampler.onSample = { [weak self] sample in
            guard let self else { return }
            stats.sample = sample
            stats.cpuHistory.append(sample.cpu)
            stats.memoryTimeline.add(usedFraction: sample.memory.usedFraction, pressure: stats.pressure,
                                     swapRate: sample.swapRate, at: sample.time)
            stats.memoryPeak = max(stats.memoryPeak, sample.memory.used)
            showCPU()
            showMemory()
        }
        sampler.start()
        processSampler.onUpdate = { [weak self] in self?.stats.processes = $0 }
        stats.energyAvailable = processProbe.energyAvailable
        if processProbe.energyAvailable, UserDefaults.standard.string(forKey: Self.cpuListKey) == ProcessMetric.energy.rawValue {
            stats.cpuListMetric = .energy
        }
        installPanels()
    }

    private func installPanels() {
        let actions = PanelActions(openActivityMonitor: { [weak self] tab in
            self?.panels.close()
            ActivityMonitor.open(tab)
        }, quit: { NSApp.terminate(nil) }, setCPUListMetric: { [weak self] metric in
            guard let self, metric != stats.cpuListMetric else { return }
            stats.cpuListMetric = metric
            UserDefaults.standard.set(metric.rawValue, forKey: Self.cpuListKey)
            syncReaders()
        })
        cpuItem.onOpen = { [weak self] in
            guard let self else { return }
            toggle(cpuItem) { CPUPanelView(stats: self.stats, actions: actions) }
        }
        memoryItem.onOpen = { [weak self] in
            guard let self else { return }
            toggle(memoryItem) { MemoryPanelView(stats: self.stats, actions: actions) }
        }
        panels.onShow = { [weak self] _ in self?.syncReaders() }
        for item in [cpuItem, memoryItem] {
            item.theme = { [weak self] in self?.theme ?? .defaultID }
            item.onTheme = { [weak self] in self?.theme = $0 }
        }
    }

    private func syncReaders() {
        let shown = panels.shown
        sampler.interval = shown == nil ? 2 : 1
        if shown == .cpu {
            if stats.sample?.details == nil { stats.sample?.details = sampler.startDetails() }
        } else {
            sampler.stopDetails()
            stats.sample?.details = nil
        }
        stats.processes = []
        let limit = PanelTheme.processRows
        let metric: ProcessMetric? = switch shown {
        case .cpu: stats.cpuListMetric
        case .memory: .memory
        case nil: nil
        }
        if let metric {
            let probe = processProbe
            processSampler.start(every: 2) { probe.sample(metric, limit: limit) }
        } else {
            processSampler.stop()
        }
    }

    private func toggle(_ item: MetricStatusItem, content: () -> some View) {
        guard let anchor = item.anchorFrame else { return }
        panels.toggle(item.kind, palette: PanelPalette.make(theme), content: content, anchor: anchor.frame, screen: anchor.screen)
    }

    private func thermalChanged() {
        stats.thermal = thermalMonitor?.pressure ?? .nominal
        stats.lowPower = thermalMonitor?.lowPower ?? false
        showCPU()
    }

    private func showCPU() {
        guard let cpu = stats.sample?.cpu else { return }
        cpuItem.show(MenuBarReading(fraction: cpu.total, indicator: stats.thermal.indicator))
    }

    private func showMemory() {
        guard let memory = stats.sample?.memory else { return }
        memoryItem.show(MenuBarReading(fraction: memory.usedFraction, indicator: stats.pressure.indicator))
    }
}
