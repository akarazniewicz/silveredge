import XCTest
@testable import Domain

final class ThermalPressureTests: XCTestCase {
    func testNotifyStatesMapToLevels() {
        XCTAssertEqual(ThermalPressure(notifyState: 0), .nominal)
        XCTAssertEqual(ThermalPressure(notifyState: 1), .moderate)
        XCTAssertEqual(ThermalPressure(notifyState: 2), .heavy)
        XCTAssertEqual(ThermalPressure(notifyState: 4), .sleeping)
    }

    func testUnknownStateIsNominal() {
        XCTAssertEqual(ThermalPressure(notifyState: 40), .nominal)
    }

    func testNominalHasNoIndicator() {
        XCTAssertNil(ThermalPressure.nominal.indicator)
    }

    func testModerateIsAWarning() {
        XCTAssertEqual(ThermalPressure.moderate.indicator, .warning)
    }

    func testHeavyAndBeyondAreCritical() {
        XCTAssertEqual(ThermalPressure.heavy.indicator, .critical)
        XCTAssertEqual(ThermalPressure.trapping.indicator, .critical)
        XCTAssertEqual(ThermalPressure.sleeping.indicator, .critical)
    }
}
