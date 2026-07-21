import Carbon.HIToolbox
import CoreGraphics
import EasyEngineCore
import Foundation

struct KeyboardProcessResult {
    let suppressesOriginal: Bool
    let outputCount: Int
    let disposition: KeyboardService.Diagnostic.Disposition

    static let passed = KeyboardProcessResult(suppressesOriginal: false, outputCount: 0, disposition: .passed)
    static let suppressed = KeyboardProcessResult(suppressesOriginal: true, outputCount: 0, disposition: .suppressed)
    static let bypassed = KeyboardProcessResult(suppressesOriginal: false, outputCount: 0, disposition: .bypassed)
}

/// Applies Vietnamese engine transforms and posts synthesized key events.
final class KeyboardInputPipeline {
    private static let specialKeyKinds: [UInt16: KeyEvent.Kind] = [
        51: .backspace,
        117: .forwardDelete,
        123: .leftArrow,
        124: .rightArrow,
        125: .downArrow,
        126: .upArrow,
        36: .return,
        48: .tab,
        53: .escape,
        49: .space,
    ]

    typealias SpotlightVisibilityProvider = () -> Bool

    private let synthesizer: KeySynthesizer
    private var engine: VietnameseEngine
    private var settings: EasyKeySettings
    private var macroExpander = MacroExpander()
    private var activeBundleIdentifier: String?
    private var usesForeignInputSource = false
    private var cachedIsChromiumAddressBar: Bool?
    private var addressBarCacheTime: CFAbsoluteTime = 0
    private var isRefreshingAddressBar = false
    private let spotlightVisibilityProvider: SpotlightVisibilityProvider
    private var cachedIsSpotlightVisible: Bool?
    private var spotlightCacheTime: CFAbsoluteTime = 0

    private static let addressBarCacheTTL: CFAbsoluteTime = 1.5
    private static let spotlightCacheTTL: CFAbsoluteTime = 0.3

    private var cmdCDoublePressHandler: (@MainActor () -> Void)?
    private var cmdCDoublePressWindowMs: Int = 400
    private var lastCmdCTimestamp: UInt64?

    var onTogglePause: (() -> Void)?
    var onLanguageToggled: ((InputLanguage) -> Void)?

    init(
        settings: EasyKeySettings,
        spotlightVisibilityProvider: @escaping SpotlightVisibilityProvider = SpotlightWindowDetector.isSpotlightWindowVisible,
        focusedTextReplacer: @escaping ([Int], String) -> FocusedElementInspector.FocusedTextReplacementResult =
            FocusedElementInspector.replaceFocusedText
    ) {
        self.settings = settings
        self.spotlightVisibilityProvider = spotlightVisibilityProvider
        synthesizer = KeySynthesizer(focusedTextReplacer: focusedTextReplacer)
        engine = VietnameseEngine(configuration: Self.engineConfiguration(for: settings, rule: nil))
    }

    func update(settings: EasyKeySettings) {
        self.settings = settings
        engine.configuration = Self.engineConfiguration(for: settings, rule: currentCompatibilityRule())
        resetSession()
    }

    func update(macros: [Macro]) {
        macroExpander.update(macros: macros)
    }

    func setActiveApplication(_ bundleIdentifier: String?) {
        activeBundleIdentifier = bundleIdentifier
        engine.configuration = Self.engineConfiguration(for: settings, rule: currentCompatibilityRule())
        invalidateAddressBarCache()
        invalidateSpotlightCache()
        resetSession()
    }

    func setUsesForeignInputSource(_ foreign: Bool) {
        usesForeignInputSource = foreign
        resetSession()
    }

    func resetSession() {
        engine.reset()
        synthesizer.resetEncodedUnits()
        macroExpander.reset()
    }

    func setCmdCDoublePressHandler(windowMs: Int, handler: @escaping @MainActor () -> Void) {
        cmdCDoublePressWindowMs = windowMs
        cmdCDoublePressHandler = handler
    }

    func clearCmdCDoublePressHandler() {
        cmdCDoublePressHandler = nil
        lastCmdCTimestamp = nil
    }

    var activeBundleIdentifierSnapshot: String? {
        activeBundleIdentifier
    }

    func process(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, keyCode: UInt16?) -> KeyboardProcessResult {
        if let activeBundleIdentifier,
           settings.compatibility.ignoredApplicationBundleIdentifiers.contains(activeBundleIdentifier) {
            resetSession()
            return .bypassed
        }

        if type == .flagsChanged {
            return processFlagsChanged(proxy: proxy, event: event, keyCode: keyCode)
        }

        if Self.isMouseEvent(type) {
            invalidateAddressBarCache()
            invalidateSpotlightCache()
            resetSession()
            return .passed
        }

        guard type == .keyDown, let keyCode else {
            return .passed
        }

        detectCmdCDoublePress(keyCode: keyCode, event: event)

        if shortcutMatches(KeyboardService.defaultEmergencyPauseShortcut, type: type, keyCode: keyCode, event: event) {
            DispatchQueue.main.async { [weak self] in self?.onTogglePause?() }
            return .suppressed
        }
        if shortcutMatches(settings.input.switchShortcut, type: type, keyCode: keyCode, event: event) {
            toggleLanguage()
            return .suppressed
        }

        if let macroResult = processMacro(proxy: proxy, keyCode: keyCode, event: event) {
            return macroResult
        }

        guard settings.input.language == .vietnamese,
              settings.compatibility.otherLanguageSupport || !usesForeignInputSource
        else {
            resetSession()
            return .bypassed
        }

        let normalized = Self.normalize(event: event, keyCode: keyCode)
        let output = engine.process(event: normalized)
        guard output.disposition == .suppress else {
            if output.sessionEffect == .resetSession {
                synthesizer.resetEncodedUnits()
            }
            return .passed
        }

        apply(proxy: proxy, output)
        return KeyboardProcessResult(suppressesOriginal: true, outputCount: output.edits.count, disposition: .suppressed)
    }

    private func processMacro(proxy: CGEventTapProxy, keyCode: UInt16, event: CGEvent) -> KeyboardProcessResult? {
        guard let character = Self.character(from: event),
              let expansion = macroExpander.consume(
                  character: character,
                  keyCode: keyCode,
                  modifiers: Self.modifiers(from: event),
                  options: settings.macro,
                  language: settings.input.language
              )
        else { return nil }
        engine.reset()
        synthesizer.postBackspace(proxy: proxy, count: expansion.triggerLength)
        synthesizer.insert(proxy: proxy, expansion.text)
        synthesizer.postPhysicalKey(proxy: proxy, keyCode: keyCode)
        synthesizer.resetEncodedUnits()
        return KeyboardProcessResult(suppressesOriginal: true, outputCount: 2, disposition: .suppressed)
    }

    private func apply(proxy: CGEventTapProxy, _ output: EngineOutput) {
        let rule = currentCompatibilityRule()
        let isSpotlight = rule?.workarounds.contains(.spotlightSelection) == true || isSpotlightContext()
        let replacementUnits = encodedUnits(for: engine.state, configuration: engine.configuration)
        let inChromiumAddressBar = isChromiumAddressBarContext()
        var focusedCaretUnknown = false

        editLoop: for edit in output.edits {
            switch edit {
            case let .deleteBackward(count):
                applyDeleteBackward(
                    proxy: proxy,
                    count: count,
                    isSpotlight: isSpotlight,
                    inChromiumAddressBar: inChromiumAddressBar
                )
            case let .insert(text):
                synthesizer.insert(proxy: proxy, text)
            case let .replaceBackward(deleteCount, insert):
                let strategy = applyReplaceBackward(
                    proxy: proxy,
                    deleteCount: deleteCount,
                    insert: insert,
                    replacementUnits: replacementUnits,
                    isSpotlight: isSpotlight,
                    inChromiumAddressBar: inChromiumAddressBar
                )
                focusedCaretUnknown = focusedCaretUnknown || strategy == .atomicFocusedTextCaretUnknown
                if focusedCaretUnknown {
                    break editLoop
                }
            }
        }

        if !inChromiumAddressBar {
            if rule?.workarounds.contains(.emptyCharacterInsertion) == true {
                synthesizer.insertEmptyCharacter(proxy: proxy, "\u{200B}")
            } else if rule?.workarounds.contains(.alternateEmptyCharacter) == true {
                synthesizer.insertEmptyCharacter(proxy: proxy, "\u{2060}")
            }
        }
        if output.sessionEffect == .resetSession || focusedCaretUnknown {
            resetSession()
        }
    }

    private func applyDeleteBackward(
        proxy: CGEventTapProxy,
        count: Int,
        isSpotlight: Bool,
        inChromiumAddressBar: Bool
    ) {
        synthesizer.replaceBackward(
            proxy: proxy,
            deleteCount: count,
            insert: "",
            encodedUnits: [],
            useFocusedTextReplacement: false,
            useSelectionReplacement: isSpotlight,
            breakAutocomplete: inChromiumAddressBar
        )
    }

    private func applyReplaceBackward(
        proxy: CGEventTapProxy,
        deleteCount: Int,
        insert: String,
        replacementUnits: [String],
        isSpotlight: Bool,
        inChromiumAddressBar: Bool
    ) -> KeySynthesizer.ReplacementStrategy {
        synthesizer.replaceBackward(
            proxy: proxy,
            deleteCount: deleteCount,
            insert: insert,
            encodedUnits: replacementUnits,
            useFocusedTextReplacement: false,
            useSelectionReplacement: isSpotlight,
            breakAutocomplete: Self.shouldBreakAutocomplete(
                inChromiumAddressBar: inChromiumAddressBar,
                isSpotlight: false,
                deleteCount: deleteCount
            )
        )
    }

    private func isChromiumAddressBarContext() -> Bool {
        guard let bundle = activeBundleIdentifier,
              settings.compatibility.compatibilityModeApplicationBundleIdentifiers.contains(bundle)
        else {
            return false
        }

        let now = CFAbsoluteTimeGetCurrent()
        if let cached = cachedIsChromiumAddressBar,
           now - addressBarCacheTime < Self.addressBarCacheTTL {
            return cached
        }

        if !isRefreshingAddressBar {
            isRefreshingAddressBar = true
            addressBarCacheTime = now
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let detected = FocusedElementInspector.isChromiumAddressBar()
                DispatchQueue.main.async {
                    self?.cachedIsChromiumAddressBar = detected
                    self?.isRefreshingAddressBar = false
                }
            }
        }

        return cachedIsChromiumAddressBar ?? false
    }

    private func invalidateAddressBarCache() {
        cachedIsChromiumAddressBar = nil
        addressBarCacheTime = 0
        isRefreshingAddressBar = false
    }

    /// Spotlight's panel never activates as a regular app, so bundle-based rules
    /// miss it. An on-screen window owned by the Spotlight process means the
    /// panel has keyboard focus.
    private func isSpotlightContext() -> Bool {
        let now = CFAbsoluteTimeGetCurrent()
        if let cached = cachedIsSpotlightVisible,
           now - spotlightCacheTime < Self.spotlightCacheTTL {
            return cached
        }
        let visible = spotlightVisibilityProvider()
        if visible != cachedIsSpotlightVisible {
            AppLog.debug(.keyboard, "Spotlight visibility changed visible=\(visible)")
        }
        cachedIsSpotlightVisible = visible
        spotlightCacheTime = now
        return visible
    }

    private func invalidateSpotlightCache() {
        cachedIsSpotlightVisible = nil
        spotlightCacheTime = 0
    }

    private func encodedUnits(for state: SessionState, configuration: EngineConfiguration) -> [String] {
        let toneTarget = TelexComposer.toneTargetIndex(atoms: state.atoms, style: configuration.toneStyle)
        return state.atoms.enumerated().map { index, atom in
            TransformEngine.encode(
                atoms: [atom],
                tone: index == toneTarget ? state.tone : .none,
                encoding: configuration.outputEncoding,
                toneStyle: configuration.toneStyle
            )
        }
    }

    private func currentCompatibilityRule() -> AppCompatibilityRule? {
        AppCompatibility.rule(
            for: activeBundleIdentifier,
            compatibilityModeApplicationBundleIdentifiers: settings.compatibility.compatibilityModeApplicationBundleIdentifiers
        )
    }

    private func toggleLanguage() {
        settings.input.language = settings.input.language == .vietnamese ? .english : .vietnamese
        resetSession()
        let language = settings.input.language
        DispatchQueue.main.async { [weak self] in
            self?.onLanguageToggled?(language)
        }
    }

    private func shortcutMatches(_ shortcut: Shortcut, type: CGEventType, keyCode: UInt16?, event: CGEvent) -> Bool {
        guard shortcut.isActive, Self.modifiers(from: event) == shortcut.modifiers else { return false }
        if shortcut.keyCode == 0, !shortcut.modifiers.isEmpty {
            return type == .flagsChanged
        }
        return type == .keyDown && keyCode == shortcut.keyCode
    }

    static func engineConfiguration(
        for settings: EasyKeySettings,
        rule: AppCompatibilityRule?
    ) -> EngineConfiguration {
        var configuration = EngineConfiguration(
            inputMethod: settings.input.inputMethod,
            outputEncoding: settings.input.encoding,
            spellCheck: settings.typing.spellCheck,
            autoRestoreKeys: settings.typing.restoreInvalidWord,
            toneStyle: settings.typing.toneStyle,
            quickTelexConsonants: settings.typing.quickTelexConsonants,
            standaloneWShortcut: settings.typing.standaloneWShortcut,
            bracketShortcuts: settings.typing.bracketShortcuts,
            uppercaseFirstCharacter: settings.typing.uppercaseFirstCharacter
        )
        if rule?.workarounds.contains(.unicodeCombiningOutput) == true {
            configuration.outputEncoding = .unicodeCombining
        }
        return configuration
    }

    static func shouldBreakAutocomplete(
        inChromiumAddressBar: Bool,
        isSpotlight: Bool,
        deleteCount: Int
    ) -> Bool {
        (inChromiumAddressBar || isSpotlight) && deleteCount > 0
    }

    static func keyCode(from event: CGEvent) -> UInt16? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keyCode >= 0, keyCode <= Int64(UInt16.max) else { return nil }
        return UInt16(keyCode)
    }

    static func normalize(event: CGEvent, keyCode: UInt16) -> KeyEvent {
        let modifiers = modifiers(from: event)
        return KeyEvent(
            kind: keyKind(for: keyCode, event: event),
            shift: modifiers.contains(.shift),
            capsLock: event.flags.contains(.maskAlphaShift),
            control: modifiers.contains(.control),
            option: modifiers.contains(.option),
            command: modifiers.contains(.command)
        )
    }

    private static func keyKind(for keyCode: UInt16, event: CGEvent) -> KeyEvent.Kind {
        specialKeyKinds[keyCode] ?? character(from: event).map(KeyEvent.Kind.character) ?? .other
    }

    private static func character(from event: CGEvent) -> Character? {
        var length = 0
        var buffer = [UniChar](repeating: 0, count: 8)
        event.keyboardGetUnicodeString(
            maxStringLength: buffer.count,
            actualStringLength: &length,
            unicodeString: &buffer
        )
        guard length > 0 else { return nil }
        return String(utf16CodeUnits: buffer, count: length).first
    }

    static func modifiers(from event: CGEvent) -> Shortcut.ModifierFlags {
        var modifiers: Shortcut.ModifierFlags = []
        if event.flags.contains(.maskShift) {
            modifiers.insert(.shift)
        }
        if event.flags.contains(.maskControl) {
            modifiers.insert(.control)
        }
        if event.flags.contains(.maskAlternate) {
            modifiers.insert(.option)
        }
        if event.flags.contains(.maskCommand) {
            modifiers.insert(.command)
        }
        return modifiers
    }

    static func isMouseEvent(_ type: CGEventType) -> Bool {
        switch type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown,
             .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            true
        default:
            false
        }
    }

    static func makeEventMask() -> CGEventMask {
        let types: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged,
            .leftMouseDown, .rightMouseDown, .otherMouseDown,
            .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
        ]
        return types.reduce(0) { $0 | (CGEventMask(1) << $1.rawValue) }
    }

    static func isCurrentInputSourceForeign() -> Bool {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let languages = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages)
        else {
            return false
        }
        let languageCodes = Unmanaged<CFArray>.fromOpaque(languages).takeUnretainedValue() as NSArray
        guard let languageCodes = languageCodes as? [String] else { return false }
        return !languageCodes.contains { $0.lowercased().hasPrefix("en") }
    }

    private func detectCmdCDoublePress(keyCode: UInt16, event: CGEvent) {
        guard let handler = cmdCDoublePressHandler else { return }
        guard keyCode == UInt16(kVK_ANSI_C),
              event.flags.contains(.maskCommand),
              !event.flags.contains(.maskAlternate),
              !event.flags.contains(.maskControl)
        else {
            lastCmdCTimestamp = nil
            return
        }

        let now = event.timestamp

        if let last = lastCmdCTimestamp,
           timestampDeltaMs(lhs: last, rhs: now) <= Double(cmdCDoublePressWindowMs) {
            lastCmdCTimestamp = nil
            DispatchQueue.main.async { handler() }
            return
        }

        lastCmdCTimestamp = now
    }

    private func timestampDeltaMs(lhs: UInt64, rhs: UInt64) -> Double {
        let delta: UInt64
        if rhs >= lhs {
            delta = rhs - lhs
        } else {
            delta = lhs - rhs
        }
        return Double(delta) / 1_000_000.0
    }
}

private extension KeyboardInputPipeline {
    func processFlagsChanged(proxy: CGEventTapProxy, event: CGEvent, keyCode: UInt16?) -> KeyboardProcessResult {
        if shortcutMatches(KeyboardService.defaultEmergencyPauseShortcut, type: .flagsChanged, keyCode: keyCode, event: event) {
            AppLog.debug(.keyboard, "Emergency pause shortcut matched")
            DispatchQueue.main.async { [weak self] in self?.onTogglePause?() }
            return .suppressed
        }
        if shortcutMatches(settings.input.switchShortcut, type: .flagsChanged, keyCode: keyCode, event: event) {
            AppLog.debug(.keyboard, "Language switch shortcut matched")
            toggleLanguage()
            return .suppressed
        }
        if settings.input.language == .vietnamese,
           shortcutMatches(settings.typing.restoreWordShortcut, type: .flagsChanged, keyCode: keyCode, event: event) {
            let output = engine.restoreRawKeys()
            guard output.disposition == .suppress else { return .passed }
            apply(proxy: proxy, output)
            return KeyboardProcessResult(
                suppressesOriginal: true,
                outputCount: output.edits.count,
                disposition: .suppressed
            )
        }
        invalidateSpotlightCache()
        resetSession()
        return .passed
    }
}
