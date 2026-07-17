import CoreGraphics
@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardServiceStateTests: XCTestCase {
    func testInitHealthIsStopped() {
        let service = KeyboardService(settings: .defaults)
        XCTAssertEqual(service.health, .stopped)
    }

    func testTogglePauseFromStopped() {
        let service = KeyboardService(settings: .defaults)
        var pauseStates: [Bool] = []
        service.pauseHandler = { pauseStates.append($0) }

        service.togglePause()
        XCTAssertTrue(pauseStates.contains(true))
    }

    func testTogglePauseMultiple() {
        let service = KeyboardService(settings: .defaults)
        var pauseStates: [Bool] = []
        service.pauseHandler = { pauseStates.append($0) }

        service.togglePause()
        service.togglePause()
        service.togglePause()

        XCTAssertEqual(pauseStates, [true, false, true])
    }

    func testSetPausedTrue() {
        let service = KeyboardService(settings: .defaults)
        service.setPaused(true)
        XCTAssertEqual(service.health, .stopped)
    }

    func testSetPausedFalseFromStopped() {
        let service = KeyboardService(settings: .defaults)
        service.setPaused(true)
        service.setPaused(false)
        XCTAssertEqual(service.health, .requestingPermission)
    }

    func testHealthHandlerCalled() {
        let service = KeyboardService(settings: .defaults)
        var healthStates: [KeyboardService.Health] = []
        service.healthHandler = { healthStates.append($0) }

        service.setPaused(true)
        service.setPaused(false)

        XCTAssertTrue(healthStates.contains(.stopped))
        XCTAssertTrue(healthStates.contains(.requestingPermission))
    }

    func testStopWhenAlreadyStopped() {
        let service = KeyboardService(settings: .defaults)
        service.stop()
        XCTAssertEqual(service.health, .stopped)
    }

    func testPauseWhenPausedStaysPaused() {
        let service = KeyboardService(settings: .defaults)
        service.setPaused(true)
        service.togglePause()
        XCTAssertEqual(service.health, .requestingPermission)
    }

    func testSetDiagnosticsEnabledTrue() {
        let service = KeyboardService(settings: .defaults)
        service.setDiagnosticsEnabled(true)
        XCTAssertTrue(service.diagnosticSnapshot().isEmpty)
    }

    func testUpdateSettingsDoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        var settings = EasyKeySettings.defaults
        settings.input.inputMethod = .vni
        settings.input.encoding = .vniWindows
        settings.typing.quickTelex = true
        service.update(settings: settings)
    }

    func testUpdateSettingsSimpleTelex() {
        let service = KeyboardService(settings: .defaults)
        var settings = EasyKeySettings.defaults
        settings.input.inputMethod = .simpleTelex
        settings.input.encoding = .cp1258
        service.update(settings: settings)
    }

    func testSetActiveApplication() {
        let service = KeyboardService(settings: .defaults)
        service.setActiveApplication("com.apple.Safari")
        service.setActiveApplication("com.google.Chrome")
        service.setActiveApplication(nil)
    }

    func testResetSessionMultiple() {
        let service = KeyboardService(settings: .defaults)
        service.resetSession()
        service.resetSession()
        service.resetSession()
    }

    func testRefreshInputSource() {
        let service = KeyboardService(settings: .defaults)
        service.refreshInputSource()
    }

    func testLanguageToggleHandler() {
        let service = KeyboardService(settings: .defaults)
        var toggled: [InputLanguage] = []
        service.languageToggleHandler = { toggled.append($0) }

        service.start()
    }

    func testDefaultEmergencyPauseShortcut() {
        let shortcut = KeyboardService.defaultEmergencyPauseShortcut
        XCTAssertTrue(shortcut.isActive)
        XCTAssertEqual(shortcut.keyCode, 35)
        XCTAssertTrue(shortcut.modifiers.contains(.control))
        XCTAssertTrue(shortcut.modifiers.contains(.option))
        XCTAssertTrue(shortcut.modifiers.contains(.command))
    }
}
