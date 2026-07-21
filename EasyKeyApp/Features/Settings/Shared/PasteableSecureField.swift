import AppKit
import SwiftUI

/// NSSecureTextField wrapper so Cmd+V / Edit ▸ Paste updates the binding immediately.
/// SwiftUI `SecureField` in accessory apps often fails to paste or lags the binding.
struct PasteableSecureField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var accessibilityLabel: String?
    var accessibilityIdentifier: String?
    var onSubmit: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> BindingSecureTextField {
        let field = BindingSecureTextField()
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.isEditable = true
        field.isSelectable = true
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.focusRingType = .default
        field.delegate = context.coordinator
        field.target = context.coordinator
        field.action = #selector(Coordinator.commit(_:))
        field.onTextChange = { [weak coordinator = context.coordinator] value in
            coordinator?.parent.text = value
        }
        field.stringValue = text
        field.placeholderString = placeholder
        applyAccessibility(to: field)
        return field
    }

    func updateNSView(_ field: BindingSecureTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text {
            field.stringValue = text
        }
        if field.placeholderString != placeholder {
            field.placeholderString = placeholder
        }
        applyAccessibility(to: field)
    }

    private func applyAccessibility(to field: BindingSecureTextField) {
        if let accessibilityLabel {
            field.setAccessibilityLabel(accessibilityLabel)
        }
        if let accessibilityIdentifier {
            field.setAccessibilityIdentifier(accessibilityIdentifier)
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: PasteableSecureField

        init(_ parent: PasteableSecureField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSecureTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let field = control as? NSSecureTextField {
                    parent.text = field.stringValue
                }
                parent.onSubmit?()
                return true
            }
            return false
        }

        @objc func commit(_ sender: NSSecureTextField) {
            parent.text = sender.stringValue
            parent.onSubmit?()
        }
    }
}

final class BindingSecureTextField: NSSecureTextField {
    var onTextChange: ((String) -> Void)?

    @objc func paste(_: Any?) {
        let pasted = NSPasteboard.general.string(forType: .string) ?? ""
        if let editor = currentEditor() as? NSTextView {
            editor.insertText(pasted, replacementRange: editor.selectedRange())
        } else if !pasted.isEmpty {
            stringValue = pasted
        }
        onTextChange?(stringValue)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags == .command,
              let character = event.charactersIgnoringModifiers?.lowercased()
        else {
            return super.performKeyEquivalent(with: event)
        }

        switch character {
        case "v":
            paste(nil)
            return true
        case "c":
            NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
            return true
        case "x":
            NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
            onTextChange?(stringValue)
            return true
        case "a":
            NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self)
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}
