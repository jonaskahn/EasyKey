import AppKit
import ApplicationServices
import Carbon.HIToolbox
import CoreGraphics
import EasyEngineCore
import Foundation

enum SelectedTextReadResult: Equatable {
    case text(String)
    case absent
    case permissionDenied
    case secureField
    case unsupportedRole
    case inaccessible
    case oversized
}

protocol SelectedTextReading {
    func readSelectedText() -> SelectedTextReadResult
}

struct AccessibilityElementReference {
    fileprivate let value: AnyObject

    init(_ value: AnyObject) {
        self.value = value
    }
}

enum AccessibilityStringRead: Equatable {
    case value(String)
    case noValue
    case unsupported
    case failed
}

protocol AccessibilitySelectedTextAccessing {
    var isProcessTrusted: Bool { get }
    func focusedElement() -> AccessibilityElementReference?
    func stringAttribute(_ attribute: String, of element: AccessibilityElementReference) -> AccessibilityStringRead
}

final class SystemAccessibilitySelectedTextAccess: AccessibilitySelectedTextAccessing {
    var isProcessTrusted: Bool {
        AXIsProcessTrusted()
    }

    func focusedElement() -> AccessibilityElementReference? {
        let systemWide = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &value
        ) == .success,
            let value,
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return nil
        }
        return AccessibilityElementReference(value as AnyObject)
    }

    func stringAttribute(_ attribute: String, of element: AccessibilityElementReference) -> AccessibilityStringRead {
        let axElement = unsafeBitCast(element.value, to: AXUIElement.self)
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(axElement, attribute as CFString, &value)
        switch status {
        case .success:
            guard let string = value as? String else { return .failed }
            return .value(string)
        case .noValue:
            return .noValue
        case .attributeUnsupported:
            return .unsupported
        default:
            return .failed
        }
    }
}

struct AccessibilitySelectedTextReader: SelectedTextReading {
    private static let supportedRoles: Set<String> = [
        kAXTextFieldRole as String,
        kAXTextAreaRole as String,
        kAXComboBoxRole as String,
        kAXStaticTextRole as String,
        "AXWebArea",
    ]

    private let access: AccessibilitySelectedTextAccessing
    private let maximumLength: Int

    init(
        access: AccessibilitySelectedTextAccessing = SystemAccessibilitySelectedTextAccess(),
        maximumLength: Int = TranslationRequest.maximumSourceTextLength
    ) {
        self.access = access
        self.maximumLength = maximumLength
    }

    func readSelectedText() -> SelectedTextReadResult {
        guard access.isProcessTrusted else { return .permissionDenied }
        guard let element = access.focusedElement() else { return .inaccessible }

        guard case let .value(role) = access.stringAttribute(kAXRoleAttribute as String, of: element) else {
            return .inaccessible
        }
        guard Self.supportedRoles.contains(role) else { return .unsupportedRole }

        switch access.stringAttribute(kAXSubroleAttribute as String, of: element) {
        case let .value(subrole) where subrole == kAXSecureTextFieldSubrole as String:
            return .secureField
        case .failed:
            return .inaccessible
        case .value, .noValue, .unsupported:
            break
        }

        switch access.stringAttribute(kAXSelectedTextAttribute as String, of: element) {
        case let .value(text):
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .absent }
            guard text.count <= maximumLength else { return .oversized }
            return .text(text)
        case .noValue:
            return .absent
        case .unsupported, .failed:
            return .inaccessible
        }
    }
}

enum SelectedTextCaptureSource: Equatable {
    case accessibility
    case simulatedCopy
    case blank
}

struct SelectedTextCaptureResult: Equatable {
    let text: String
    let source: SelectedTextCaptureSource
    let accessibilityResult: SelectedTextReadResult
}

@MainActor
final class SelectedTextCaptureCoordinator {
    private let selectedTextReader: SelectedTextReading
    private let simulatedCopy: SelectedTextSimulating?
    private let frontmostApplication: @MainActor () -> NSRunningApplication?
    private let activateEasyKey: @MainActor () -> Void
    private let maximumLength: Int

    private(set) var previousApplication: NSRunningApplication?

    init(
        selectedTextReader: SelectedTextReading = AccessibilitySelectedTextReader(),
        simulatedCopy: SelectedTextSimulating? = SystemSelectedTextSimulator(),
        frontmostApplication: @escaping @MainActor () -> NSRunningApplication? = { NSWorkspace.shared.frontmostApplication },
        activateEasyKey: @escaping @MainActor () -> Void = { NSApp.activate(ignoringOtherApps: true) },
        maximumLength: Int = TranslationRequest.maximumSourceTextLength
    ) {
        self.selectedTextReader = selectedTextReader
        self.simulatedCopy = simulatedCopy
        self.frontmostApplication = frontmostApplication
        self.activateEasyKey = activateEasyKey
        self.maximumLength = maximumLength
    }

    func capture() -> SelectedTextCaptureResult {
        previousApplication = frontmostApplication()
        let accessibilityResult = selectedTextReader.readSelectedText()
        let result: SelectedTextCaptureResult
        if case let .text(text) = accessibilityResult {
            result = SelectedTextCaptureResult(
                text: text,
                source: .accessibility,
                accessibilityResult: accessibilityResult
            )
        } else if accessibilityResult != .secureField,
                  accessibilityResult != .oversized,
                  let text = captureViaSimulatedCopy() {
            result = SelectedTextCaptureResult(
                text: text,
                source: .simulatedCopy,
                accessibilityResult: accessibilityResult
            )
        } else {
            result = SelectedTextCaptureResult(
                text: "",
                source: .blank,
                accessibilityResult: accessibilityResult
            )
        }
        activateEasyKey()
        return result
    }

    private func captureViaSimulatedCopy() -> String? {
        guard let simulatedCopy else { return nil }
        guard let text = simulatedCopy.copySelection(from: previousApplication) else { return nil }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard text.count <= maximumLength else { return nil }
        return text
    }
}

protocol SelectedTextSimulating: AnyObject {
    func copySelection(from app: NSRunningApplication?) -> String?
}

/// Pasteboard surface the simulated-copy flow needs; protocol so tests can
/// substitute a fake (NSPasteboard itself cannot be subclassed).
protocol SelectedTextPasteboardAccessing: AnyObject {
    var pasteboardItems: [NSPasteboardItem]? { get }
    var changeCount: Int { get }
    func clearContents() -> Int
    func string(forType type: NSPasteboard.PasteboardType) -> String?
    func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool
}

final class SystemSelectedTextPasteboard: SelectedTextPasteboardAccessing {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var pasteboardItems: [NSPasteboardItem]? {
        pasteboard.pasteboardItems
    }

    var changeCount: Int {
        pasteboard.changeCount
    }

    func clearContents() -> Int {
        pasteboard.clearContents()
    }

    func string(forType type: NSPasteboard.PasteboardType) -> String? {
        pasteboard.string(forType: type)
    }

    func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool {
        pasteboard.writeObjects(objects)
    }
}

final class SystemSelectedTextSimulator: SelectedTextSimulating {
    private let pasteboard: SelectedTextPasteboardAccessing
    private let eventSource: CGEventSource?
    private let activationTimeBudget: TimeInterval

    init(
        pasteboard: SelectedTextPasteboardAccessing = SystemSelectedTextPasteboard(),
        eventSource: CGEventSource? = CGEventSource(stateID: .privateState),
        activationTimeBudget: TimeInterval = 0.2
    ) {
        self.pasteboard = pasteboard
        self.eventSource = eventSource
        self.activationTimeBudget = activationTimeBudget
    }

    func copySelection(from app: NSRunningApplication?) -> String? {
        let savedItems = pasteboard.pasteboardItems
        pasteboard.clearContents()
        let clearedChangeCount = pasteboard.changeCount

        postCopyKeyEvents(to: app)

        let deadline = Date().addingTimeInterval(activationTimeBudget)
        var capturedText: String?
        while Date() < deadline {
            if pasteboard.changeCount != clearedChangeCount {
                capturedText = pasteboard.string(forType: .string)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let text = capturedText, !text.isEmpty {
                    break
                }
            }
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        restorePasteboard(savedItems: savedItems)

        guard let text = capturedText, !text.isEmpty else { return nil }
        return text
    }

    private func postCopyKeyEvents(to app: NSRunningApplication?) {
        guard let source = eventSource else { return }

        let cmdDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(kVK_Command),
            keyDown: true
        )
        let cDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(kVK_ANSI_C),
            keyDown: true
        )
        let cUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(kVK_ANSI_C),
            keyDown: false
        )
        let cmdUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(kVK_Command),
            keyDown: false
        )

        cDown?.flags = .maskCommand
        cUp?.flags = .maskCommand

        if let pid = app?.processIdentifier {
            _ = cmdDown?.postToPid(pid)
            _ = cDown?.postToPid(pid)
            _ = cUp?.postToPid(pid)
            _ = cmdUp?.postToPid(pid)
        } else {
            _ = cmdDown?.post(tap: .cghidEventTap)
            _ = cDown?.post(tap: .cghidEventTap)
            _ = cUp?.post(tap: .cghidEventTap)
            _ = cmdUp?.post(tap: .cghidEventTap)
        }
    }

    private func restorePasteboard(savedItems: [NSPasteboardItem]?) {
        guard let savedItems, !savedItems.isEmpty else { return }
        let clonedItems = savedItems.map(Self.clone)
        pasteboard.clearContents()
        pasteboard.writeObjects(clonedItems)
    }

    /// `NSPasteboardItem` already bound to a pasteboard cannot be reused in a
    /// second `writeObjects:` call — AppKit throws `NSInvalidArgumentException`.
    /// Copy each type's data into a fresh item instead.
    private static func clone(_ item: NSPasteboardItem) -> NSPasteboardItem {
        let clone = NSPasteboardItem()
        for type in item.types {
            if let data = item.data(forType: type) {
                clone.setData(data, forType: type)
            }
        }
        return clone
    }
}
