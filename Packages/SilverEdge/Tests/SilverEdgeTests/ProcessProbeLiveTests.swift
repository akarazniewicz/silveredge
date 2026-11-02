import XCTest
import Domain
@testable import Platform

/// Reads this Mac's real processes. Opt-in: SILVEREDGE_LIVE_PROCESSES=1.
final class ProcessProbeLiveTests: XCTestCase {
    func testListsEachMetricOnThisMac() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["SILVEREDGE_LIVE_PROCESSES"] == "1", "Set SILVEREDGE_LIVE_PROCESSES=1")
        let probe = ProcessProbe()
        let memory = probe.sample(.memory, limit: 8)
        print("— memory"); memory.forEach { print(String(format: "%8.0f MB  %@%@", $0.value / 1_048_576, $0.name, $0.others > 0 ? " + \($0.others)" : "")) }
        XCTAssertFalse(memory.isEmpty)
        XCTAssertTrue(memory.allSatisfy { !$0.name.isEmpty })
        for metric in [ProcessMetric.cpu, .energy] {
            XCTAssertTrue(probe.sample(metric, limit: 8).isEmpty, "the first rate sample is the baseline")
            Thread.sleep(forTimeInterval: 2)
            let ranked = probe.sample(metric, limit: 8)
            print("— \(metric)"); ranked.forEach { print(String(format: "%8.1f  %@%@", $0.value, $0.name, $0.others > 0 ? " + \($0.others)" : "")) }
            XCTAssertFalse(ranked.isEmpty)
            XCTAssertEqual(ranked.map(\.value), ranked.map(\.value).sorted(by: >))
        }
    }
}
