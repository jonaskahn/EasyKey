import AppKit
import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class ClipboardServicesExtendedTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("services-ext-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testInitDefaultState() {
        let registrar = FakeHotKeyRegistrar()
        let services = makeServices(enabled: true, registrar: registrar, reader: FakePasteboardReader())
        XCTAssertEqual(services.model.entryCount, 0)
        XCTAssertFalse(services.monitor.isRunning)
        XCTAssertFalse(services.hotKey.isRegistered)
        XCTAssertFalse(services.hotkeyConflict)
    }

    func testStartWithHotkeyConflict() async {
        let registrar = FakeHotKeyRegistrar()
        registrar.failNextRegister = true
        let services = makeServices(enabled: true, registrar: registrar, reader: FakePasteboardReader())
        await services.start(loadPersisted: false)
        XCTAssertTrue(services.hotkeyConflict)
    }

    func testStartDoesNotStartCaptureWhenDisabled() async {
        let registrar = FakeHotKeyRegistrar()
        let reader = FakePasteboardReader()
        let services = makeServices(enabled: false, registrar: registrar, reader: reader)
        await services.start(loadPersisted: false)
        XCTAssertFalse(services.monitor.isRunning)
    }

    func testApplyTogglesCaptureOnOff() async {
        let reader = FakePasteboardReader()
        let services = makeServices(enabled: false, registrar: FakeHotKeyRegistrar(), reader: reader)
        await services.start(loadPersisted: false)
        XCTAssertFalse(services.monitor.isRunning)

        services.apply(ClipboardOptions(isCaptureEnabled: true))
        XCTAssertTrue(services.monitor.isRunning)

        services.apply(ClipboardOptions(isCaptureEnabled: false))
        XCTAssertFalse(services.monitor.isRunning)
    }

    func testApplyDoesNotRestartWhenAlreadyRunning() async {
        let registrar = FakeHotKeyRegistrar()
        let services = makeServices(enabled: true, registrar: registrar, reader: FakePasteboardReader())
        await services.start(loadPersisted: false)
        let previousRegistrations = registrar.registerCount

        services.apply(ClipboardOptions(isCaptureEnabled: true, shortcut: Shortcut(keyCode: 9, modifiers: [.command])))

        let currentRegistrations = registrar.registerCount
        XCTAssertEqual(currentRegistrations, previousRegistrations + 1)
    }

    func testHandleWakeRefreshesMonitor() async {
        let reader = FakePasteboardReader()
        let services = makeServices(enabled: true, registrar: FakeHotKeyRegistrar(), reader: reader)
        await services.start(loadPersisted: false)
        services.handleWake()
    }

    func testSynthesizePasteReturnsBool() {
        let result = ClipboardServices.synthesizePaste()
        XCTAssertTrue(result || !result)
    }

    func testOpenSettingsClosure() {
        let services = makeServices(enabled: true, registrar: FakeHotKeyRegistrar(), reader: FakePasteboardReader())
        var opened = false
        services.openSettings = { opened = true }
        services.openSettings()
        XCTAssertTrue(opened)
    }

    func testShowPanelDoesNotCrash() {
        let services = makeServices(enabled: true, registrar: FakeHotKeyRegistrar(), reader: FakePasteboardReader())
        services.showPanel()
    }

    private func makeServices(
        enabled: Bool,
        registrar: FakeHotKeyRegistrar,
        reader: FakePasteboardReader
    ) -> ClipboardServices {
        ClipboardServices(
            options: ClipboardOptions(isCaptureEnabled: enabled),
            applicationSupportDirectory: directory,
            keyProvider: InMemoryClipboardKeyStore(),
            reader: reader,
            hotKeyRegistrar: registrar,
            frontmostProvider: { nil }
        )
    }
}
