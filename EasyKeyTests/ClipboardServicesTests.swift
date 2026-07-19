import AppKit
import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class ClipboardServicesTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("services-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testStartRegistersHotkeyAndStartsCaptureWhenEnabled() async {
        let registrar = FakeHotKeyRegistrar()
        let reader = FakePasteboardReader()
        let services = makeServices(enabled: true, registrar: registrar, reader: reader)
        await services.start(loadPersisted: false)
        XCTAssertTrue(services.hotKey.isRegistered)
        XCTAssertTrue(services.monitor.isRunning)
        XCTAssertFalse(services.hotkeyConflict)
    }

    func testCaptureFlowsFromMonitorToModel() async {
        let reader = FakePasteboardReader()
        let services = makeServices(enabled: true, registrar: FakeHotKeyRegistrar(), reader: reader)
        await services.start(loadPersisted: false)
        reader.setText("captured", changeCount: 42)
        services.monitor.poll()
        XCTAssertEqual(services.model.entryCount, 1)
    }

    func testApplyStopsCaptureWhenDisabled() async {
        let reader = FakePasteboardReader()
        let services = makeServices(enabled: true, registrar: FakeHotKeyRegistrar(), reader: reader)
        await services.start(loadPersisted: false)
        services.apply(ClipboardOptions(isCaptureEnabled: false))
        XCTAssertFalse(services.monitor.isRunning)
    }

    func testStopTearsDown() async {
        let services = makeServices(enabled: true, registrar: FakeHotKeyRegistrar(), reader: FakePasteboardReader())
        await services.start(loadPersisted: false)
        await services.stop()
        XCTAssertFalse(services.monitor.isRunning)
        XCTAssertFalse(services.hotKey.isRegistered)
    }

    func testApplyReturnsOptions() async {
        let registrar = FakeHotKeyRegistrar()
        let services = makeServices(enabled: true, registrar: registrar, reader: FakePasteboardReader())
        await services.start(loadPersisted: false)
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.ignoredApplicationBundleIdentifiers = ["com.example.test"]
        services.apply(options)
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
