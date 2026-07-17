import CoreGraphics
import EasyEngineCore
import Foundation

public final class KeySynthesizer {
    enum ReplacementStrategy: Equatable {
        case atomicFocusedText
        case atomicFocusedTextCaretUnknown
        case selectionReplacement
        case breakAutocompleteAndBackspace
        case physicalBackspace
    }

    private struct EncodedUnit {
        let utf16: Int
        let graphemes: Int
    }

    private static let selfPostedEventMarker: Int64 = 0x45_4153_594B_4559

    private let eventSource: CGEventSource?
    private let focusedTextReplacer: ([Int], String) -> FocusedElementInspector.FocusedTextReplacementResult
    private var encodedUnitStack: [EncodedUnit] = []
    private var pendingEmptyCharacter = false

    public init() {
        eventSource = CGEventSource(stateID: .privateState)
        focusedTextReplacer = FocusedElementInspector.replaceFocusedText
    }

    init(
        focusedTextReplacer: @escaping ([Int], String) -> FocusedElementInspector.FocusedTextReplacementResult
    ) {
        eventSource = CGEventSource(stateID: .privateState)
        self.focusedTextReplacer = focusedTextReplacer
    }

    public func postBackspace(proxy: CGEventTapProxy, count: Int = 1) {
        guard count > 0 else { return }
        for _ in 0 ..< count {
            postPhysicalKey(proxy: proxy, keyCode: 51)
        }
    }

    public func postUnicodeText(proxy: CGEventTapProxy, _ text: String) {
        postUnicodeText(proxy: proxy, text, encodedUnits: text.map(String.init))
    }

    public func postPhysicalKey(proxy: CGEventTapProxy, keyCode: UInt16, modifiers: CGEventFlags = []) {
        postKeyEvent(proxy: proxy, keyCode: keyCode, modifiers: modifiers, keyDown: true)
        postKeyEvent(proxy: proxy, keyCode: keyCode, modifiers: modifiers, keyDown: false)
    }

    public func postShiftLeft(proxy: CGEventTapProxy, count: Int) {
        guard count > 0 else { return }
        for _ in 0 ..< count {
            postPhysicalKey(proxy: proxy, keyCode: 123, modifiers: .maskShift)
        }
    }

    public func postCut(proxy: CGEventTapProxy) {
        postPhysicalKey(proxy: proxy, keyCode: 7, modifiers: .maskCommand)
    }

    @discardableResult
    func replaceBackward(
        proxy: CGEventTapProxy,
        deleteCount: Int,
        insert text: String,
        encodedUnits: [String],
        useFocusedTextReplacement: Bool,
        useSelectionReplacement: Bool = false,
        breakAutocomplete: Bool = false
    ) -> ReplacementStrategy {
        if useFocusedTextReplacement,
           !pendingEmptyCharacter,
           deleteCount >= 0,
           deleteCount <= encodedUnitStack.count {
            let deletedLengths = encodedUnitStack.suffix(deleteCount).map(\.utf16)
            switch focusedTextReplacer(deletedLengths, text) {
            case .succeeded:
                _ = removeEncodedUnits(deleteCount)
                trackEncodedUnits(encodedUnits)
                return .atomicFocusedText
            case .valueChangedCaretUnknown:
                resetEncodedUnits()
                return .atomicFocusedTextCaretUnknown
            case .failed:
                break
            }
        }

        // Spotlight path: backspaces get swallowed by the panel's provisional
        // autocomplete selection, but arrow keys cancel it. Select the composed
        // text with Shift+Left and type the replacement over the selection.
        if useSelectionReplacement {
            let selectionCount = prepareDeleteForSelection(deleteCount: deleteCount)
            postShiftLeft(proxy: proxy, count: selectionCount)
            postUnicodeText(proxy: proxy, text, encodedUnits: encodedUnits)
            return .selectionReplacement
        }

        let shouldBreakAutocomplete = breakAutocomplete || useFocusedTextReplacement
        if shouldBreakAutocomplete {
            postUnicodeText(proxy: proxy, "\u{202F}", encodedUnits: [])
            postBackspace(proxy: proxy, count: 1)
        }
        let removedUnits = prepareDelete(deleteCount: deleteCount)
        postBackspace(proxy: proxy, count: removedUnits)
        postUnicodeText(proxy: proxy, text, encodedUnits: encodedUnits)
        return shouldBreakAutocomplete ? .breakAutocompleteAndBackspace : .physicalBackspace
    }

    func insert(proxy: CGEventTapProxy, _ text: String, encodedUnits: [String]? = nil) {
        clearPendingEmptyCharacter(proxy: proxy)
        postUnicodeText(proxy: proxy, text, encodedUnits: encodedUnits ?? text.map(String.init))
    }

    func insertEmptyCharacter(proxy: CGEventTapProxy, _ text: String) {
        clearPendingEmptyCharacter(proxy: proxy)
        postUnicodeText(proxy: proxy, text, encodedUnits: [])
        pendingEmptyCharacter = true
    }

    func resetEncodedUnits() {
        encodedUnitStack.removeAll(keepingCapacity: true)
        pendingEmptyCharacter = false
    }

    public static func isSelfPosted(_ event: CGEvent) -> Bool {
        guard event.getIntegerValueField(.eventSourceUserData) == selfPostedEventMarker else {
            return false
        }
        return CGEventSource(event: event)?.sourceStateID == .privateState
    }

    var encodedUnitCount: Int {
        encodedUnitStack.count
    }

    var hasPendingEmptyCharacter: Bool {
        pendingEmptyCharacter
    }

    @discardableResult
    func prepareDelete(deleteCount: Int) -> Int {
        var physicalCount = 0
        if pendingEmptyCharacter {
            physicalCount += 1
            pendingEmptyCharacter = false
        }
        physicalCount += removeEncodedUnits(deleteCount)
        return physicalCount
    }

    /// Like `prepareDelete`, but counts graphemes: arrow keys move the caret per
    /// grapheme cluster, while backspaces are tracked per UTF-16 unit.
    @discardableResult
    func prepareDeleteForSelection(deleteCount: Int) -> Int {
        var selectionCount = 0
        if pendingEmptyCharacter {
            selectionCount += 1
            pendingEmptyCharacter = false
        }
        selectionCount += removeEncodedUnitGraphemes(deleteCount)
        return selectionCount
    }

    func trackEncodedUnits(_ encodedUnits: [String]) {
        encodedUnitStack.append(contentsOf: encodedUnits.map {
            EncodedUnit(utf16: $0.utf16.count, graphemes: $0.count)
        })
    }

    func markPendingEmptyCharacter() {
        pendingEmptyCharacter = true
    }

    private func clearPendingEmptyCharacter(proxy: CGEventTapProxy) {
        guard pendingEmptyCharacter else { return }
        postBackspace(proxy: proxy, count: 1)
        pendingEmptyCharacter = false
    }

    private func postUnicodeText(proxy: CGEventTapProxy, _ text: String, encodedUnits: [String]) {
        guard !text.isEmpty else { return }

        for chunk in utf16Chunks(in: text) {
            guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false)
            else {
                AppLog.error(.synth, "Failed to create unicode key events")
                continue
            }
            markAsSelfPosted(keyDown)
            markAsSelfPosted(keyUp)
            let units = Array(chunk.utf16)
            units.withUnsafeBufferPointer { buffer in
                keyDown.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
            }
            keyDown.tapPostEvent(proxy)
            keyUp.tapPostEvent(proxy)
        }

        encodedUnitStack.append(contentsOf: encodedUnits.map {
            EncodedUnit(utf16: $0.utf16.count, graphemes: $0.count)
        })
    }

    private func removeEncodedUnits(_ logicalCount: Int) -> Int {
        guard logicalCount > 0 else { return 0 }
        var deletedUnits = 0
        for _ in 0 ..< min(logicalCount, encodedUnitStack.count) {
            let unit = encodedUnitStack.removeLast()
            deletedUnits += unit.utf16
        }
        return deletedUnits
    }

    private func removeEncodedUnitGraphemes(_ logicalCount: Int) -> Int {
        guard logicalCount > 0 else { return 0 }
        var deletedGraphemes = 0
        for _ in 0 ..< min(logicalCount, encodedUnitStack.count) {
            let unit = encodedUnitStack.removeLast()
            deletedGraphemes += unit.graphemes
        }
        return deletedGraphemes
    }

    private func postKeyEvent(proxy: CGEventTapProxy, keyCode: UInt16, modifiers: CGEventFlags, keyDown: Bool) {
        guard let event = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(keyCode), keyDown: keyDown) else {
            AppLog.error(.synth, "Failed to create physical key event keyCode=\(keyCode)")
            return
        }
        event.flags = modifiers
        markAsSelfPosted(event)
        event.tapPostEvent(proxy)
    }

    private func markAsSelfPosted(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: Self.selfPostedEventMarker)
    }

    private func utf16Chunks(in text: String) -> [String] {
        let units = Array(text.utf16)
        var chunks: [String] = []
        var index = 0

        while index < units.count {
            var end = min(index + 16, units.count)
            if end < units.count, (0xD800 ... 0xDBFF).contains(units[end - 1]) {
                end -= 1
            }
            chunks.append(String(decoding: units[index ..< end], as: UTF16.self))
            index = end
        }

        return chunks
    }
}
