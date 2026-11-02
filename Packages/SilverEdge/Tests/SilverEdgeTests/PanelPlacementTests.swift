import XCTest
@testable import Shell

@MainActor
final class PanelPlacementTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    private let size = CGSize(width: 300, height: 400)

    func testCentresUnderTheItem() {
        let origin = PanelController.origin(for: size, below: CGRect(x: 500, y: 800, width: 40, height: 24), in: screen)
        XCTAssertEqual(origin.x, 370)
        XCTAssertEqual(origin.y, 394)
    }

    func testStaysInsideTheRightEdge() {
        let origin = PanelController.origin(for: size, below: CGRect(x: 960, y: 800, width: 40, height: 24), in: screen)
        XCTAssertEqual(origin.x, 1_000 - 8 - 300)
    }

    func testStaysInsideTheLeftEdge() {
        let origin = PanelController.origin(for: size, below: CGRect(x: 0, y: 800, width: 40, height: 24), in: screen)
        XCTAssertEqual(origin.x, 8)
    }
}
