import XCTest
@testable import Domain

final class FanStatusTests: XCTestCase {
    func testStoppedFanIsOffAtZero() {
        let fan = FanStatus(rpm: 0, minimum: 2_317, maximum: 7_826)
        XCTAssertFalse(fan.isRunning)
        XCTAssertEqual(fan.fraction, 0)
    }

    func testFractionIsPlaceInRange() {
        XCTAssertEqual(FanStatus(rpm: 5_000, minimum: 2_000, maximum: 8_000).fraction, 0.5, accuracy: 1e-9)
    }

    func testFractionIsClamped() {
        XCTAssertEqual(FanStatus(rpm: 9_000, minimum: 2_000, maximum: 8_000).fraction, 1)
        XCTAssertEqual(FanStatus(rpm: 1_500, minimum: 2_000, maximum: 8_000).fraction, 0)
    }

    func testUnknownRangeHasNoFraction() {
        XCTAssertEqual(FanStatus(rpm: 3_000, minimum: 0, maximum: 0).fraction, 0)
    }
}
