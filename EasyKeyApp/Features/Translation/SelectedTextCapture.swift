import AppKit
import ApplicationServices
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
    private let frontmostApplication: @MainActor () -> NSRunningApplication?
    private let activateEasyKey: @MainActor () -> Void
    private let maximumLength: Int

    private(set) var previousApplication: NSRunningApplication?

    init(
        selectedTextReader: SelectedTextReading = AccessibilitySelectedTextReader(),
        pasteboardReader: PasteboardReading = SystemPasteboardReader(),
        frontmostApplication: @escaping @MainActor () -> NSRunningApplication? = { NSWorkspace.shared.frontmostApplication },
        activateEasyKey: @escaping @MainActor () -> Void = { NSApp.activate(ignoringOtherApps: true) },
        maximumLength: Int = TranslationRequest.maximumSourceTextLength
    ) {
        self.selectedTextReader = selectedTextReader
        self.pasteboardReader = pasteboardReader
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
