import XCTest
@testable import Domain
@testable import UI

@MainActor
final class ThemeTests: XCTestCase {
    func testSavedIdRestoresItsTheme() {
        XCTAssertEqual(ThemeID(saved: "graphite-pro"), .graphitePro)
    }

    func testUnknownOrMissingIdIsFrost() {
        XCTAssertEqual(ThemeID(saved: "retired"), .frost)
        XCTAssertEqual(ThemeID(saved: nil), .frost)
    }

    func testFrostAndSystemFollowTheSystemAppearance() {
        XCTAssertNil(PanelPalette.make(.frost).appearance)
        XCTAssertNil(PanelPalette.make(.system).appearance)
    }

    func testFixedThemesForceTheirAppearance() {
        XCTAssertEqual(PanelPalette.make(.graphitePro).appearance, .darkAqua)
        XCTAssertEqual(PanelPalette.make(.quartzPro).appearance, .aqua)
    }
}
