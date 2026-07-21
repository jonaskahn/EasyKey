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
    case pasteboard
    case blank
}

struct SelectedTextCaptureResult: Equatable {
    let text: String
    let source: SelectedTextCaptureSource
    let accessibilityResult: SelectedTextReadResult

    var isOrdinaryAbsence: Bool {
        accessibilityResult == .absent
    }
}

@MainActor
final class SelectedTextCaptureCoordinator {
    private let selectedTextReader: SelectedTextReading
    private let pasteboardReader: PasteboardReading
    private let simulatedCopy: SelectedTextSimulating?
    private let frontmostApplication: @MainActor () -> NSRunningApplication?
    private let activateEasyKey: @MainActor () -> Void
    private let maximumLength: Int

    private(set) var previousApplication: NSRunningApplication?

    init(
        selectedTextReader: SelectedTextReading = AccessibilitySelectedTextReader(),
        pasteboardReader: PasteboardReading = SystemPasteboardReader(),
        simulatedCopy: SelectedTextSimulating? = SystemSelectedTextSimulator(),
        frontmostApplication: @escaping @MainActor () -> NSRunningApplication? = { NSWorkspace.shared.frontmostApplication },
        activateEasyKey: @escaping @MainActor () -> Void = { NSApp.activate(ignoringOtherApps: true) },
        maximumLength: Int = TranslationRequest.maximumSourceTextLength
    ) {
        self.selectedTextReader = selectedTextReader
        self.pasteboardReader = pasteboardReader
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
        } else if let text = captureViaSimulatedCopy() {
            result = SelectedTextCaptureResult(
                text: text,
                source: .simulatedCopy,
                accessibilityResult: accessibilityResult
            )
        } else if let text = readPlainTextPasteboard() {
            result = SelectedTextCaptureResult(
                text: text,
                source: .pasteboard,
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

    private func readPlainTextPasteboard() -> String? {
        let initialChangeCount = pasteboardReader.changeCount
        let descriptor = pasteboardReader.descriptor()
        guard descriptor.changeCount == initialChangeCount,
              !SensitivePasteboardMarkers.contains(descriptor.items.flatMap(\.typeIdentifiers))
        else {
            return nil
        }

        let selection = descriptor.items.map { item in
            item.typeIdentifiers.contains(PasteboardClassifier.plainText) ? [PasteboardClassifier.plainText] : []
        }
        guard selection.contains(where: { !$0.isEmpty }) else { return nil }

        let snapshot = pasteboardReader.snapshot(selecting: selection)
        guard snapshot.changeCount == initialChangeCount,
              pasteboardReader.changeCount == initialChangeCount
        else {
            return nil
        }

        for item in snapshot.items {
            guard let representation = item.representations.first(where: {
                $0.typeIdentifier == PasteboardClassifier.plainText
            }),
                let text = String(data: representation.data, encoding: .utf8),
                !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                text.count <= maximumLength
            else {
                continue
            }
            return text
        }
        return nil
    }
}

protocol SelectedTextSimulating: AnyObject {
    func copySelection(from app: NSRunningApplication?) -> String?
}

final class SystemSelectedTextSimulator: SelectedTextSimulating {
    private let pasteboard: NSPasteboard
    private let eventSource: CGEventSource?
    private let activationTimeBudget: TimeInterval

    init(
        pasteboard: NSPasteboard = .general,
        eventSource: CGEventSource? = CGEventSource(stateID: .privateState),
        activationTimeBudget: TimeInterval = 0.2
    ) {
        self.pasteboard = pasteboard
        self.eventSource = eventSource
        self.activationTimeBudget = activationTimeBudget
    }

    func copySelection(from app: NSRunningApplication?) -> String? {
        let savedItems = pasteboard.pasteboardItems
        let savedChangeCount = pasteboard.changeCount

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

        restorePasteboard(savedItems: savedItems, savedChangeCount: savedChangeCount)

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

    private func restorePasteboard(
        savedItems: [NSPasteboardItem]?,
        savedChangeCount _: Int
    ) {
        guard let savedItems, !savedItems.isEmpty else { return }
        pasteboard.clearContents()
        pasteboard.writeObjects(savedItems)
    }
}
