import XCTest
@testable import Domain

final class BatteryStatusTests: XCTestCase {
    private func battery(milliamps: Int = -658, millivolts: Int = 11_873, max: Int = 5_453, design: Int = 6_249) -> BatteryStatus {
        BatteryStatus(percent: 70, isCharging: false, externalPower: false, fullyCharged: false, minutesRemaining: 341,
                      milliamps: milliamps, millivolts: millivolts, maxCapacity: max, designCapacity: design,
                      cycles: 445, celsius: 30.4, adapterWatts: nil)
    }

    func testDischargingDrawIsPositiveWatts() {
        XCTAssertEqual(battery().dischargeWatts, 7.81, accuracy: 0.01)
    }

    func testChargingFlowIsNegative() {
        XCTAssertLessThan(battery(milliamps: 2_000).dischargeWatts, 0)
    }

    func testHealthIsFullChargeAgainstDesign() {
        XCTAssertEqual(battery().health, 0.873, accuracy: 0.001)
    }

    func testHealthNeverExceedsOne() {
        XCTAssertEqual(battery(max: 7_000).health, 1)
    }

    func testUnknownDesignCapacityHasNoHealth() {
        XCTAssertEqual(battery(design: 0).health, 0)
    }
}
