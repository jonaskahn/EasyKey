@testable import EasyKey
import XCTest

final class TranslationPanelGeometryTests: XCTestCase {
    private let panelSize = CGSize(width: 520, height: 560)

    func testMiddleOfDisplayOffsetsBelowAndRightOfPointer() {
        let screen = geometry(x: 0, y: 0, width: 1440, height: 900)

        let origin = translationPanelOrigin(
            pointerLocation: CGPoint(x: 400, y: 800),
            panelSize: panelSize,
            screens: [screen]
        )

        XCTAssertEqual(origin, CGPoint(x: 408, y: 232))
    }

    func testEveryVisibleFrameEdgeConstrainsEntirePanel() {
        let screen = geometry(x: 100, y: 50, width: 1200, height: 800)
        let pointers = [
            CGPoint(x: 100, y: 50),
            CGPoint(x: 1300, y: 50),
            CGPoint(x: 100, y: 850),
            CGPoint(x: 1300, y: 850),
        ]

        for pointer in pointers {
            let origin = translationPanelOrigin(pointerLocation: pointer, panelSize: panelSize, screens: [screen])
            XCTAssertGreaterThanOrEqual(origin.x, screen.visibleFrame.minX)
            XCTAssertLessThanOrEqual(origin.x + panelSize.width, screen.visibleFrame.maxX)
            XCTAssertGreaterThanOrEqual(origin.y, screen.visibleFrame.minY)
            XCTAssertLessThanOrEqual(origin.y + panelSize.height, screen.visibleFrame.maxY)
        }
    }

    func testNegativeCoordinateDisplayUsesItsVisibleFrame() {
        let screen = geometry(x: -1600, y: -200, width: 1600, height: 1000)

        let origin = translationPanelOrigin(
            pointerLocation: CGPoint(x: -1590, y: -190),
            panelSize: panelSize,
            screens: [screen]
        )

        XCTAssertEqual(origin.x, -1582)
        XCTAssertEqual(origin.y, -200)
    }

    func testMultipleDisplaysSelectDisplayContainingPointer() {
        let primary = geometry(x: 0, y: 0, width: 1440, height: 900)
        let left = TranslationPanelScreenGeometry(
            frame: CGRect(x: -1920, y: -200, width: 1920, height: 1080),
            visibleFrame: CGRect(x: -1920, y: -150, width: 1920, height: 1030)
        )

        let origin = translationPanelOrigin(
            pointerLocation: CGPoint(x: -100, y: 800),
            panelSize: panelSize,
            screens: [primary, left]
        )

        XCTAssertGreaterThanOrEqual(origin.x, left.visibleFrame.minX)
        XCTAssertLessThanOrEqual(origin.x + panelSize.width, left.visibleFrame.maxX)
        XCTAssertGreaterThanOrEqual(origin.y, left.visibleFrame.minY)
        XCTAssertLessThanOrEqual(origin.y + panelSize.height, left.visibleFrame.maxY)
    }

    func testPointerOutsideDisplaysUsesNearestDisplay() {
        let left = geometry(x: -1600, y: 0, width: 1600, height: 900)
        let right = geometry(x: 0, y: 0, width: 1600, height: 900)

        let origin = translationPanelOrigin(
            pointerLocation: CGPoint(x: 1700, y: 400),
            panelSize: panelSize,
            screens: [left, right]
        )

        XCTAssertEqual(origin.x, right.visibleFrame.maxX - panelSize.width)
    }

    func testPanelLargerThanVisibleFramePinsToMinimumEdges() {
        let screen = geometry(x: -300, y: -400, width: 300, height: 300)

        let origin = translationPanelOrigin(
            pointerLocation: CGPoint(x: -150, y: -250),
            panelSize: panelSize,
            screens: [screen]
        )

        XCTAssertEqual(origin, screen.visibleFrame.origin)
    }

    private func geometry(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> TranslationPanelScreenGeometry {
        let frame = CGRect(x: x, y: y, width: width, height: height)
        return TranslationPanelScreenGeometry(frame: frame, visibleFrame: frame)
    }
}
