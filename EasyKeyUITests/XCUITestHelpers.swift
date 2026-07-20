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
    /// silently no-op. After the fallback click we briefly recheck `isHittable`: if the window woke
    /// up as a result, we issue one real `click()` so the action actually fires.
    @discardableResult
    func clickWhenHittable(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result == .completed, isHittable {
            click()
            return true
        }
        let elementFrame = frame
        guard exists, elementFrame.width > 0, elementFrame.height > 0 else { return false }
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()

        let wakeExpectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        if XCTWaiter().wait(for: [wakeExpectation], timeout: 1) == .completed, isHittable {
            click()
        }
        return true
    }
}
