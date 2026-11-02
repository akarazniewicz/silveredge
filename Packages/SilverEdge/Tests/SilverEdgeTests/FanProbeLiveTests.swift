import XCTest
@testable import Platform

/// Reads this Mac's real fans. Opt-in: SILVEREDGE_LIVE_FANS=1.
@MainActor
final class FanProbeLiveTests: XCTestCase {
    func testReadsFansWithTheirRanges() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["SILVEREDGE_LIVE_FANS"] == "1", "Set SILVEREDGE_LIVE_FANS=1")
        let fans = try XCTUnwrap(FanProbe()).read()
        fans.forEach { print("fan: \($0.rpm) rpm (\($0.minimum)–\($0.maximum))") }
        XCTAssertFalse(fans.isEmpty)
        XCTAssertTrue(fans.allSatisfy { $0.maximum > $0.minimum })
    }
}
