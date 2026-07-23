@testable import EasyKey
import XCTest

@MainActor
final class AppCoordinatorConcurrencyTests: XCTestCase {
    func testAppCoordinatorInitialization_OnMainActor() {
        let coordinator = AppCoordinator.makeDefault()
        XCTAssertNotNil(coordinator.settingsStore)
    }
}
