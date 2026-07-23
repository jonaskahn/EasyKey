import Carbon.HIToolbox
import CoreGraphics
import EasyEngineCore
import Foundation

// swiftlint:disable file_length

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
    typealias ChromiumAddressBarDetector = () -> Bool

    private struct AddressBarCache {
        var value: Bool?
        var updatedAt: CFAbsoluteTime = 0
        var isRefreshing = false
        var generation: UInt = 0
    }

    private let synthesizer: KeySynthesizer
    private var engine: VietnameseEngine
    private var settings: EasyKeySettings
    private var macroExpander = MacroExpander()
    private var activeBundleIdentifier: String?
    private var usesForeignInputSource = false
    private let chromiumAddressBarDetector: ChromiumAddressBarDetector
    private let addressBarStateQueue = DispatchQueue(label: "com.easykey.chromium-address-cache")
    private var addressBarCache = AddressBarCache()
    private let spotlightVisibilityProvider: SpotlightVisibilityProvider
    private var cachedIsSpotlightVisible: Bool?
    private var spotlightCacheTime: CFAbsoluteTime = 0

    private static let addressBarCacheTTL: CFAbsoluteTime = 1.5
    private static let spotlightCacheTTL: CFAbsoluteTime = 0.3

    private var cmdCDoublePressHandler: (@MainActor () -> Void)?
    private var cmdCDoublePressWindowMs: Int = 400
    private var lastCmdCTimestamp: UInt64?

    var onTogglePause: (() -> Void)?
    var onLanguageToggleRequested: ((InputLanguage) -> Void)?

    init(
        settings: EasyKeySettings,
        spotlightVisibilityProvider: @escaping SpotlightVisibilityProvider = SpotlightWindowDetector.isSpotlightWindowVisible,
        chromiumAddressBarDetector: @escaping ChromiumAddressBarDetector = FocusedElementInspector.isChromiumAddressBar,
        focusedTextReplacer: @escaping ([Int], String) -> FocusedElementInspector.FocusedTextReplacementResult =
            FocusedElementInspector.replaceFocusedText,
        eventFactory: KeySynthesizer.EventFactory? = nil
    ) {
        self.settings = settings
        self.spotlightVisibilityProvider = spotlightVisibilityProvider
        self.chromiumAddressBarDetector = chromiumAddressBarDetector
        synthesizer = KeySynthesizer(focusedTextReplacer: focusedTextReplacer, eventFactory: eventFactory)
        engine = VietnameseEngine(configuration: Self.engineConfiguration(for: settings, rule: nil))
    }

    func update(settings: EasyKeySettings) {
        let oldConfig = engine.configuration
        let newConfig = Self.engineConfiguration(for: settings, rule: currentCompatibilityRule())
        self.settings = settings
        if oldConfig != newConfig {
            engine.configuration = newConfig
            resetSession()
        }
    }

    func update(macros: [Macro]) {
        macroExpander.update(macros: macros)
    }

    var isComposing: Bool {
        !engine.state.isEmpty
    }

    var activeAppBundleIdentifier: String? {
        activeBundleIdentifier
    }

    var currentSettings: EasyKeySettings {
        settings
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

    private func resetComposition() {
        engine.resetComposition()
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
        if shortcutMatches(KeyboardService.defaultEmergencyPauseShortcut, type: type, keyCode: keyCode, event: event) {
            DispatchQueue.main.async { [weak self] in self?.onTogglePause?() }
            return .suppressed
        }

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
            resetComposition()
            return .passed
        }

        guard type == .keyDown, let keyCode else {
            return .passed
        }

        detectCmdCDoublePress(keyCode: keyCode, event: event)

        if shortcutMatches(settings.input.switchShortcut, type: type, keyCode: keyCode, event: event) {
            toggleLanguage()
            return .suppressed
        }
        if settings.input.language == .vietnamese,
           shortcutMatches(settings.typing.restoreWordShortcut, type: type, keyCode: keyCode, event: event) {
            return restoreRawKeys(proxy: proxy)
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

        guard apply(proxy: proxy, output) else {
            resetSession()
            return .passed
        }
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
        guard synthesizer.postMacroExpansion(
            proxy: proxy,
            backspaceCount: expansion.triggerLength,
            text: expansion.text,
            physicalKeyCode: keyCode
        )
        else {
            resetSession()
            return .passed
        }
        synthesizer.resetEncodedUnits()
        return KeyboardProcessResult(suppressesOriginal: true, outputCount: 2, disposition: .suppressed)
    }

    private func apply(proxy: CGEventTapProxy, _ output: EngineOutput) -> Bool {
        let rule = currentCompatibilityRule()
        let isSpotlight = rule?.workarounds.contains(.spotlightSelection) == true || isSpotlightContext()
        let replacementUnits = encodedUnits(for: engine.state, configuration: engine.configuration)
        let inChromiumAddressBar = isChromiumAddressBarContext()
        var focusedCaretUnknown = false

        editLoop: for edit in output.edits {
            switch edit {
            case let .deleteBackward(count):
                guard applyDeleteBackward(
                    proxy: proxy,
                    count: count,
                    isSpotlight: isSpotlight,
                    inChromiumAddressBar: inChromiumAddressBar
                )
                else { return false }
            case let .insert(text):
                guard synthesizer.insert(proxy: proxy, text) else { return false }
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
                if strategy == .failed {
                    return false
                }
                if focusedCaretUnknown {
                    break editLoop
                }
            }
        }

        if !inChromiumAddressBar {
            if rule?.workarounds.contains(.emptyCharacterInsertion) == true {
                guard synthesizer.insertEmptyCharacter(proxy: proxy, "\u{200B}") else { return false }
            } else if rule?.workarounds.contains(.alternateEmptyCharacter) == true {
                guard synthesizer.insertEmptyCharacter(proxy: proxy, "\u{2060}") else { return false }
            }
        }
        if output.sessionEffect == .resetSession || focusedCaretUnknown {
            resetSession()
        }
        return true
    }

    private func applyDeleteBackward(
        proxy: CGEventTapProxy,
        count: Int,
        isSpotlight: Bool,
        inChromiumAddressBar: Bool
    ) -> Bool {
        synthesizer.replaceBackward(
            proxy: proxy,
            deleteCount: count,
            insert: "",
            encodedUnits: [],
            useFocusedTextReplacement: false,
            useSelectionReplacement: isSpotlight,
            breakAutocomplete: inChromiumAddressBar
        ) != .failed
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

        return addressBarStateQueue.sync {
            let now = CFAbsoluteTimeGetCurrent()
            if let value = addressBarCache.value,
               now - addressBarCache.updatedAt < Self.addressBarCacheTTL {
                return value
            }
            if !addressBarCache.isRefreshing {
                addressBarCache.isRefreshing = true
                let generation = addressBarCache.generation
                let detector = chromiumAddressBarDetector
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    let detected = detector()
                    self?.addressBarStateQueue.async { [weak self] in
                        guard let self, self.addressBarCache.generation == generation else { return }
                        self.addressBarCache.value = detected
                        self.addressBarCache.updatedAt = CFAbsoluteTimeGetCurrent()
                        self.addressBarCache.isRefreshing = false
                    }
                }
            }
            return addressBarCache.value ?? false
        }
    }

    private func invalidateAddressBarCache() {
        addressBarStateQueue.sync {
            addressBarCache.value = nil
            addressBarCache.updatedAt = 0
            addressBarCache.isRefreshing = false
            addressBarCache.generation &+= 1
        }
    }

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
        let next: InputLanguage = settings.input.language == .vietnamese ? .english : .vietnamese
        DispatchQueue.main.async { [weak self] in
            self?.onLanguageToggleRequested?(next)
        }
    }

    private func shortcutMatches(_ shortcut: Shortcut, type: CGEventType, keyCode: UInt16?, event: CGEvent) -> Bool {
        guard shortcut.isActive, Self.modifiers(from: event) == shortcut.modifiers else { return false }
        if shortcut.isModifierOnly {
            return type == .flagsChanged
        }
        return type == .keyDown && keyCode == shortcut.keyCode
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
        if shortcutMatches(settings.input.switchShortcut, type: .flagsChanged, keyCode: keyCode, event: event) {
            AppLog.debug(.keyboard, "Language switch shortcut matched")
            toggleLanguage()
            return .suppressed
        }
        if settings.input.language == .vietnamese,
           shortcutMatches(settings.typing.restoreWordShortcut, type: .flagsChanged, keyCode: keyCode, event: event) {
            return restoreRawKeys(proxy: proxy)
        }
        invalidateSpotlightCache()
        resetComposition()
        return .passed
    }

    func restoreRawKeys(proxy: CGEventTapProxy) -> KeyboardProcessResult {
        let output = engine.restoreRawKeys()
        guard output.disposition == .suppress else { return .passed }
        guard apply(proxy: proxy, output) else {
            resetSession()
            return .passed
        }
        return KeyboardProcessResult(
            suppressesOriginal: true,
            outputCount: output.edits.count,
            disposition: .suppressed
        )
    }
}

extension KeyboardInputPipeline {
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
}
