import SwiftUI
import Domain

/// Thermal pressure as a level gauge, the three load averages as tiles, uptime in the header.
struct LoadThermalCard: View {
    @Environment(\.panelPalette) private var palette
    let thermal: ThermalPressure
    /// The Low Power pill, when the Energy card isn't there to carry it.
    let showsLowPower: Bool
    let details: CPUDetails?

    var body: some View {
        PanelCard(title: L10n.tr("cpu.load", "Load & Thermal"), symbol: "thermometer.medium") {
            if let uptime = details.map({ PanelFormat.duration($0.load.uptime) }) {
                Label(uptime, systemImage: "clock")
                    .font(PanelTheme.captionFont)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
                    .help(L10n.tr("load.uptime", "Uptime"))
                    .accessibilityLabel("\(L10n.tr("load.uptime", "Uptime")) \(uptime)")
            }
        } content: {
            VStack(alignment: .leading, spacing: 10) {
                thermalRow
                if let fans = details?.fans, !fans.isEmpty {
                    FanRow(fans: fans)
                }
                HStack(spacing: 6) {
                    tile(L10n.tr("load.oneMinute", "1 min"), load: details?.load.one)
                    tile(L10n.tr("load.fiveMinutes", "5 min"), load: details?.load.five)
                    tile(L10n.tr("load.fifteenMinutes", "15 min"), load: details?.load.fifteen)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(L10n.tr("load.average", "Load Average"))
            }
        }
    }

    private var coreCount: Int { details?.cores.reduce(0) { $0 + $1.loads.count } ?? 0 }

    /// The bar is load per core: full when there's as much work as cores.
    private func tile(_ caption: String, load: Double?) -> some View {
        let perCore = coreCount > 0 ? (load ?? 0) / Double(coreCount) : 0
        return StatTile(value: load.map(PanelFormat.load) ?? "—",
                        fraction: perCore, tint: palette.load(perCore), caption: caption)
    }

    private var thermalRow: some View {
        HStack(spacing: 8) {
            LevelGauge(steps: 5, lit: thermal.rawValue + 1, color: palette.thermal(thermal))
            Text(PanelFormat.thermal(thermal)).font(PanelTheme.valueFont)
            Spacer(minLength: 6)
            if showsLowPower { LowPowerBadge() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L10n.tr("load.thermal", "Thermal")) \(PanelFormat.thermal(thermal))")
    }
}

/// One line for all fans: a bar each across its range, the fastest one's speed, or "Off".
private struct FanRow: View {
    @Environment(\.panelPalette) private var palette
    let fans: [FanStatus]

    var body: some View {
        let fastest = fans.max { $0.rpm < $1.rpm }
        HStack(spacing: 6) {
            Label(L10n.tr("load.fans", "Fans"), systemImage: "fan")
                .labelStyle(.titleAndIcon)
            Spacer(minLength: 6)
            ForEach(fans.indices, id: \.self) { index in
                Meter(fraction: fans[index].fraction, tint: palette.fan(fans[index].fraction), width: PanelTheme.fanMeterWidth)
                    .opacity(fans[index].isRunning ? 1 : 0.5)
            }
            Text(fastest.map { $0.isRunning ? PanelFormat.rpm($0.rpm) : L10n.tr("fans.off", "Off") } ?? "")
                .font(PanelTheme.valueFont)
                .foregroundStyle(fastest?.isRunning == true ? palette.primaryText : palette.secondaryText)
                .lineLimit(1)
                .frame(minWidth: PanelTheme.fanValueWidth, alignment: .trailing)
        }
        .contentShape(Rectangle())
        .help(details)
        .accessibilityElement(children: .combine)
        .accessibilityValue(details)
    }

    /// "Fan 1: 2 317 rpm (2 317–7 826)", one line per fan.
    private var details: String {
        fans.indices.map { index in
            let fan = fans[index]
            return L10n.tr("fans.detail", "Fan \(index + 1): \(PanelFormat.rpm(fan.rpm)) (\(PanelFormat.number(fan.minimum))–\(PanelFormat.number(fan.maximum)))")
        }
        .joined(separator: "\n")
    }
}
