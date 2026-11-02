import XCTest
@testable import Domain

final class MemoryPressureTests: XCTestCase {
    func testKernelLevelsMapToPressure() {
        XCTAssertEqual(MemoryPressure(kernelLevel: 1), .normal)
        XCTAssertEqual(MemoryPressure(kernelLevel: 2), .warning)
        XCTAssertEqual(MemoryPressure(kernelLevel: 4), .critical)
    }

    func testUnknownLevelIsNormal() {
        XCTAssertEqual(MemoryPressure(kernelLevel: 0), .normal)
    }

    func testNormalPressureHasNoIndicator() {
        XCTAssertNil(MemoryPressure.normal.indicator)
    }

    func testElevatedPressureHasItsIndicator() {
        XCTAssertEqual(MemoryPressure.warning.indicator, .warning)
        XCTAssertEqual(MemoryPressure.critical.indicator, .critical)
    }
}
