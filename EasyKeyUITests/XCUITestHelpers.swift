import XCTest

extension XCUIElement {
    /// Clicks the element, waiting for it to become hittable first, and returns whether a click
    /// was dispatched. XCUITest's `exists`/`waitForExistence` only confirm the accessibility element
    /// is in the tree, not that its window is key and its frame is resolvable on screen. Under
    /// headless CI the app window is frequently never key, so controls report `isHittable == false`;
    /// for a control nested in a clipped `ScrollView` (e.g. the `SettingsDetail` panes) calling
    /// `click()` then throws "Unable to find hit point" and aborts the test.
    ///
    /// When the element does not report hittable in time we scroll it into view (via `reveal`)
    /// and retry. As a last resort we fall back to a coordinate click, but only when the element's
    /// frame actually intersects the window — a click at a frame that lies outside the window would
    /// land on the desktop and silently no-op.
    ///
    /// A hittable element implies the window is key, so a successful `isHittable` click fires the
    /// action exactly once. Only in the coordinate-fallback path can the first click be eaten as a
    /// plain window activation (AppKit's click-through prevention); there we re-check after the
    /// click and issue a follow-up click once the window woke up.
    @discardableResult
    func clickWhenHittable(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        if XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed, isHittable {
            click()
            return true
        }

        // Off-screen inside a scroll view: scroll it into view and retry.
        if exists, XCUIApplication().reveal(self) {
            let retry = XCTNSPredicateExpectation(predicate: predicate, object: self)
            if XCTWaiter().wait(for: [retry], timeout: 2) == .completed, isHittable {
                click()
                return true
            }
        }

        let elementFrame = frame
        guard exists, elementFrame.width > 0, elementFrame.height > 0 else { return false }
        let windowFrame = XCUIApplication().windows.firstMatch.frame
        let intersects = windowFrame.width > 0
            && elementFrame.maxY > windowFrame.minY
            && elementFrame.minY < windowFrame.maxY
            && elementFrame.maxX > windowFrame.minX
            && elementFrame.minX < windowFrame.maxX
        guard intersects else { return false }
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        return confirmWindowKeyThenClick(predicate: predicate)
    }

    /// After a click that may have been consumed as window activation, wait briefly and re-click
    /// once if the element is still hittable — this ensures the control's action actually fires.
    private func confirmWindowKeyThenClick(predicate: NSPredicate) -> Bool {
        let wakeExpectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        if XCTWaiter().wait(for: [wakeExpectation], timeout: 1) == .completed, isHittable {
            click()
        }
        return true
    }
}

extension XCUIApplication {
    /// Eats the first "activation-only" click so subsequent interactions with real controls are
    /// not silently consumed by making a background window key. Under headless CI the app window
    /// is frequently never key — this forces it key deterministically.
    @discardableResult
    func ensureKeyWindow() -> Bool {
        let mainWindow = windows.firstMatch
        guard mainWindow.exists else { return false }
        let titleBarClick = mainWindow.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02))
        titleBarClick.click()
        Thread.sleep(forTimeInterval: 0.5)
        return true
    }

    /// Reveals `element` inside a scrollable ancestor by scrolling the `SettingsDetail` scroll
    /// view until the element's frame intersects the window.
    ///
    /// Mouse drags do NOT scroll `NSScrollView` on macOS (only scroll wheel events do), so a
    /// drag-based "swipe" loop leaves off-screen rows untouched and the element never becomes
    /// hittable. Use the native `scroll(byDeltaX:deltaY:)` API instead, which synthesizes real
    /// scroll-wheel events.
    @discardableResult
    func reveal(_ element: XCUIElement, maximumScrolls: Int = 15) -> Bool {
        let window = windows.firstMatch
        let settingsDetail = descendants(matching: .any)["SettingsDetail"]
        guard element.exists, window.exists, settingsDetail.exists else { return element.exists }

        for _ in 0 ..< maximumScrolls {
            let elementFrame = element.frame
            if elementFrame.width > 0,
               elementFrame.maxY > window.frame.minY,
               elementFrame.minY < window.frame.maxY {
                return element.isHittable || elementFrame.maxY <= window.frame.maxY
            }
            // Scroll toward the element: down if it is below the window, up if above.
            if elementFrame.maxY > window.frame.minY {
                settingsDetail.scroll(byDeltaX: 0, deltaY: -80)
            } else {
                settingsDetail.scroll(byDeltaX: 0, deltaY: 80)
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        // Final in-window check: `exists` alone is not enough — scroll-view children exist
        // even when scrolled out of the visible area.
        let elementFrame = element.frame
        return elementFrame.width > 0
            && elementFrame.maxY > window.frame.minY
            && elementFrame.minY < window.frame.maxY
    }
}
