import XCTest
@testable import Domain

final class MemoryTimelineTests: XCTestCase {
    private func add(_ timeline: inout MemoryTimeline, _ used: Double, _ pressure: MemoryPressure = .normal, swapIn: Double = 0, at time: Double) {
        timeline.add(usedFraction: used, pressure: pressure, swapRate: SwapRate(inPerSecond: swapIn, outPerSecond: 0), at: time)
    }

    func testSamplesInOneSlotAverage() {
        var timeline = MemoryTimeline()
        add(&timeline, 0.4, at: 0)
        add(&timeline, 0.6, at: 10)
        XCTAssertEqual(timeline.slots.count, 1)
        XCTAssertEqual(timeline.slots[0]?.usedFraction ?? 0, 0.5, accuracy: 1e-9)
    }

    func testSlotKeepsItsWorstPressure() {
        var timeline = MemoryTimeline()
        add(&timeline, 0.5, .warning, at: 0)
        add(&timeline, 0.5, .normal, at: 5)
        XCTAssertEqual(timeline.slots[0]?.pressure, .warning)
    }

    func testSwapRatesAverage() {
        var timeline = MemoryTimeline()
        add(&timeline, 0.5, swapIn: 100, at: 0)
        add(&timeline, 0.5, swapIn: 300, at: 1)
        XCTAssertEqual(timeline.slots[0]?.swapIn ?? 0, 200, accuracy: 1e-9)
    }

    func testNextSlotStartsAfterThirtySeconds() {
        var timeline = MemoryTimeline()
        add(&timeline, 0.4, at: 0)
        add(&timeline, 0.8, at: 31)
        XCTAssertEqual(timeline.slots.map { $0?.usedFraction }, [0.4, 0.8])
    }

    func testTimeWithoutSamplesStaysEmpty() {
        var timeline = MemoryTimeline()
        add(&timeline, 0.4, at: 0)
        add(&timeline, 0.8, at: 95)
        XCTAssertEqual(timeline.slots.map { $0?.usedFraction }, [0.4, nil, nil, 0.8])
    }

    func testKeepsOnlyAnHour() {
        var timeline = MemoryTimeline()
        for slot in 0..<200 { add(&timeline, Double(slot) / 200, at: Double(slot) * 30) }
        XCTAssertEqual(timeline.slots.count, MemoryTimeline.slotCount)
        XCTAssertEqual(timeline.slots.last??.usedFraction ?? 0, 199.0 / 200, accuracy: 1e-9)
    }

    func testLongSleepLeavesAnEmptyHourThenTheNewSlot() {
        var timeline = MemoryTimeline()
        add(&timeline, 0.4, at: 0)
        add(&timeline, 0.8, at: 10 * 3_600)
        XCTAssertEqual(timeline.slots.count, MemoryTimeline.slotCount)
        XCTAssertEqual(timeline.slots.compactMap { $0 }.map(\.usedFraction), [0.8])
    }

    func testSwapScaleNeverBelowOneMegabytePerSecond() {
        XCTAssertEqual(SwapScale.top(of: [MemorySlot(usedFraction: 0, pressure: .normal, swapIn: 2_000, swapOut: 0)]), 1_048_576)
    }

    func testSwapScaleFollowsTheBusiestSlot() {
        let slots: [MemorySlot?] = [nil, MemorySlot(usedFraction: 0, pressure: .normal, swapIn: 1_000, swapOut: 9_000_000)]
        XCTAssertEqual(SwapScale.top(of: slots), 9_000_000)
    }

    func testPressureOrdersBySeverity() {
        XCTAssertEqual(max(MemoryPressure.critical, .warning), .critical)
    }
}
