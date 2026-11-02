import XCTest
@testable import Domain

final class EnergyImpactTests: XCTestCase {
    private func counters(qos: [UInt64] = [], cpu: UInt64 = 0, wakeups: UInt64 = 0, read: UInt64 = 0) -> CoalitionCounters {
        CoalitionCounters(cpuByQoS: qos, cpuTotal: cpu, wakeups: wakeups, bytesRead: read, bytesWritten: 0, gpuNanoseconds: 0)
    }

    func testOneBusyCoreReadsOneHundred() {
        let score = EnergyImpact.score(from: counters(cpu: 0), to: counters(cpu: 1_000_000_000), seconds: 1, weights: .standard)
        XCTAssertEqual(score, 100, accuracy: 1e-9)
    }

    func testBackgroundQoSWeighsLess() {
        let old = counters(qos: [0, 0, 0, 0, 0, 0, 0])
        let new = counters(qos: [0, 0, 1_000_000_000, 0, 0, 0, 0])
        XCTAssertEqual(EnergyImpact.score(from: old, to: new, seconds: 1, weights: .standard), 80, accuracy: 1e-9)
    }

    func testWakeupsCountAsCPUTime() {
        // 5,000 wakeups × 0.2 ms = 1 s of CPU-equivalent over 10 s → 10.
        let score = EnergyImpact.score(from: counters(), to: counters(wakeups: 5_000), seconds: 10, weights: .standard)
        XCTAssertEqual(score, 10, accuracy: 1e-9)
    }

    func testDiskReadsCount() {
        let score = EnergyImpact.score(from: counters(), to: counters(read: 1_000_000_000), seconds: 1, weights: .standard)
        XCTAssertEqual(score, 45, accuracy: 1e-9)
    }

    func testFallsBackToTotalCPUWithoutQoSSplit() {
        let score = EnergyImpact.score(from: counters(cpu: 0), to: counters(cpu: 500_000_000), seconds: 1, weights: .standard)
        XCTAssertEqual(score, 50, accuracy: 1e-9)
    }

    func testCounterGoingBackCountsNothing() {
        XCTAssertEqual(EnergyImpact.score(from: counters(cpu: 10), to: counters(cpu: 5), seconds: 1, weights: .standard), 0)
    }

    func testNoElapsedTimeIsZero() {
        XCTAssertEqual(EnergyImpact.score(from: counters(), to: counters(cpu: 10), seconds: 0, weights: .standard), 0)
    }

    func testWeightsReadFromConstants() {
        let weights = EnergyWeights(constants: ["kcpu_wakeups": 0.0005, "kqos_background": 0.5])
        XCTAssertEqual(weights.wakeup, 0.0005)
        XCTAssertEqual(weights.qos[1], 0.5)
        XCTAssertEqual(weights.qos[2], 0.5)
        XCTAssertEqual(weights.cpuTime, EnergyWeights.standard.cpuTime)
    }

    func testAppMainExecutableNamesTheCoalition() {
        let named = EnergyImpact.representative(of: [
            (pid: 50, path: "/Applications/iTerm.app/Contents/MacOS/iTerm2"),
            (pid: 10, path: "/usr/bin/login"),
            (pid: 60, path: "/Applications/iTerm.app/Contents/Frameworks/Helper.app/Contents/MacOS/Helper")
        ])
        XCTAssertEqual(named?.pid, 50)
        XCTAssertEqual(named?.name, "iTerm2")
    }

    func testWithoutAnAppTheLowestPidNamesIt() {
        let named = EnergyImpact.representative(of: [(pid: 400, path: "/usr/sbin/b"), (pid: 300, path: "/usr/libexec/a")])
        XCTAssertEqual(named?.name, "a")
    }

    func testNoMembersNoName() {
        XCTAssertNil(EnergyImpact.representative(of: []))
    }

    func testLevelsByScore() {
        XCTAssertEqual(EnergyImpact.level(3), .light)
        XCTAssertEqual(EnergyImpact.level(10), .moderate)
        XCTAssertEqual(EnergyImpact.level(60), .high)
        XCTAssertEqual(EnergyImpact.level(100), .extreme)
    }

    func testShareOfTotal() {
        XCTAssertEqual(EnergyImpact.share(25, of: 100), 0.25)
    }

    func testNothingRanHasNoShare() {
        XCTAssertEqual(EnergyImpact.share(0, of: 0), 0)
    }
}
