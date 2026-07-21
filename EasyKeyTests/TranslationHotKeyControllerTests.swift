import Carbon.HIToolbox
import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class TranslationHotKeyControllerTests: XCTestCase {
    func testDefaultShortcutRegistersPhysicalOptionC() {
        let registrar = FakeTranslationHotKeyRegistrar()
        let controller = TranslationHotKeyController(registrar: registrar) {}

        XCTAssertTrue(controller.apply(TranslationOptions().shortcut))

        XCTAssertEqual(registrar.registrations.count, 1)
        XCTAssertEqual(registrar.registrations[0].keyCode, 8)
        XCTAssertEqual(registrar.registrations[0].modifiers, UInt32(optionKey))
        XCTAssertEqual(controller.registrationState, .registered(TranslationOptions().shortcut))
        XCTAssertTrue(controller.isRegistered)
        XCTAssertFalse(controller.hasConflict)
    }

    func testActivationInvokesCallbackExactlyOnceForMatchingEvent() throws {
        let registrar = FakeTranslationHotKeyRegistrar()
        var activationCount = 0
        let controller = TranslationHotKeyController(registrar: registrar) { activationCount += 1 }
        controller.apply(TranslationOptions().shortcut)

        let identity = try XCTUnwrap(registrar.registrations.first?.identity)
        registrar.fire(identity: identity)

        XCTAssertEqual(activationCount, 1)
    }

    func testUnmatchedEventDoesNotInvokeCallback() {
        let registrar = FakeTranslationHotKeyRegistrar()
        var activationCount = 0
        let controller = TranslationHotKeyController(registrar: registrar) { activationCount += 1 }
        controller.apply(TranslationOptions().shortcut)

        registrar.fire(identity: TranslationHotKeyIdentity(signature: 0, identifier: 0))

        XCTAssertEqual(activationCount, 0)
    }

    func testReplacementRegistersNewBeforeUnregisteringOld() {
        let registrar = FakeTranslationHotKeyRegistrar()
        let controller = TranslationHotKeyController(registrar: registrar) {}
        let original = TranslationOptions().shortcut
        let replacement = Shortcut(keyCode: 1, modifiers: [.command, .shift])
        controller.apply(original)
        let originalIdentity = registrar.registrations[0].identity

        XCTAssertTrue(controller.apply(replacement))

        XCTAssertEqual(registrar.operations, [
            .register(originalIdentity),
            .register(registrar.registrations[1].identity),
            .unregister(originalIdentity),
        ])
        XCTAssertEqual(registrar.activeIdentities, [registrar.registrations[1].identity])
        XCTAssertEqual(controller.registrationState, .registered(replacement))
    }

    func testConflictingReplacementPreservesPreviousRegistrationAndPublishesState() {
        let registrar = FakeTranslationHotKeyRegistrar()
        let controller = TranslationHotKeyController(registrar: registrar) {}
        let original = TranslationOptions().shortcut
        let replacement = Shortcut(keyCode: 1, modifiers: [.command])
        controller.apply(original)
        registrar.failNextRegistration = true

        XCTAssertFalse(controller.apply(replacement))

        XCTAssertEqual(registrar.activeIdentities, [registrar.registrations[0].identity])
        XCTAssertEqual(controller.registrationState, .conflict(attempted: replacement, active: original))
        XCTAssertTrue(controller.hasConflict)
        XCTAssertTrue(controller.isRegistered)
    }

    func testInitialConflictPublishesNoActiveShortcut() {
        let registrar = FakeTranslationHotKeyRegistrar()
        registrar.failNextRegistration = true
        let controller = TranslationHotKeyController(registrar: registrar) {}
        let shortcut = TranslationOptions().shortcut

        XCTAssertFalse(controller.apply(shortcut))

        XCTAssertEqual(controller.registrationState, .conflict(attempted: shortcut, active: nil))
        XCTAssertFalse(controller.isRegistered)
    }

    func testDuplicateSuccessfulApplyDoesNotTouchRegistrar() {
        let registrar = FakeTranslationHotKeyRegistrar()
        let controller = TranslationHotKeyController(registrar: registrar) {}
        let shortcut = TranslationOptions().shortcut
        controller.apply(shortcut)

        XCTAssertTrue(controller.apply(shortcut))

        XCTAssertEqual(registrar.registrations.count, 1)
        XCTAssertEqual(registrar.operations.count, 1)
    }

    func testReapplyingActiveShortcutClearsReplacementConflictWithoutRegistrarCalls() {
        let registrar = FakeTranslationHotKeyRegistrar()
        let controller = TranslationHotKeyController(registrar: registrar) {}
        let original = TranslationOptions().shortcut
        controller.apply(original)
        registrar.failNextRegistration = true
        controller.apply(Shortcut(keyCode: 1, modifiers: [.command]))
        let attemptCount = registrar.registrationAttempts

        XCTAssertTrue(controller.apply(original))

        XCTAssertEqual(registrar.registrationAttempts, attemptCount)
        XCTAssertEqual(controller.registrationState, .registered(original))
        XCTAssertFalse(controller.hasConflict)
    }

    func testDuplicateFailedApplyDoesNotRetryRegistrar() {
        let registrar = FakeTranslationHotKeyRegistrar()
        registrar.failNextRegistration = true
        let controller = TranslationHotKeyController(registrar: registrar) {}
        let shortcut = TranslationOptions().shortcut
        controller.apply(shortcut)

        XCTAssertFalse(controller.apply(shortcut))

        XCTAssertEqual(registrar.registrationAttempts, 1)
    }

    func testClearingShortcutUnregistersAndClearsConflict() {
        let registrar = FakeTranslationHotKeyRegistrar()
        let controller = TranslationHotKeyController(registrar: registrar) {}
        controller.apply(TranslationOptions().shortcut)

        XCTAssertTrue(controller.apply(.none))

        XCTAssertTrue(registrar.activeIdentities.isEmpty)
        XCTAssertEqual(controller.registrationState, .unregistered)
        XCTAssertFalse(controller.isRegistered)
        XCTAssertFalse(controller.hasConflict)
    }

    func testShutdownRemovesRegistrationHandlersAndRegistrarEventHandler() throws {
        let registrar = FakeTranslationHotKeyRegistrar()
        var activationCount = 0
        let controller = TranslationHotKeyController(registrar: registrar) { activationCount += 1 }
        controller.apply(TranslationOptions().shortcut)
        let identity = try XCTUnwrap(registrar.registrations.first?.identity)

        controller.shutdown()
        registrar.fire(identity: identity)

        XCTAssertTrue(registrar.activeIdentities.isEmpty)
        XCTAssertTrue(registrar.handlers.isEmpty)
        XCTAssertFalse(registrar.isEventHandlerInstalled)
        XCTAssertEqual(registrar.shutdownCount, 1)
        XCTAssertEqual(activationCount, 0)
        XCTAssertEqual(controller.registrationState, .unregistered)
    }

    func testShutdownIsIdempotentAndApplyCannotReRegister() {
        let registrar = FakeTranslationHotKeyRegistrar()
        let controller = TranslationHotKeyController(registrar: registrar) {}
        controller.apply(TranslationOptions().shortcut)

        controller.shutdown()
        controller.shutdown()

        XCTAssertFalse(controller.apply(Shortcut(keyCode: 1, modifiers: [.command])))
        XCTAssertEqual(registrar.shutdownCount, 1)
        XCTAssertEqual(registrar.registrationAttempts, 1)
    }

    func testTranslationCarbonIdentityDiffersFromClipboardIdentity() {
        XCTAssertNotEqual(TranslationHotKeyController.carbonSignature, CarbonHotKeyRegistrar.carbonSignature)
        XCTAssertNotEqual(TranslationHotKeyController.firstCarbonIdentifier, ClipboardHotKeyController.firstCarbonIdentifier)
    }

    func testCarbonModifierMappingIncludesEverySupportedModifier() {
        let modifiers = TranslationHotKeyController.carbonModifiers([.control, .option, .shift, .command])

        XCTAssertEqual(modifiers, UInt32(controlKey | optionKey | shiftKey | cmdKey))
    }
}

private final class FakeTranslationHotKeyRegistrar: TranslationHotKeyRegistering {
    struct Registration {
        let keyCode: UInt32
        let modifiers: UInt32
        let identity: TranslationHotKeyIdentity
    }

    enum Operation: Equatable {
        case register(TranslationHotKeyIdentity)
        case unregister(TranslationHotKeyIdentity)
        case shutdown
    }

    private(set) var registrations: [Registration] = []
    private(set) var registrationAttempts = 0
    private(set) var activeIdentities: Set<TranslationHotKeyIdentity> = []
    private(set) var handlers: [TranslationHotKeyIdentity: @MainActor () -> Void] = [:]
    private(set) var operations: [Operation] = []
    private(set) var shutdownCount = 0
    private(set) var isEventHandlerInstalled = false
    var failNextRegistration = false

    func register(
        keyCode: UInt32,
        modifiers: UInt32,
        identity: TranslationHotKeyIdentity,
        handler: @escaping @MainActor () -> Void
    ) -> Bool {
        registrationAttempts += 1
        if failNextRegistration {
            failNextRegistration = false
            return false
        }
        registrations.append(Registration(keyCode: keyCode, modifiers: modifiers, identity: identity))
        activeIdentities.insert(identity)
        handlers[identity] = handler
        operations.append(.register(identity))
        isEventHandlerInstalled = true
        return true
    }

    func unregister(identity: TranslationHotKeyIdentity) {
        activeIdentities.remove(identity)
        handlers.removeValue(forKey: identity)
        operations.append(.unregister(identity))
    }

    func shutdown() {
        shutdownCount += 1
        activeIdentities.removeAll()
        handlers.removeAll()
        isEventHandlerInstalled = false
        operations.append(.shutdown)
    }

    @MainActor
    func fire(identity: TranslationHotKeyIdentity) {
        handlers[identity]?()
    }
}
