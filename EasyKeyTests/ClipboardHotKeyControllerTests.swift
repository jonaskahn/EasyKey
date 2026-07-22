import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class ClipboardHotKeyControllerTests: XCTestCase {
    func testRegistersConfiguredShortcut() {
        let registrar = FakeHotKeyRegistrar()
        let controller = ClipboardHotKeyController(registrar: registrar) {}
        XCTAssertTrue(controller.apply(Shortcut(keyCode: 9, modifiers: [.control, .option])))
        XCTAssertTrue(controller.isRegistered)
        XCTAssertEqual(registrar.activeIdentifiers.count, 1)
    }

    func testReplacingShortcutRegistersNewBeforeRemovingOld() {
        let registrar = FakeHotKeyRegistrar()
        let controller = ClipboardHotKeyController(registrar: registrar) {}
        controller.apply(Shortcut(keyCode: 9, modifiers: [.control, .option]))
        controller.apply(Shortcut(keyCode: 8, modifiers: [.command]))
        XCTAssertEqual(registrar.activeIdentifiers.count, 1)
        XCTAssertEqual(registrar.registerCount, 2)
        XCTAssertEqual(registrar.unregisterCount, 1)
    }

    func testFailedReplacementKeepsPreviousShortcut() {
        let registrar = FakeHotKeyRegistrar()
        let controller = ClipboardHotKeyController(registrar: registrar) {}
        controller.apply(Shortcut(keyCode: 9, modifiers: [.control, .option]))

        registrar.failNextRegister = true
        XCTAssertFalse(controller.apply(Shortcut(keyCode: 8, modifiers: [.command])))
        XCTAssertTrue(controller.hasConflict)
        XCTAssertTrue(controller.isRegistered)
        XCTAssertEqual(registrar.activeIdentifiers.count, 1)
    }

    func testInactiveShortcutUnregisters() {
        let registrar = FakeHotKeyRegistrar()
        let controller = ClipboardHotKeyController(registrar: registrar) {}
        controller.apply(Shortcut(keyCode: 9, modifiers: [.control, .option]))
        controller.apply(.none)
        XCTAssertFalse(controller.isRegistered)
        XCTAssertTrue(registrar.activeIdentifiers.isEmpty)
    }

    func testActivationHandlerFires() {
        let registrar = FakeHotKeyRegistrar()
        var fired = 0
        let controller = ClipboardHotKeyController(registrar: registrar) { fired += 1 }
        controller.apply(Shortcut(keyCode: 9, modifiers: [.control]))
        registrar.fireAll()
        XCTAssertEqual(fired, 1)
    }

    func testShutdownReleasesRegistrar() {
        let registrar = FakeHotKeyRegistrar()
        let controller = ClipboardHotKeyController(registrar: registrar) {}
        controller.apply(Shortcut(keyCode: 9, modifiers: [.control]))

        controller.shutdown()

        XCTAssertFalse(controller.isRegistered)
        XCTAssertEqual(registrar.shutdownCount, 1)
    }
}

final class FakeHotKeyRegistrar: ClipboardHotKeyRegistrar {
    private(set) var activeIdentifiers: Set<UInt32> = []
    private(set) var registerCount = 0
    private(set) var unregisterCount = 0
    private(set) var shutdownCount = 0
    var failNextRegister = false
    private var handlers: [UInt32: () -> Void] = [:]

    func register(keyCode _: UInt32, modifiers _: UInt32, identifier: UInt32, handler: @escaping () -> Void) -> Bool {
        registerCount += 1
        if failNextRegister {
            failNextRegister = false
            return false
        }
        activeIdentifiers.insert(identifier)
        handlers[identifier] = handler
        return true
    }

    func unregister(identifier: UInt32) {
        unregisterCount += 1
        activeIdentifiers.remove(identifier)
        handlers.removeValue(forKey: identifier)
    }

    func fireAll() {
        handlers.values.forEach { $0() }
    }

    func shutdown() {
        shutdownCount += 1
        activeIdentifiers.removeAll()
        handlers.removeAll()
    }
}
