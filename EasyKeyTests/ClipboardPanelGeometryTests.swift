@testable import EasyKey
import XCTest

final class ClipboardPanelGeometryTests: XCTestCase {
    private let panel = CGSize(width: 420, height: 500)

    func testOffsetsBelowRightOfCursorInMiddleOfScreen() {
        let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = clipboardPanelOrigin(mouseLocation: CGPoint(x: 500, y: 600), panelSize: panel, visibleFrame: frame)
        XCTAssertEqual(origin.x, 508)
        XCTAssertEqual(origin.y, 600 - 8 - 500)
    }

    func testClampsToRightEdge() {
        let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = clipboardPanelOrigin(mouseLocation: CGPoint(x: 1430, y: 600), panelSize: panel, visibleFrame: frame)
        XCTAssertEqual(origin.x, 1440 - 420)
    }

    func testClampsToBottomEdge() {
        let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = clipboardPanelOrigin(mouseLocation: CGPoint(x: 500, y: 20), panelSize: panel, visibleFrame: frame)
        XCTAssertEqual(origin.y, 0)
    }

    func testClampsToTopEdge() {
        let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = clipboardPanelOrigin(mouseLocation: CGPoint(x: 500, y: 5000), panelSize: panel, visibleFrame: frame)
        XCTAssertEqual(origin.y, 900 - 500)
    }

    func testHandlesNegativeOriginDisplay() {
        let frame = CGRect(x: -1440, y: -900, width: 1440, height: 900)
        let origin = clipboardPanelOrigin(mouseLocation: CGPoint(x: -1430, y: -100), panelSize: panel, visibleFrame: frame)
        XCTAssertGreaterThanOrEqual(origin.x, frame.minX)
        XCTAssertLessThanOrEqual(origin.x + panel.width, frame.maxX)
        XCTAssertGreaterThanOrEqual(origin.y, frame.minY)
        XCTAssertLessThanOrEqual(origin.y + panel.height, frame.maxY)
    }

    func testPanelLargerThanScreenPinsToMinimum() {
        let frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        let origin = clipboardPanelOrigin(mouseLocation: CGPoint(x: 150, y: 150), panelSize: panel, visibleFrame: frame)
        XCTAssertEqual(origin.x, 0)
        XCTAssertEqual(origin.y, 0)
    }
}
