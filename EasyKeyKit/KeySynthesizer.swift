import CoreGraphics
import EasyEngineCore
import Foundation

public final class KeySynthesizer {
    typealias EventFactory = (UInt16, Bool) -> CGEvent?

    enum ReplacementStrategy: Equatable {
        case failed
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

    private struct UnicodeEventPair {
        let chunk: String
        let keyDown: CGEvent
        let keyUp: CGEvent
    }

    private static let selfPostedEventMarker: Int64 = 0x45_4153_594B_4559

    private let focusedTextReplacer: ([Int], String) -> FocusedElementInspector.FocusedTextReplacementResult
    private let eventFactory: EventFactory
    private var encodedUnitStack: [EncodedUnit] = []
    private var pendingEmptyCharacter = false

    public init() {
        let eventSource = CGEventSource(stateID: .privateState)
        focusedTextReplacer = FocusedElementInspector.replaceFocusedText
        eventFactory = { keyCode, keyDown in
            CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(keyCode), keyDown: keyDown)
        }
    }

    init(
        focusedTextReplacer: @escaping ([Int], String) -> FocusedElementInspector.FocusedTextReplacementResult,
        eventFactory: EventFactory? = nil
    ) {
        self.focusedTextReplacer = focusedTextReplacer
        if let eventFactory {
            self.eventFactory = eventFactory
        } else {
            let eventSource = CGEventSource(stateID: .privateState)
            self.eventFactory = { keyCode, keyDown in
                CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(keyCode), keyDown: keyDown)
            }
        }
    }

    @discardableResult
    public func postBackspace(proxy: CGEventTapProxy, count: Int = 1) -> Bool {
        guard count > 0 else { return true }
        guard let events = makePhysicalKeyEvents(keyCode: 51, modifiers: [], count: count) else { return false }
        post(events, proxy: proxy)
        return true
    }

    @discardableResult
    public func postUnicodeText(proxy: CGEventTapProxy, _ text: String) -> Bool {
        postUnicodeText(proxy: proxy, text, encodedUnits: text.map(String.init))
    }

    @discardableResult
    public func postPhysicalKey(proxy: CGEventTapProxy, keyCode: UInt16, modifiers: CGEventFlags = []) -> Bool {
        guard let events = makePhysicalKeyEvents(keyCode: keyCode, modifiers: modifiers, count: 1) else { return false }
        post(events, proxy: proxy)
        return true
    }

    @discardableResult
    public func postShiftLeft(proxy: CGEventTapProxy, count: Int) -> Bool {
        guard count > 0 else { return true }
        guard let events = makePhysicalKeyEvents(keyCode: 123, modifiers: .maskShift, count: count) else { return false }
        post(events, proxy: proxy)
        return true
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

        if useSelectionReplacement {
            let selectionCount = selectionDeleteCount(deleteCount)
            guard let selectionEvents = makePhysicalKeyEvents(
                keyCode: 123,
                modifiers: .maskShift,
                count: selectionCount
            ), let insertionEvents = makeUnicodeEvents(text)
            else { return .failed }
            _ = prepareDeleteForSelection(deleteCount: deleteCount)
            post(selectionEvents, proxy: proxy)
            post(insertionEvents, proxy: proxy, encodedUnits: encodedUnits)
            return .selectionReplacement
        }

        let shouldBreakAutocomplete = breakAutocomplete || useFocusedTextReplacement
        guard let insertionEvents = makeUnicodeEvents(text),
              let breakEvents = makeUnicodeEvents(shouldBreakAutocomplete ? "\u{202F}" : ""),
              let breakBackspaceEvents = makePhysicalKeyEvents(
                  keyCode: 51,
                  modifiers: [],
                  count: shouldBreakAutocomplete ? 1 : 0
              ),
              let deletionEvents = makePhysicalKeyEvents(
                  keyCode: 51,
                  modifiers: [],
                  count: physicalDeleteCount(deleteCount)
              )
        else { return .failed }
        post(breakEvents, proxy: proxy, encodedUnits: [])
        post(breakBackspaceEvents, proxy: proxy)
        let removedUnits = prepareDelete(deleteCount: deleteCount)
        assert(removedUnits == deletionEvents.count)
        post(deletionEvents, proxy: proxy)
        post(insertionEvents, proxy: proxy, encodedUnits: encodedUnits)
        return shouldBreakAutocomplete ? .breakAutocompleteAndBackspace : .physicalBackspace
    }

    @discardableResult
    func insert(proxy: CGEventTapProxy, _ text: String, encodedUnits: [String]? = nil) -> Bool {
        guard let events = makeUnicodeEvents(text), clearPendingEmptyCharacter(proxy: proxy) else { return false }
        post(events, proxy: proxy, encodedUnits: encodedUnits ?? text.map(String.init))
        return true
    }

    @discardableResult
    func insertEmptyCharacter(proxy: CGEventTapProxy, _ text: String) -> Bool {
        guard let events = makeUnicodeEvents(text), clearPendingEmptyCharacter(proxy: proxy) else { return false }
        post(events, proxy: proxy, encodedUnits: [])
        pendingEmptyCharacter = true
        return true
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

    func postMacroExpansion(
        proxy: CGEventTapProxy,
        backspaceCount: Int,
        text: String,
        physicalKeyCode: UInt16,
        useSelectionReplacement: Bool,
        breakAutocomplete: Bool
    ) -> Bool {
        let encodedUnits = text.map(String.init)

        if useSelectionReplacement {
            let selectionCount = macroExpansionSelectionCount(backspaceCount)
            guard let selectionEvents = makePhysicalKeyEvents(
                keyCode: 123,
                modifiers: .maskShift,
                count: selectionCount
            ), let insertionEvents = makeUnicodeEvents(text),
            let delimiterEvents = makePhysicalKeyEvents(keyCode: physicalKeyCode, modifiers: [], count: 1)
            else { return false }
            _ = prepareDeleteForSelection(deleteCount: backspaceCount)
            post(selectionEvents, proxy: proxy)
            post(insertionEvents, proxy: proxy, encodedUnits: encodedUnits)
            post(delimiterEvents, proxy: proxy)
            return true
        }

        let physicalCount = macroExpansionDeleteCount(backspaceCount)
        guard let insertionEvents = makeUnicodeEvents(text),
              let breakEvents = makeUnicodeEvents(breakAutocomplete ? "\u{202F}" : ""),
              let breakBackspaceEvents = makePhysicalKeyEvents(
                  keyCode: 51,
                  modifiers: [],
                  count: breakAutocomplete ? 1 : 0
              ),
              let deletionEvents = makePhysicalKeyEvents(keyCode: 51, modifiers: [], count: physicalCount),
              let delimiterEvents = makePhysicalKeyEvents(keyCode: physicalKeyCode, modifiers: [], count: 1)
        else { return false }
        post(breakEvents, proxy: proxy, encodedUnits: [])
        post(breakBackspaceEvents, proxy: proxy)
        _ = prepareDelete(deleteCount: backspaceCount)
        post(deletionEvents, proxy: proxy)
        post(insertionEvents, proxy: proxy, encodedUnits: encodedUnits)
        post(delimiterEvents, proxy: proxy)
        return true
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

    private func clearPendingEmptyCharacter(proxy: CGEventTapProxy) -> Bool {
        guard pendingEmptyCharacter else { return true }
        guard postBackspace(proxy: proxy, count: 1) else { return false }
        pendingEmptyCharacter = false
        return true
    }

    @discardableResult
    private func postUnicodeText(proxy: CGEventTapProxy, _ text: String, encodedUnits: [String]) -> Bool {
        guard let events = makeUnicodeEvents(text) else { return false }
        post(events, proxy: proxy, encodedUnits: encodedUnits)
        return true
    }

    private func makeUnicodeEvents(_ text: String) -> [UnicodeEventPair]? {
        var events: [UnicodeEventPair] = []
        let chunks = utf16Chunks(in: text)
        events.reserveCapacity(chunks.count)
        for chunk in chunks {
            guard let keyDown = eventFactory(0, true),
                  let keyUp = eventFactory(0, false)
            else {
                AppLog.error(.synth, "Failed to create unicode key events")
                return nil
            }
            events.append(UnicodeEventPair(chunk: chunk, keyDown: keyDown, keyUp: keyUp))
        }
        return events
    }

    private func post(_ events: [UnicodeEventPair], proxy: CGEventTapProxy, encodedUnits: [String]) {
        for event in events {
            let keyDown = event.keyDown
            let keyUp = event.keyUp
            Self.markAsSelfPosted(keyDown)
            Self.markAsSelfPosted(keyUp)
            let units = Array(event.chunk.utf16)
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

    private func physicalDeleteCount(_ logicalCount: Int) -> Int {
        let pendingCount = pendingEmptyCharacter ? 1 : 0
        let count = min(max(0, logicalCount), encodedUnitStack.count)
        return pendingCount + encodedUnitStack.suffix(count).reduce(0) { $0 + $1.utf16 }
    }

    private func selectionDeleteCount(_ logicalCount: Int) -> Int {
        let pendingCount = pendingEmptyCharacter ? 1 : 0
        let count = min(max(0, logicalCount), encodedUnitStack.count)
        return pendingCount + encodedUnitStack.suffix(count).reduce(0) { $0 + $1.graphemes }
    }

    private func macroExpansionDeleteCount(_ logicalCount: Int) -> Int {
        guard encodedUnitStack.count >= logicalCount else {
            return logicalCount + (pendingEmptyCharacter ? 1 : 0)
        }
        return physicalDeleteCount(logicalCount)
    }

    private func macroExpansionSelectionCount(_ logicalCount: Int) -> Int {
        guard encodedUnitStack.count >= logicalCount else {
            return logicalCount + (pendingEmptyCharacter ? 1 : 0)
        }
        return selectionDeleteCount(logicalCount)
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

    private func makePhysicalKeyEvents(
        keyCode: UInt16,
        modifiers: CGEventFlags,
        count: Int
    ) -> [(keyDown: CGEvent, keyUp: CGEvent)]? {
        var events: [(keyDown: CGEvent, keyUp: CGEvent)] = []
        events.reserveCapacity(count)
        for _ in 0 ..< count {
            guard let keyDown = eventFactory(keyCode, true), let keyUp = eventFactory(keyCode, false) else {
                AppLog.error(.synth, "Failed to create physical key events keyCode=\(keyCode)")
                return nil
            }
            keyDown.flags = modifiers
            keyUp.flags = modifiers
            Self.markAsSelfPosted(keyDown)
            Self.markAsSelfPosted(keyUp)
            events.append((keyDown, keyUp))
        }
        return events
    }

    private func post(_ events: [(keyDown: CGEvent, keyUp: CGEvent)], proxy: CGEventTapProxy) {
        for event in events {
            event.keyDown.tapPostEvent(proxy)
            event.keyUp.tapPostEvent(proxy)
        }
    }

    public static func markAsSelfPosted(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: selfPostedEventMarker)
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

struct MacroExpansion {
    let triggerLength: Int
    let text: String
}

struct MacroExpander {
    private static let delimiterKeyCodes: Set<UInt16> = [36, 48, 49]

    private var macros: [Macro] = []
    private var trigger = ""
    /// Secondary defense against macro self-recursion loops (primary defense is KeySynthesizer.isSelfPosted).
    private(set) var inMacroExpansion = false

    mutating func update(macros: [Macro]) {
        self.macros = macros
        trigger = ""
        inMacroExpansion = false
    }

    mutating func reset() {
        trigger = ""
    }

    mutating func consume(
        character: Character,
        keyCode: UInt16,
        modifiers: Shortcut.ModifierFlags,
        options: MacroOptions,
        language: InputLanguage
    ) -> MacroExpansion? {
        guard !inMacroExpansion,
              options.enabled,
              modifiers.isEmpty
        else {
            trigger = ""
            return nil
        }

        guard Self.delimiterKeyCodes.contains(keyCode) else {
            guard !character.isWhitespace else {
                trigger = ""
                return nil
            }
            trigger.append(character)
            if trigger.count > MacroStore.maximumTriggerLength {
                trigger.removeFirst(trigger.count - MacroStore.maximumTriggerLength)
            }
            return nil
        }

        defer { trigger = "" }
        guard let macro = macros.first(where: {
            $0.isEnabled
                && $0.category.matches(language)
                && $0.trigger.compare(trigger, options: .caseInsensitive) == .orderedSame
        })
        else {
            return nil
        }
        let text = options.autoCapitalize
            ? MacroStore.matchCapitalization(of: trigger, in: macro.expansion)
            : macro.expansion
        return MacroExpansion(triggerLength: trigger.count, text: text)
    }
}
