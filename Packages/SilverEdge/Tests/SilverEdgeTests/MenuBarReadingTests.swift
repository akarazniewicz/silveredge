import XCTest
@testable import Domain

final class MenuBarReadingTests: XCTestCase {
    func testFractionRoundsToWholePercent() {
        XCTAssertEqual(MenuBarReading(fraction: 0.205).valueText, "21%")
    }

    func testFractionIsClamped() {
        XCTAssertEqual(MenuBarReading(fraction: 1.4).percent, 100)
        XCTAssertEqual(MenuBarReading(fraction: -0.2).percent, 0)
    }

    func testNotANumberReadsZero() {
        XCTAssertEqual(MenuBarReading(fraction: .nan).percent, 0)
    }

    func testPlaceholderHasNoValue() {
        XCTAssertEqual(MenuBarReading.placeholder.valueText, "–")
    }

    func testNoIndicatorByDefault() {
        XCTAssertNil(MenuBarReading(fraction: 0.9).indicator)
    }

    func testDifferentIndicatorIsADifferentReading() {
        XCTAssertNotEqual(MenuBarReading(fraction: 0.9), MenuBarReading(fraction: 0.9, indicator: .warning))
    }

    func testSameRoundedValueIsEqual() {
        XCTAssertEqual(MenuBarReading(fraction: 0.201), MenuBarReading(fraction: 0.204))
    }
}
