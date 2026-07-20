import XCTest

final class SettingsAccessibilityTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--ui-skip-onboarding")
    }

    override func tearDown() {
        app.terminate()
    }

    private func performAuditOnSection(_ section: String) throws {
        app.launchArguments += ["--ui-settings-section", section]
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit { issue in
            if issue.auditType == .sufficientElementDescription,
               issue.element?.elementType == .group,
               issue.element?.identifier.isEmpty == true {
                return true
            }
            if issue.auditType == .sufficientElementDescription,
               issue.element?.elementType == .touchBar {
                return true
            }
            if issue.auditType == .parentChild,
               issue.element?.elementType == .group,
               issue.element?.identifier.isEmpty == true {
                return true
            }
            if issue.auditType == .contrast {
                return true
            }
            return issue.auditType == .action
                && issue.element?.elementType == .popUpButton
        }
        app.terminate()
    }

    func testTypingSectionPassesAccessibilityAudit() throws {
        try performAuditOnSection("Typing")
    }

    func testEncodingSectionPassesAccessibilityAudit() throws {
        try performAuditOnSection("Encoding")
    }

    func testClipboardSectionPassesAccessibilityAudit() throws {
        try performAuditOnSection("Clipboard")
    }

    func testMacrosSectionPassesAccessibilityAudit() throws {
        try performAuditOnSection("Macros")
    }

    func testSmartSwitchSectionPassesAccessibilityAudit() throws {
        try performAuditOnSection("Smart Switch")
    }

    func testBehaviorSectionPassesAccessibilityAudit() throws {
        try performAuditOnSection("Behavior")
    }

    func testSystemSectionPassesAccessibilityAudit() throws {
        try performAuditOnSection("System")
    }

    func testAboutSectionPassesAccessibilityAudit() throws {
        try performAuditOnSection("About")
    }
}
