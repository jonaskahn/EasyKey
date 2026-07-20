import Carbon.HIToolbox
import EasyEngineCore

/// Narrow seam over Carbon hotkey registration so the controller's
/// register/replace/conflict logic is testable without touching the real
/// window-server hotkey registry.
protocol ClipboardHotKeyRegistrar: AnyObject {
    func register(keyCode: UInt32, modifiers: UInt32, identifier: UInt32, handler: @escaping () -> Void) -> Bool
    func unregister(identifier: UInt32)
}

/// Owns the active clipboard-panel hotkey registration. Replacement registers the
/// new shortcut under a fresh identifier first and only then removes the old one,
/// so a conflicting shortcut leaves the previous binding working.
@MainActor
final class ClipboardHotKeyController {
    nonisolated static let firstCarbonIdentifier: UInt32 = 1

    private let registrar: ClipboardHotKeyRegistrar
    private let onActivate: () -> Void

    private var activeIdentifier: UInt32?
    private var activeShortcut: Shortcut?
    private var nextIdentifier = ClipboardHotKeyController.firstCarbonIdentifier
    private(set) var hasConflict = false

    init(registrar: ClipboardHotKeyRegistrar, onActivate: @escaping () -> Void) {
        self.registrar = registrar
        self.onActivate = onActivate
    }

    var isRegistered: Bool {
        activeIdentifier != nil
    }

    /// Applies a shortcut, returning whether registration succeeded. On failure the
    /// previous shortcut stays registered and `hasConflict` becomes true.
    @discardableResult
    func apply(_ shortcut: Shortcut) -> Bool {
        guard shortcut.isActive else {
            unregister()
            hasConflict = false
            return true
        }
        if shortcut == activeShortcut, activeIdentifier != nil {
            return true
        }

        let identifier = nextIdentifier
        nextIdentifier &+= 1
        let succeeded = registrar.register(
            keyCode: UInt32(shortcut.keyCode),
            modifiers: Self.carbonModifiers(shortcut.modifiers),
            identifier: identifier,
            handler: onActivate
        )
        guard succeeded else {
            hasConflict = true
            return false
        }
        if let previous = activeIdentifier {
            registrar.unregister(identifier: previous)
        }
        activeIdentifier = identifier
        activeShortcut = shortcut
        hasConflict = false
        return true
    }

    func unregister() {
        if let identifier = activeIdentifier {
            registrar.unregister(identifier: identifier)
        }
        activeIdentifier = nil
        activeShortcut = nil
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

/// Production Carbon registrar. Installs one application event handler and routes
/// hotkey events to per-identifier handlers.
final class CarbonHotKeyRegistrar: ClipboardHotKeyRegistrar {
    static let carbonSignature: OSType = 0x454B_4859

    private var handlers: [UInt32: () -> Void] = [:]
    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?

    init() {
        installEventHandlerIfNeeded()
    }

    func register(keyCode: UInt32, modifiers: UInt32, identifier: UInt32, handler: @escaping () -> Void) -> Bool {
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.carbonSignature, id: identifier)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else { return false }
        refs[identifier] = ref
        handlers[identifier] = handler
        return true
    }

    func unregister(identifier: UInt32) {
        if let ref = refs.removeValue(forKey: identifier) {
            UnregisterEventHotKey(ref)
        }
        handlers.removeValue(forKey: identifier)
    }

    fileprivate func handle(identifier: UInt32) {
        handlers[identifier]?()
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), carbonHotKeyEventHandler, 1, &spec, context, &eventHandler)
    }
}

private func carbonHotKeyEventHandler(
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
    let registrar = Unmanaged<CarbonHotKeyRegistrar>.fromOpaque(userData).takeUnretainedValue()
    registrar.handle(identifier: hotKeyID.id)
    return noErr
}
