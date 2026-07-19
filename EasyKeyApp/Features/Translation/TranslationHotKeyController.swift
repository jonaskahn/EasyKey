import Carbon.HIToolbox
import EasyEngineCore

struct TranslationHotKeyIdentity: Equatable, Hashable {
    let signature: OSType
    let identifier: UInt32
}

protocol TranslationHotKeyRegistering: AnyObject {
    func register(
        keyCode: UInt32,
        modifiers: UInt32,
        identity: TranslationHotKeyIdentity,
        handler: @escaping @MainActor () -> Void
    ) -> Bool
    func unregister(identity: TranslationHotKeyIdentity)
    func shutdown()
}

enum TranslationHotKeyRegistrationState: Equatable {
    case unregistered
    case registered(Shortcut)
    case conflict(attempted: Shortcut, active: Shortcut?)
}

/// Owns translation hotkey registration and keeps a working binding when a
/// replacement conflicts. Carbon resources remain owned until `shutdown()`.
@MainActor
final class TranslationHotKeyController {
    nonisolated static let carbonSignature: OSType = 0x454B_5452 // 'EKTR'
    nonisolated static let firstCarbonIdentifier: UInt32 = 0x5452_0001

    private let registrar: TranslationHotKeyRegistering
    private let onActivate: @MainActor () -> Void
    private var activeIdentity: TranslationHotKeyIdentity?
    private var activeShortcut: Shortcut?
    private var failedShortcut: Shortcut?
    private var nextIdentifier = TranslationHotKeyController.firstCarbonIdentifier
    private var isShutdown = false

    private(set) var registrationState: TranslationHotKeyRegistrationState = .unregistered

    init(registrar: TranslationHotKeyRegistering, onActivate: @escaping @MainActor () -> Void) {
        self.registrar = registrar
        self.onActivate = onActivate
    }

    var isRegistered: Bool {
        activeIdentity != nil
    }

    var hasConflict: Bool {
        if case .conflict = registrationState {
            return true
        }
        return false
    }

    @discardableResult
    func apply(_ shortcut: Shortcut) -> Bool {
        guard !isShutdown else { return false }
        guard shortcut.isActive else {
            unregister()
            failedShortcut = nil
            registrationState = .unregistered
            return true
        }
        if shortcut == activeShortcut, activeIdentity != nil {
            failedShortcut = nil
            registrationState = .registered(shortcut)
            return true
        }
        if shortcut == failedShortcut {
            return false
        }

        let identity = TranslationHotKeyIdentity(
            signature: Self.carbonSignature,
            identifier: nextIdentifier
        )
        nextIdentifier &+= 1
        let succeeded = registrar.register(
            keyCode: UInt32(shortcut.keyCode),
            modifiers: Self.carbonModifiers(shortcut.modifiers),
            identity: identity,
            handler: onActivate
        )
        guard succeeded else {
            failedShortcut = shortcut
            registrationState = .conflict(attempted: shortcut, active: activeShortcut)
            return false
        }

        if let previousIdentity = activeIdentity {
            registrar.unregister(identity: previousIdentity)
        }
        activeIdentity = identity
        activeShortcut = shortcut
        failedShortcut = nil
        registrationState = .registered(shortcut)
        return true
    }

    func unregister() {
        if let activeIdentity {
            registrar.unregister(identity: activeIdentity)
        }
        activeIdentity = nil
        activeShortcut = nil
        failedShortcut = nil
        registrationState = .unregistered
    }

    func shutdown() {
        guard !isShutdown else { return }
        unregister()
        registrar.shutdown()
        isShutdown = true
    }

    static func carbonModifiers(_ modifiers: Shortcut.ModifierFlags) -> UInt32 {
        var value: UInt32 = 0
        if modifiers.contains(.control) {
            value |= UInt32(controlKey)
        }
        if modifiers.contains(.option) {
            value |= UInt32(optionKey)
        }
        if modifiers.contains(.shift) {
            value |= UInt32(shiftKey)
        }
        if modifiers.contains(.command) {
            value |= UInt32(cmdKey)
        }
        return value
    }
}

/// Carbon adapter dedicated to translation. One application handler routes
/// only translation-signature events and is removed during shutdown.
final class CarbonTranslationHotKeyRegistrar: TranslationHotKeyRegistering {
    private var handlers: [TranslationHotKeyIdentity: @MainActor () -> Void] = [:]
    private var references: [TranslationHotKeyIdentity: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    private var isShutdown = false

    func register(
        keyCode: UInt32,
        modifiers: UInt32,
        identity: TranslationHotKeyIdentity,
        handler: @escaping @MainActor () -> Void
    ) -> Bool {
        guard !isShutdown, identity.signature == TranslationHotKeyController.carbonSignature else { return false }
        guard installEventHandlerIfNeeded() else { return false }

        var reference: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: identity.signature, id: identity.identifier)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &reference)
        guard status == noErr, let reference else { return false }
        references[identity] = reference
        handlers[identity] = handler
        return true
    }

    func unregister(identity: TranslationHotKeyIdentity) {
        if let reference = references.removeValue(forKey: identity) {
            UnregisterEventHotKey(reference)
        }
        handlers.removeValue(forKey: identity)
    }

    func shutdown() {
        guard !isShutdown else { return }
        for reference in references.values {
            UnregisterEventHotKey(reference)
        }
        references.removeAll()
        handlers.removeAll()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        isShutdown = true
    }

    @MainActor
    fileprivate func handle(identity: TranslationHotKeyIdentity) {
        handlers[identity]?()
    }

    private func installEventHandlerIfNeeded() -> Bool {
        if eventHandler != nil {
            return true
        }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            translationHotKeyEventHandler,
            1,
            &spec,
            context,
            &eventHandler
        )
        return status == noErr && eventHandler != nil
    }

    deinit {
        shutdown()
    }
}

private func translationHotKeyEventHandler(
    _: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }
    guard hotKeyID.signature == TranslationHotKeyController.carbonSignature else {
        return OSStatus(eventNotHandledErr)
    }

    let registrar = Unmanaged<CarbonTranslationHotKeyRegistrar>.fromOpaque(userData).takeUnretainedValue()
    MainActor.assumeIsolated {
        registrar.handle(identity: TranslationHotKeyIdentity(signature: hotKeyID.signature, identifier: hotKeyID.id))
    }
    return noErr
}
