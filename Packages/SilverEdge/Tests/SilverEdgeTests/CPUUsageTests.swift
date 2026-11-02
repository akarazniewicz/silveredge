import XCTest
@testable import Domain

final class CPUUsageTests: XCTestCase {
    func testSharesComeFromTheDelta() {
        let old = CPUTicks(user: 100, system: 50, idle: 800, nice: 0)
        let new = CPUTicks(user: 130, system: 60, idle: 860, nice: 0)
        let usage = CPUUsage.between(old, new)
        XCTAssertEqual(usage.user, 0.3, accuracy: 1e-9)
        XCTAssertEqual(usage.system, 0.1, accuracy: 1e-9)
        XCTAssertEqual(usage.total, 0.4, accuracy: 1e-9)
    }

    func testNiceTimeCountsAsUser() {
        let usage = CPUUsage.between(CPUTicks(user: 0, system: 0, idle: 0, nice: 0), CPUTicks(user: 10, system: 0, idle: 80, nice: 10))
        XCTAssertEqual(usage.user, 0.2, accuracy: 1e-9)
    }

    func testWrappedCounterKeepsTheDelta() {
        let old = CPUTicks(user: UInt32.max - 9, system: 0, idle: 0, nice: 0)
        let new = CPUTicks(user: 10, system: 0, idle: 20, nice: 0)
        XCTAssertEqual(CPUUsage.between(old, new).user, 0.5, accuracy: 1e-9)
    }

    func testNoElapsedTicksIsZero() {
        let ticks = CPUTicks(user: 5, system: 5, idle: 5, nice: 5)
        XCTAssertEqual(CPUUsage.between(ticks, ticks), .zero)
    }
}
