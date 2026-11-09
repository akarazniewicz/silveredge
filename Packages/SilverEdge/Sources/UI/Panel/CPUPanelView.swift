import SwiftUI
import Domain

package struct CPUPanelView: View {
    @Environment(\.panelPalette) private var palette
    let stats: LiveStats
    let actions: PanelActions

    package init(stats: LiveStats, actions: PanelActions) {
        self.stats = stats
        self.actions = actions
    }

    private var listSwitch: some View {
        Picker(L10n.tr("cpu.listMode", "Rank by"), selection: Binding(get: { stats.cpuListMetric }, set: actions.setCPUListMetric)) {
            Text(L10n.tr("cpu.listMode.cpu", "CPU")).tag(ProcessMetric.cpu)
            Text(L10n.tr("cpu.listMode.energy", "Energy")).tag(ProcessMetric.energy)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .controlSize(.mini)
        .fixedSize()
    }

    package var body: some View {
        let cpu = stats.sample?.cpu ?? .zero
        let details = stats.sample?.details
        let battery = details?.battery
        PanelContainer(actions: actions, tab: ActivityMonitorTab(stats.cpuListMetric)) {
            PanelCard(title: L10n.tr("cpu.title", "CPU"), symbol: "cpu", trailing: PanelFormat.percent(cpu.total)) {
                CPUHistoryGraph(history: stats.cpuHistory)
                    .padding(.bottom, 4)
                MeterRow(label: L10n.tr("cpu.user", "User"), value: PanelFormat.percent(cpu.user), fraction: cpu.user)
                MeterRow(label: L10n.tr("cpu.system", "System"), value: PanelFormat.percent(cpu.system), fraction: cpu.system,
                         tint: palette.system)
            }
            PanelCard(title: L10n.tr("cpu.cores", "Cores"), symbol: "square.grid.3x3") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(details?.cores ?? [], id: \.kind) { CoreBars(group: $0) }
                }
            }
            LoadThermalCard(thermal: stats.thermal, showsLowPower: stats.lowPower && battery == nil, details: details)
            if let battery {
                EnergyCard(battery: battery, lowPower: stats.lowPower)
            }
            PanelCard(title: L10n.tr("cpu.gpu", "GPU"), symbol: "rectangle.3.group",
                      trailing: details?.gpu?.utilization.map(PanelFormat.percent)) {
                let gpu = details?.gpu
                MeterRow(label: gpu?.name ?? "—", value: "", fraction: gpu?.utilization ?? 0)
                MeterRow(label: L10n.tr("gpu.memory", "Memory"), value: gpu?.memoryInUse.map(PanelFormat.bytes) ?? "—")
            }
            PanelCard(title: L10n.tr("cpu.processes", "Top Processes"), symbol: "list.number") {
                if stats.energyAvailable { listSwitch }
            } content: {
                ProcessList(processes: stats.processes, metric: stats.cpuListMetric)
            }
        }
    }
}
