import ApplicationServices
import EasyEngineCore
import Foundation

enum FocusedElementInspector {
    enum FocusedTextReplacementResult: Equatable {
        case failed
        case succeeded
        case valueChangedCaretUnknown
    }

    struct TextReplacement: Equatable {
        let value: String
        let caretRange: NSRange
    }

    private static let chromiumAddressBarDescriptions: Set<String> = [
        "Address and search bar",
        "Address field",
    ]

    static func isChromiumAddressBar() -> Bool {
        guard let element = focusedElement() else { return false }
        if let description = stringAttribute(element, kAXDescriptionAttribute as String),
           chromiumAddressBarDescriptions.contains(description) {
            return true
        }
        if let identifier = stringAttribute(element, kAXIdentifierAttribute as String),
           identifier.localizedCaseInsensitiveContains("omnibox") {
            return true
        }
        return false
    }

    static func replaceFocusedText(
        deletedUnitLengths: [Int],
        replacement text: String
    ) -> FocusedTextReplacementResult {
        guard let element = focusedElement(),
              let value = stringAttribute(element, kAXValueAttribute as String),
              let selectedRange = rangeAttribute(element, kAXSelectedTextRangeAttribute as String),
              let edit = replacement(
                  value: value,
                  selectedRange: selectedRange,
                  deletedUnitLengths: deletedUnitLengths,
                  replacement: text
              ),
              isSettable(element, kAXValueAttribute as String),
              isSettable(element, kAXSelectedTextRangeAttribute as String)
        else {
            return .failed
        }

        let valueStatus = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            edit.value as CFString
        )
        guard valueStatus == .success else {
            AppLog.debug(.keyboard, "AX focused value replacement failed status=\(valueStatus.rawValue)")
            return .failed
        }

        var caret = CFRange(location: edit.caretRange.location, length: 0)
        guard let caretValue = AXValueCreate(.cfRange, &caret) else {
            AppLog.debug(.keyboard, "AX focused caret value creation failed")
            return .valueChangedCaretUnknown
        }
        let caretStatus = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            caretValue
        )
        if caretStatus != .success {
            AppLog.debug(.keyboard, "AX focused caret update failed status=\(caretStatus.rawValue)")
            return .valueChangedCaretUnknown
        }
        return .succeeded
    }

    static func replacement(
        value: String,
        selectedRange: NSRange,
        deletedUnitLengths: [Int],
        replacement text: String
    ) -> TextReplacement? {
        let valueLength = value.utf16.count
        guard selectedRange.location >= 0,
              selectedRange.length >= 0,
              selectedRange.location <= valueLength,
              selectedRange.length <= valueLength - selectedRange.location
        else {
            return nil
        }

        var deletedLength = 0
        for length in deletedUnitLengths {
            guard length >= 0 else { return nil }
            let (sum, overflow) = deletedLength.addingReportingOverflow(length)
            guard !overflow else { return nil }
            deletedLength = sum
        }
        guard deletedLength <= selectedRange.location else { return nil }

        let replacementRange = NSRange(
            location: selectedRange.location - deletedLength,
            length: deletedLength + selectedRange.length
        )
        let mutableValue = NSMutableString(string: value)
        mutableValue.replaceCharacters(in: replacementRange, with: text)
        let caretLocation = replacementRange.location + text.utf16.count
        return TextReplacement(
            value: mutableValue as String,
            caretRange: NSRange(location: caretLocation, length: 0)
        )
    }

    private static func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focused
        )
        guard status == .success, let focused else {
            if status != .success {
                AppLog.debug(.keyboard, "AX focused element unavailable status=\(status.rawValue)")
            }
            return nil
        }
        guard CFGetTypeID(focused) == AXUIElementGetTypeID() else {
            AppLog.debug(.keyboard, "AX focused value is not an AXUIElement")
            return nil
        }
        return unsafeBitCast(focused, to: AXUIElement.self)
    }

    private static func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success, let value else { return nil }
        return value as? String
    }

    private static func rangeAttribute(_ element: AXUIElement, _ attribute: String) -> NSRange? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID()
        else {
            return nil
        }

        let axValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cfRange else { return nil }
        var range = CFRange()
        guard AXValueGetValue(axValue, .cfRange, &range) else { return nil }
        return NSRange(location: range.location, length: range.length)
    }

    private static func isSettable(_ element: AXUIElement, _ attribute: String) -> Bool {
        var settable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, attribute as CFString, &settable) == .success
            && settable.boolValue
    }
}
