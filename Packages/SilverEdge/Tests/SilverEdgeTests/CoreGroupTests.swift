import XCTest
@testable import Domain

final class CoreGroupTests: XCTestCase {
    func testEfficiencyCoresComeFirstInCPUOrder() {
        let groups = CoreGroup.groups(loads: [0.1, 0.2, 0.5, 0.6, 0.7], efficiencyCount: 2)
        XCTAssertEqual(groups, [CoreGroup(kind: .performance, loads: [0.5, 0.6, 0.7]), CoreGroup(kind: .efficiency, loads: [0.1, 0.2])])
    }

    func testOneKindOfCoreIsOneGroup() {
        XCTAssertEqual(CoreGroup.groups(loads: [0.1, 0.3], efficiencyCount: 0), [CoreGroup(kind: .uniform, loads: [0.1, 0.3])])
    }

    func testAverage() {
        XCTAssertEqual(CoreGroup(kind: .uniform, loads: [0.2, 0.4]).average, 0.3, accuracy: 1e-9)
    }

    func testNoCoresAverageZero() {
        XCTAssertEqual(CoreGroup(kind: .uniform, loads: []).average, 0)
    }
}
