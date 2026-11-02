import XCTest
@testable import Domain

final class HistoryTests: XCTestCase {
    func testKeepsOrderBeforeFull() {
        var history = History<Int>(capacity: 3)
        history.append(1)
        history.append(2)
        XCTAssertEqual(history.values, [1, 2])
    }

    func testDropsOldestOnceFull() {
        var history = History<Int>(capacity: 3)
        (1...5).forEach { history.append($0) }
        XCTAssertEqual(history.values, [3, 4, 5])
    }
}
