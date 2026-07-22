import Foundation

/// Streaming Vietnamese input engine. Raw keystrokes are the source of truth;
/// every edit recomputes the composed buffer via `TelexComposer`, which makes
/// backspace, repeat-to-undo, and word restoration exact.
public struct VietnameseEngine {
    private static let sentenceTerminators: Set<String> = [".", "!", "?", "\n"]

    public internal(set) var state: SessionState
    public var configuration: EngineConfiguration
    private var atSentenceStart = true
    private var lastRenderedCount = 0

    public init(configuration: EngineConfiguration = EngineConfiguration()) {
        state = SessionState()
        self.configuration = configuration
    }

    public var currentBuffer: String {
        if state.forceRaw {
            return state.rawText
        }
        return TransformEngine.encode(state, configuration: configuration)
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
        atSentenceStart = true
    }

    /// Clears current word state while preserving sentence-capitalization context.
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
        if event.hasModifiers {
            clearComposition()
            return .passThrough
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
            return .passThrough
        }

        let previousCount = lastRenderedCount
        state.rawKeys.removeLast()
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
        let composed = currentBuffer
        let raw = state.rawText
        guard configuration.spellCheck, composed != raw else {
            return composed
        }
        guard !VietnameseOrthography.isValidWord(composed) else {
            return composed
        }
        return configuration.autoRestoreKeys ? raw : composed
    }

    private mutating func processReset() -> EngineOutput {
        clearComposition()
        return .passThrough
    }

    private mutating func clearComposition() {
        state.reset()
        lastRenderedCount = 0
    }
}
