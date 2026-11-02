/// The internal battery, as the smart battery reports it.
package struct BatteryStatus: Equatable, Sendable {
    package var percent: Int
    package var isCharging: Bool
    package var externalPower: Bool
    package var fullyCharged: Bool
    /// Minutes to empty (on battery) or to full (charging); nil while the system is still estimating.
    package var minutesRemaining: Int?
    /// Signed: negative while discharging. Milliamps × millivolts.
    package var milliamps: Int
    package var millivolts: Int
    package var maxCapacity: Int
    package var designCapacity: Int
    package var cycles: Int
    package var celsius: Double
    /// The connected charger's rating, when it reports one.
    package var adapterWatts: Int?

    package init(percent: Int, isCharging: Bool, externalPower: Bool, fullyCharged: Bool, minutesRemaining: Int?,
                 milliamps: Int, millivolts: Int, maxCapacity: Int, designCapacity: Int, cycles: Int, celsius: Double, adapterWatts: Int?) {
        self.percent = percent
        self.isCharging = isCharging
        self.externalPower = externalPower
        self.fullyCharged = fullyCharged
        self.minutesRemaining = minutesRemaining
        self.milliamps = milliamps
        self.millivolts = millivolts
        self.maxCapacity = maxCapacity
        self.designCapacity = designCapacity
        self.cycles = cycles
        self.celsius = celsius
        self.adapterWatts = adapterWatts
    }

    /// Watts flowing out of (positive) or into (negative) the battery.
    package var dischargeWatts: Double { -Double(milliamps) * Double(millivolts) / 1_000_000 }

    /// Full-charge capacity against design, 0…1.
    package var health: Double {
        guard designCapacity > 0 else { return 0 }
        return min(1, Double(maxCapacity) / Double(designCapacity))
    }
}
