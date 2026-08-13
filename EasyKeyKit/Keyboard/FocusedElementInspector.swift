import ApplicationServices
import EasyEngineCore
import Foundation

enum FocusedElementInspector {
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
}
