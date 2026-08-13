import Foundation

/// Streaming Vietnamese input engine. Raw keystrokes are the source of truth;
/// every edit recomputes the composed buffer via `TelexComposer`, which makes
/// backspace, repeat-to-undo, and word restoration exact.
///
/// VNI tone digits that are invalid for the current checked final are dropped
/// without appending to raw keys, and an escaped session commits the corrected
/// word rather than the raw escape keystrokes.
public struct VietnameseEngine {
    private static let sentenceTerminators: Set<String> = [".", "!", "?", "\n"]

    /// Prefixes that mark a whitespace-delimited token as technical (slash
    /// commands, mentions, references, shell mode, shortcodes) so the whole
    /// token types literally without Vietnamese conversion.
    private static let technicalTokenPrefixes: Set<Character> = ["/", "@", "#", "!", ":"]

    public internal(set) var state: SessionState
    public var configuration: EngineConfiguration
    private var atSentenceStart = true
    private var lastRenderedCount = 0
    /// True when the next character begins a fresh token (start of input or
    /// right after a word boundary), so a leading technical prefix can be
    /// recognized before any Vietnamese composition begins.
    private var atTokenStart = true
    private var isLiteralToken = false
    private var literalTokenCharacters: [Character] = []

    public init(configuration: EngineConfiguration = EngineConfiguration()) {
        state = SessionState()
        self.configuration = configuration
    }

    public var currentBuffer: String {
        if displaysRawKeystrokes {
            return state.rawText
        }
        return composedBuffer
    }

    /// Whether the live buffer shows raw keystrokes (`forceRaw` or low
    /// live-confidence band). An explicit Telex escape overrides the live
    /// band so the corrected literal word stays visible.
    public var displaysRawKeystrokes: Bool {
        if state.forceRaw {
            return true
        }
        if state.isEscaped {
            return false
        }
        return shouldDisplayRawKeystrokesFromLiveConfidence
    }

    private var composedBuffer: String {
        TransformEngine.encode(state, configuration: configuration)
    }

    /// Plain rendering metadata for the current buffer: the per-atom encoded
    /// units the platform layer emits when replacing the buffer, so it can
    /// compute UTF-16 deletion counts without reading engine internals.
    public var renderedUnits: [String] {
        TransformEngine.encodeUnits(state, configuration: configuration)
    }

    private var shouldDisplayRawKeystrokesFromLiveConfidence: Bool {
        configuration.liveConfidenceScoring
            && !state.isEmpty
            && liveConfidenceBand == .low
    }

    private var liveConfidenceBand: LiveConfidenceBand {
        LiveConfidence.band(
            score: LiveConfidence.score(
                rawKeys: state.rawKeys,
                atoms: state.atoms
            ),
            lowThreshold: configuration.liveConfidenceLowThreshold,
            highThreshold: configuration.liveConfidenceHighThreshold
        )
    }

    public mutating func process(event: KeyEvent) -> EngineOutput {
        guard !state.isDisabled else {
            return .passThrough
        }

        switch event.kind {
        case let .character(character):
            return processCharacter(character, event: event)
        case .backspace:
            return processBackspace()
        case .space:
            return processWordBoundary(trailingChar: " ")
        case .return:
            return processWordBoundary(trailingChar: "\n")
        case .tab:
            return processWordBoundary(trailingChar: "\t")
        case .leftArrow, .rightArrow, .upArrow, .downArrow,
             .escape, .forwardDelete, .other:
            return processReset()
        }
    }

    public mutating func reset() {
        clearComposition()
        endLiteralToken()
        atSentenceStart = true
        atTokenStart = true
    }

    /// Clears current word state while preserving sentence-capitalization context.
    /// A literal token is intentionally left intact so modifier-key transitions
    /// (e.g. Shift before an uppercase letter inside a mention) do not break it.
    public mutating func resetComposition() {
        clearComposition()
    }

    /// Restores the raw keystrokes for the word being composed and freezes
    /// transformation until the next word boundary (per-word restore).
    @discardableResult
    public mutating func restoreRawKeys() -> EngineOutput {
        guard !state.isEmpty, !state.forceRaw else {
            return .passThrough
        }
        let previousCount = lastRenderedCount
        state.forceRaw = true
        lastRenderedCount = state.rawText.count
        return EngineOutput(
            disposition: .suppress,
            edits: [.replaceBackward(deleteCount: previousCount, insert: state.rawText)],
            sessionEffect: .continueSession
        )
    }

    private mutating func processCharacter(_ character: Character, event: KeyEvent) -> EngineOutput {
        if atTokenStart, configuration.literalTechnicalTokens,
           Self.technicalTokenPrefixes.contains(character) {
            isLiteralToken = true
            atTokenStart = false
            literalTokenCharacters = [character]
            return EngineOutput(
                disposition: .suppress,
                edits: [.insert(String(character))],
                sessionEffect: .continueSession
            )
        }

        if event.hasModifiers {
            clearComposition()
            if !isLiteralToken {
                atTokenStart = true
            }
            return .passThrough
        }

        if isLiteralToken {
            literalTokenCharacters.append(character)
            return EngineOutput(
                disposition: .suppress,
                edits: [.insert(String(character))],
                sessionEffect: .continueSession
            )
        }

        atTokenStart = false

        if state.forceRaw {
            clearComposition()
        }

        if isWordBreakCharacter(character) {
            return processWordBoundary(trailingChar: String(character))
        }

        var character = character
        if state.isEmpty {
            if configuration.uppercaseFirstCharacter, atSentenceStart, character.isLetter, !character.isUppercase {
                character = Character(character.uppercased())
            }
            atSentenceStart = false
        }

        let previousCount = lastRenderedCount
        if configuration.inputMethod == .vni,
           let newTone = VietnameseCharacters.toneNumberKeys[character],
           state.atoms.contains(where: { VietnameseCharacters.isVowel($0.base) }) {
            let final = TelexComposer.trailingFinalConsonants(state.atoms)
            if !VietnameseOrthography.toneIsValid(newTone, forFinal: final) {
                return EngineOutput(
                    disposition: .suppress,
                    edits: [],
                    sessionEffect: .continueSession
                )
            }
        }

        state.rawKeys.append(character)
        recompute()

        return EngineOutput(
            disposition: .suppress,
            edits: [.replaceBackward(deleteCount: previousCount, insert: currentBuffer)],
            sessionEffect: .continueSession
        )
    }

    private mutating func recompute() {
        let composition = TelexComposer.compose(rawKeys: state.rawKeys, configuration: configuration)
        state.atoms = composition.atoms
        state.tone = composition.tone
        state.isEscaped = composition.isEscaped
        lastRenderedCount = currentBuffer.count
    }

    private func isWordBreakCharacter(_ character: Character) -> Bool {
        if character.isWhitespace {
            return true
        }
        var punctuation: Set<Character> = [
            ".", ",", ";", ":", "!", "?", "(", ")",
            "<", ">", "/", "\\", "|", "@", "#", "$",
            "%", "^", "&", "*", "+", "=", "~", "`", "'",
        ]
        if !TelexComposer.usesBracketShortcuts(configuration) {
            punctuation.formUnion(["[", "]", "{", "}"])
        }
        return punctuation.contains(character)
    }

    private mutating func processBackspace() -> EngineOutput {
        guard !state.isEmpty else {
            atSentenceStart = false
            if isLiteralToken {
                literalTokenCharacters.removeLast()
                if literalTokenCharacters.isEmpty {
                    endLiteralToken()
                }
                return EngineOutput(
                    disposition: .suppress,
                    edits: [.deleteBackward(1)],
                    sessionEffect: .continueSession
                )
            }
            return .passThrough
        }

        let previousCount = lastRenderedCount
        state.rawKeys.removeLast()
        if state.rawKeys.isEmpty {
            atSentenceStart = false
        }
        recompute()

        return EngineOutput(
            disposition: .suppress,
            edits: [.replaceBackward(deleteCount: previousCount, insert: currentBuffer)],
            sessionEffect: .continueSession
        )
    }

    private mutating func processWordBoundary(trailingChar: String) -> EngineOutput {
        if Self.sentenceTerminators.contains(trailingChar) {
            atSentenceStart = true
        }

        if isLiteralToken {
            endLiteralToken()
            return .passThrough
        }

        atTokenStart = true

        guard !state.isEmpty else {
            return .passThrough
        }

        let previousCount = lastRenderedCount
        let finalText = resolvedBoundaryText()
        clearComposition()

        return EngineOutput(
            disposition: .suppress,
            edits: [
                .replaceBackward(deleteCount: previousCount, insert: finalText),
                .insert(trailingChar),
            ],
            sessionEffect: .resetSession
        )
    }

    private func resolvedBoundaryText() -> String {
        let composed = composedBuffer
        let raw = state.rawText
        if state.isEscaped {
            return composed
        }
        guard configuration.spellCheck, composed != raw else {
            return composed
        }
        guard !VietnameseOrthography.isValidWord(composed) else {
            return composed
        }
        return configuration.autoRestoreKeys ? raw : composed
    }

    private mutating func processReset() -> EngineOutput {
        endLiteralToken()
        clearComposition()
        atSentenceStart = false
        return .passThrough
    }

    private mutating func clearComposition() {
        state.reset()
        lastRenderedCount = 0
    }

    private mutating func endLiteralToken() {
        if let last = literalTokenCharacters.last,
           Self.sentenceTerminators.contains(String(last)) {
            atSentenceStart = true
        }
        literalTokenCharacters = []
        isLiteralToken = false
        atTokenStart = true
    }
}
