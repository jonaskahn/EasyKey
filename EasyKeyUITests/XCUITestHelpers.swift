import XCTest

extension XCUIElement {
    /// Clicks the element, waiting for it to become hittable first, and returns whether a click
    /// was dispatched. XCUITest's `exists`/`waitForExistence` only confirm the accessibility element
    /// is in the tree, not that its window is key and its frame is resolvable on screen. Under
    /// headless CI the app window is frequently never key, so controls report `isHittable == false`;
    /// for a control nested in a clipped `ScrollView` (e.g. the `SettingsDetail` panes) calling
    /// `click()` then throws "Unable to find hit point" and aborts the test.
    ///
    /// When the element does not report hittable in time we fall back to a coordinate click. That
    /// bypasses the hit-point search (so it never throws) while still landing on the element's frame
    /// center — which advances flows whose later assertions depend on the click actually registering
    /// (onboarding step navigation, the sidebar toggle), unlike simply skipping it.
    ///
    /// A background/non-key window eats its first click as a plain activation (AppKit's standard
    /// click-through prevention) without running the control's action — so one coordinate click can
    /// silently no-op. On both branches we briefly recheck `isHittable` after the click: if the
    /// window woke up as a result (or the click was consumed as window activation), we issue a
    /// follow-up `click()` so the action actually fires.
    @discardableResult
    func clickWhenHittable(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result == .completed, isHittable {
            click()
            return confirmWindowKeyThenClick(predicate: predicate)
        }
        let elementFrame = frame
        guard exists, elementFrame.width > 0, elementFrame.height > 0 else { return false }
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

    /// Reveals `element` inside a scrollable ancestor by swiping up at most `maximumSwipes` times.
    /// Uses a coordinate-based drag so it never throws "Unable to find hit point" when the window
    /// is not yet key.
    @discardableResult
    func reveal(_ element: XCUIElement, maximumSwipes: Int = 5) -> Bool {
        for _ in 0 ..< maximumSwipes {
            let settingsDetail = descendants(matching: .any)["SettingsDetail"]
            let window = windows.firstMatch
            let elementFrame = element.frame
            if element.exists,
               window.exists,
               elementFrame.maxY > window.frame.minY,
               elementFrame.minY < window.frame.maxY {
                return true
            }
            guard settingsDetail.exists else { return false }
            let detailFrame = settingsDetail.frame
            guard detailFrame.width > 0, detailFrame.height > 0 else { return false }
            let start = settingsDetail.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            let end = settingsDetail.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            start.click(forDuration: 0.01, thenDragTo: end)
        }
        return element.exists
    }
}
