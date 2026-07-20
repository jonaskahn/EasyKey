import XCTest

extension XCUIElement {
    /// Waits until the element is hittable before clicking. XCUITest's `exists`/`waitForExistence`
    /// only confirm the accessibility element is in the tree, not that its window is key and its
    /// frame is resolvable on screen — clicking too early drops the click or fails hit-testing.
    func clickWhenHittable(timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        _ = XCTWaiter().wait(for: [expectation], timeout: timeout)
        click()
    }
}
