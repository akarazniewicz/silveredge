import XCTest
@testable import Domain

final class ClampTests: XCTestCase {
    func testClampsToUnit() {
        XCTAssertEqual((-0.5).clampedToUnit, 0)
        XCTAssertEqual(0.4.clampedToUnit, 0.4)
        XCTAssertEqual(1.7.clampedToUnit, 1)
    }

    func testEachListOpensItsActivityMonitorTab() {
        XCTAssertEqual(ActivityMonitorTab(.cpu), .cpu)
        XCTAssertEqual(ActivityMonitorTab(.memory), .memory)
        XCTAssertEqual(ActivityMonitorTab(.energy), .energy)
    }
}
