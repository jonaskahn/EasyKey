import Carbon.HIToolbox
import CoreGraphics
import EasyEngineCore
import Foundation

/// Applies Vietnamese engine transforms and posts synthesized key events.
final class KeyboardInputPipeline {
    typealias SpotlightVisibilityProvider = () -> Bool
    typealias ChromiumAddressBarDetector = () -> Bool

    private let synthesizer: KeySynthesizer
    private var engine: VietnameseEngine
    private var settings: EasyKeySettings
    private var macroExpander = MacroExpander()
    private var activeBundleIdentifier: String?
    private var usesForeignInputSource = false
    private let chromiumResolver: ChromiumAddressBarContextResolver
    private let spotlightResolver: SpotlightContextResolver
    private let cmdCDoublePressDetector = CommandCDoublePressDetector()

    var onTogglePause: (() -> Void)?
    var onLanguageToggleRequested: ((InputLanguage) -> Void)?

    init(
        settings: EasyKeySettings,
        spotlightVisibilityProvider: @escaping SpotlightVisibilityProvider = SpotlightWindowDetector.isSpotlightWindowVisible,
        chromiumAddressBarDetector: @escaping ChromiumAddressBarDetector = FocusedElementInspector.isChromiumAddressBar,
        eventFactory: KeySynthesizer.EventFactory? = nil,
        now: @escaping () -> CFAbsoluteTime = CFAbsoluteTimeGetCurrent
    ) {
        self.settings = settings
        chromiumResolver = ChromiumAddressBarContextResolver(detector: chromiumAddressBarDetector, now: now)
        spotlightResolver = SpotlightContextResolver(provider: spotlightVisibilityProvider, now: now)
        synthesizer = KeySynthesizer(eventFactory: eventFactory)
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

    var encodedUnitCountForTesting: Int {
        synthesizer.encodedUnitCount
    }

    var composedTextForTesting: String {
        engine.currentBuffer
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

    private func resetCompositionPreservingMacroTrigger() {
        engine.resetComposition()
        synthesizer.resetEncodedUnits()
    }

    func setCmdCDoublePressHandler(windowMs: Int, handler: @escaping @MainActor () -> Void) {
        cmdCDoublePressDetector.setHandler(windowMs: windowMs, handler: handler)
    }

    func clearCmdCDoublePressHandler() {
        cmdCDoublePressDetector.clearHandler()
    }

    var activeApplicationBundleIdentifier: String? {
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

        if settings.typing.ignoreFunctionKeys, KeyboardKeyCode.isFunctionKey(keyCode) {
            engine.reset()
            synthesizer.resetEncodedUnits()
            return .bypassed
        }

        if let macroResult = processMacro(proxy: proxy, keyCode: keyCode, event: event) {
            return macroResult
        }

        guard settings.input.language == .vietnamese,
              settings.compatibility.otherLanguageSupport || !usesForeignInputSource
        else {
            // Flush engine/synthesizer state but keep the macro trigger buffer:
            // in English (or foreign-input-source) mode every keyDown lands in
            // this branch, and resetSession() would wipe the partial trigger.
            engine.reset()
            synthesizer.resetEncodedUnits()
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
        let rule = currentCompatibilityRule()
        let isSpotlight = rule?.workarounds.contains(.spotlightSelection) == true || isSpotlightContext()
        let inChromiumAddressBar = isChromiumAddressBarContext()
        guard synthesizer.postMacroExpansion(
            proxy: proxy,
            backspaceCount: expansion.triggerLength,
            text: expansion.text,
            physicalKeyCode: keyCode,
            useSelectionReplacement: isSpotlight,
            breakAutocomplete: inChromiumAddressBar
        )
        else {
            resetSession()
            return .passed
        }
        return KeyboardProcessResult(suppressesOriginal: true, outputCount: 2, disposition: .suppressed)
    }

    private func apply(proxy: CGEventTapProxy, _ output: EngineOutput) -> Bool {
        let rule = currentCompatibilityRule()
        let isSpotlight = rule?.workarounds.contains(.spotlightSelection) == true || isSpotlightContext()
        let composedEncodedUnits: [String]? = engine.displaysRawKeystrokes
            ? nil
            : engine.renderedUnits
        let inChromiumAddressBar = isChromiumAddressBarContext()

        for edit in output.edits {
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
                let replacementUnits = composedEncodedUnits ?? insert.map(String.init)
                let strategy = applyReplaceBackward(
                    proxy: proxy,
                    deleteCount: deleteCount,
                    insert: insert,
                    replacementUnits: replacementUnits,
                    isSpotlight: isSpotlight,
                    inChromiumAddressBar: inChromiumAddressBar
                )
                if strategy == .failed {
                    return false
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
        if output.sessionEffect == .resetSession {
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
        return chromiumResolver.resolve()
    }

    private func invalidateAddressBarCache() {
        chromiumResolver.invalidate()
    }

    private func isSpotlightContext() -> Bool {
        spotlightResolver.resolve()
    }

    private func invalidateSpotlightCache() {
        spotlightResolver.invalidate()
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
        cmdCDoublePressDetector.record(keyCode: keyCode, event: event)
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
        if !Self.isShiftFlagsChange(keyCode: keyCode, modifiers: Self.modifiers(from: event)) {
            resetCompositionPreservingMacroTrigger()
        }
        return .passed
    }

    /// Shift press/release must not flush the in-progress composition, otherwise
    /// a word whose first letter is typed with Shift (e.g. "A" + tone key)
    /// loses its vowel before the tone key arrives.
    private static func isShiftFlagsChange(keyCode: UInt16?, modifiers: Shortcut.ModifierFlags) -> Bool {
        guard modifiers.isDisjoint(with: [.control, .option, .command]) else { return false }
        if let keyCode {
            return keyCode == KeyboardKeyCode.leftShift || keyCode == KeyboardKeyCode.rightShift
        }
        return modifiers.contains(.shift)
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
        KeyboardEngineConfigurationFactory.make(for: settings, rule: rule)
    }

    static func shouldBreakAutocomplete(
        inChromiumAddressBar: Bool,
        isSpotlight: Bool,
        deleteCount: Int
    ) -> Bool {
        (inChromiumAddressBar || isSpotlight) && deleteCount > 0
    }

    static func keyCode(from event: CGEvent) -> UInt16? {
        CGKeyboardEventAdapter.keyCode(from: event)
    }

    static func normalize(event: CGEvent, keyCode: UInt16) -> KeyEvent {
        CGKeyboardEventAdapter.normalize(event: event, keyCode: keyCode)
    }

    static func modifiers(from event: CGEvent) -> Shortcut.ModifierFlags {
        CGKeyboardEventAdapter.modifiers(from: event)
    }

    static func isMouseEvent(_ type: CGEventType) -> Bool {
        CGKeyboardEventAdapter.isMouseEvent(type)
    }

    static func makeEventMask() -> CGEventMask {
        CGKeyboardEventAdapter.makeEventMask()
    }

    static func isCurrentInputSourceForeign() -> Bool {
        KeyboardInputSourceInspector.isCurrentInputSourceForeign()
    }

    private static func keyKind(for keyCode: UInt16, event: CGEvent) -> KeyEvent.Kind {
        CGKeyboardEventAdapter.keyKind(for: keyCode, event: event)
    }

    private static func character(from event: CGEvent) -> Character? {
        CGKeyboardEventAdapter.character(from: event)
    }
}
