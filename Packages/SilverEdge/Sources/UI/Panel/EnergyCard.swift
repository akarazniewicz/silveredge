import SwiftUI
import Domain

/// The battery: charge and what it's doing, then draw, health and temperature. Not shown without a battery.
struct EnergyCard: View {
    @Environment(\.panelPalette) private var palette
    let battery: BatteryStatus
    let lowPower: Bool

    var body: some View {
        PanelCard(title: L10n.tr("energy.title", "Energy"), symbol: "bolt.batteryblock") {
            if lowPower { LowPowerBadge() }
        } content: {
            VStack(alignment: .leading, spacing: 10) {
                chargeRow
                HStack(spacing: 6) {
                    StatTile(value: drawText, fraction: drawFraction, tint: battery.dischargeWatts < 0 ? palette.green : palette.accent,
                             caption: battery.dischargeWatts < 0 ? L10n.tr("energy.charging", "Charging") : L10n.tr("energy.draw", "Draw"))
                    StatTile(value: PanelFormat.percent(battery.health), fraction: battery.health,
                             tint: battery.health < 0.8 ? palette.orange : palette.green,
                             caption: L10n.tr("energy.health", "Health"))
                    StatTile(value: PanelFormat.celsius(battery.celsius), fraction: ((battery.celsius - 20) / 25).clampedToUnit,
                             tint: battery.celsius >= 40 ? palette.orange : palette.accent,
                             caption: L10n.tr("energy.cycles", "\(battery.cycles) cycles"))
                }
            }
        }
    }

    private var chargeRow: some View {
        HStack(spacing: 8) {
            LevelGauge(steps: 10, lit: Int((Double(battery.percent) / 10).rounded(.up)), color: chargeColor, segmentWidth: 8)
            Text(PanelFormat.percent(Double(battery.percent) / 100)).font(PanelTheme.valueFont)
            Spacer(minLength: 6)
            // An icon and the one figure that matters; the full sentence is the tooltip.
            HStack(spacing: 4) {
                Image(systemName: stateSymbol).foregroundStyle(battery.isCharging ? palette.green : palette.secondaryText)
                if let stateFigure {
                    Text(stateFigure).font(PanelTheme.valueFont).lineLimit(1).fixedSize()
                }
            }
            .contentShape(Rectangle())
            .help(stateText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(stateText)
    }

    private var stateSymbol: String {
        if battery.isCharging { return "bolt.fill" }
        return battery.externalPower ? "powerplug.fill" : "battery.75percent"
    }

    /// Time to full or empty; the charger's watts when plugged in and idle.
    private var stateFigure: String? {
        if battery.isCharging || !battery.externalPower {
            return remaining
        }
        return battery.fullyCharged ? nil : battery.adapterWatts.map { L10n.tr("format.wattsInteger", "\($0) W") }
    }

    /// Time to full or to empty.
    private var remaining: String? {
        battery.minutesRemaining.map { PanelFormat.duration(Double($0) * 60) }
    }

    private var chargeColor: Color {
        battery.percent <= 10 ? palette.red : battery.percent <= 20 ? palette.yellow : palette.green
    }

    /// Battery output against the charger's rating, or a laptop's typical 30 W ceiling on battery.
    private var drawFraction: Double {
        abs(battery.dischargeWatts) / Double(battery.adapterWatts ?? 30)
    }

    private var drawText: String {
        PanelFormat.watts(abs(battery.dischargeWatts))
    }

    private var stateText: String {
        if battery.isCharging {
            return remaining.map { L10n.tr("energy.toFull", "Charging · \($0) to full") } ?? L10n.tr("energy.chargingState", "Charging")
        }
        if battery.externalPower {
            if battery.fullyCharged { return L10n.tr("energy.full", "Fully charged") }
            return battery.adapterWatts.map { L10n.tr("energy.pluggedWatts", "Plugged in · \($0) W") } ?? L10n.tr("energy.plugged", "Plugged in")
        }
        return remaining.map { L10n.tr("energy.left", "On battery · \($0) left") } ?? L10n.tr("energy.onBattery", "On battery")
    }
}
