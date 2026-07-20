import AppKit
import SwiftUI

struct TranslationTextEditor: NSViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var onTranslateTriggered: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollablePlainDocumentContentTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.isRichText = false
        textView.isEditable = true
        textView.drawsBackground = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context _: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        if isFocused, let window = textView.window, window.firstResponder != textView {
            window.makeFirstResponder(textView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onTranslateTriggered: onTranslateTriggered)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private var textBinding: Binding<String>
        private let onTranslateTriggered: () -> Void
        weak var textView: NSTextView?

        init(
            text: Binding<String>,
            onTranslateTriggered: @escaping () -> Void
        ) {
            textBinding = text
            self.onTranslateTriggered = onTranslateTriggered
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            textBinding.wrappedValue = textView.string
        }

        func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                let flags = NSApp.currentEvent?.modifierFlags ?? []
                if flags.contains(.shift) {
                    return false
                }
                onTranslateTriggered()
                return true
            }
            return false
        }
    }
}
