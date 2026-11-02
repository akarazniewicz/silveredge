import XCTest
@testable import Domain

final class MemoryStatsTests: XCTestCase {
    private func stats(physical: UInt64 = 1_000 * 16_384) -> MemoryStats {
        MemoryStats(pageSize: 16_384, physical: physical, anonymous: 300, purgeable: 50,
                    external: 100, wired: 150, compressor: 100, uncompressed: 250)
    }

    func testUsedIsAppWiredAndCompressed() {
        let memory = stats()
        XCTAssertEqual(memory.app, 250 * 16_384)
        XCTAssertEqual(memory.used, 500 * 16_384)
        XCTAssertEqual(memory.usedFraction, 0.5, accuracy: 1e-9)
    }

    func testCachedIsFileBackedAndPurgeable() {
        XCTAssertEqual(stats().cached, 150 * 16_384)
    }

    func testFractionNeverExceedsOne() {
        XCTAssertEqual(stats(physical: 100 * 16_384).usedFraction, 1)
    }

    func testPurgeableAboveInternalLeavesNoAppMemory() {
        let memory = MemoryStats(pageSize: 4_096, physical: 4_096, anonymous: 1, purgeable: 2, external: 0, wired: 0, compressor: 0)
        XCTAssertEqual(memory.app, 0)
    }

    func testFreeIsWhatUsedAndCachedLeave() {
        XCTAssertEqual(stats().free, 350 * 16_384)
    }

    func testBreakdownAddsUpToPhysical() {
        let memory = stats()
        XCTAssertEqual(MemoryPart.allCases.map(memory.bytes).reduce(0, +), memory.physical)
    }

    func testCompressionRatio() {
        XCTAssertEqual(stats().compressionRatio ?? 0, 2.5, accuracy: 1e-9)
    }

    func testEmptyCompressorHasNoRatio() {
        let memory = MemoryStats(pageSize: 4_096, physical: 4_096, anonymous: 0, purgeable: 0, external: 0, wired: 0, compressor: 0)
        XCTAssertNil(memory.compressionRatio)
    }

    func testSwapRateIsBytesPerSecond() {
        let rate = SwapRate.between(MemoryStats.Swap(swappedIn: 1_000, swappedOut: 0), MemoryStats.Swap(swappedIn: 3_000, swappedOut: 500),
                                    seconds: 2)
        XCTAssertEqual(rate, SwapRate(inPerSecond: 1_000, outPerSecond: 250))
    }

    func testSwapRateNeedsElapsedTime() {
        XCTAssertNil(SwapRate.between(MemoryStats.Swap(), MemoryStats.Swap(), seconds: 0))
    }

    func testSwapCounterResetReadsZero() {
        let rate = SwapRate.between(MemoryStats.Swap(swappedIn: 5_000), MemoryStats.Swap(swappedIn: 100), seconds: 1)
        XCTAssertEqual(rate?.inPerSecond, 0)
    }

    func testAvailableIsCachedAndFree() {
        XCTAssertEqual(stats().available, 500 * 16_384)
    }

    func testPartFractionIsShareOfPhysical() {
        XCTAssertEqual(stats().fraction(.wired), 0.15, accuracy: 1e-9)
    }

    func testNoPhysicalMemoryNoFraction() {
        XCTAssertEqual(stats(physical: 0).fraction(.app), 0)
    }
}
