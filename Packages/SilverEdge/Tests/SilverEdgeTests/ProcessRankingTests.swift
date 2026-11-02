import XCTest
@testable import Domain

final class ProcessRankingTests: XCTestCase {
    private func rows(_ readings: [ProcessReading], totals: [UInt64: Double] = [:], limit: Int = 8) -> [ProcessUsage] {
        ProcessRanking.rows(readings, coalitionTotal: { totals[$0] }, limit: limit)
    }

    func testReadableProcessesAreRowsOfTheirOwn() {
        let ranked = rows([ProcessReading(pid: 10, coalition: 1, value: 5), ProcessReading(pid: 11, coalition: 1, value: 7)])
        XCTAssertEqual(ranked.map(\.pid), [11, 10])
        XCTAssertEqual(ranked.map(\.others), [0, 0])
    }

    func testRanksHighestFirst() {
        let ranked = rows([ProcessReading(pid: 1, coalition: 1, value: 1), ProcessReading(pid: 2, coalition: 2, value: 9),
                           ProcessReading(pid: 3, coalition: 3, value: 4)])
        XCTAssertEqual(ranked.map(\.value), [9, 4, 1])
    }

    func testStopsAtLimit() {
        let readings = (1...5).map { ProcessReading(pid: Int32($0), coalition: UInt64($0), value: Double($0)) }
        XCTAssertEqual(rows(readings, limit: 2).map(\.pid), [5, 4])
    }

    func testDaemonAloneInItsCoalitionTakesTheWholeTotal() {
        let ranked = rows([ProcessReading(pid: 329, coalition: 7, value: nil)], totals: [7: 300])
        XCTAssertEqual(ranked.first?.value, 300)
        XCTAssertEqual(ranked.first?.others, 0)
    }

    func testReadableMembersAreSubtractedFromTheCoalition() {
        let ranked = rows([ProcessReading(pid: 1, coalition: 7, value: 40), ProcessReading(pid: 2, coalition: 7, value: nil)], totals: [7: 100])
        XCTAssertEqual(ranked.first { $0.pid == 2 }?.value, 60)
    }

    func testSharedUnreadablesAreOneRowNamedByLowestPid() {
        let ranked = rows([ProcessReading(pid: 900, coalition: 7, value: nil), ProcessReading(pid: 70, coalition: 7, value: nil)],
                          totals: [7: 2_000])
        XCTAssertEqual(ranked.count, 1)
        XCTAssertEqual(ranked.first?.pid, 70)
        XCTAssertEqual(ranked.first?.others, 1)
    }

    func testCoalitionWithoutATotalIsLeftOut() {
        XCTAssertTrue(rows([ProcessReading(pid: 5, coalition: 9, value: nil)]).isEmpty)
    }

    func testOvercountedReadablesNeverMakeANegativeRow() {
        let ranked = rows([ProcessReading(pid: 1, coalition: 7, value: 120), ProcessReading(pid: 2, coalition: 7, value: nil)], totals: [7: 100])
        XCTAssertEqual(ranked.first { $0.pid == 2 }?.value, 0)
    }
}
