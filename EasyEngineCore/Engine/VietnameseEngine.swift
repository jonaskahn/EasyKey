import Foundation

public struct VietnameseEngine {
    private enum QuickWState {
        case none
        case transformedVowel(Int)
        case standaloneU(Int)
        case standaloneO(Int)
        case standaloneW(Int)
    }

    private static let sentenceTerminators: Set<String> = [".", "!", "?", "\n"]

    public private(set) var state: SessionState
    public var configuration: EngineConfiguration
    private var quickWState: QuickWState = .none
    private var atSentenceStart = true

    public init(configuration: EngineConfiguration = EngineConfiguration()) {
        state = SessionState()
        self.configuration = configuration
    }

    public mutating func process(event: KeyEvent) -> EngineOutput {
        guard !state.isDisabled else {
            return handlePassThrough()
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
        case .leftArrow, .rightArrow, .upArrow, .downArrow:
            return processMovement()
        case .escape:
            return processEscape()
        case .forwardDelete, .other:
            return processReset()
        }
    }

    public mutating func reset() {
        state.reset()
        quickWState = .none
        atSentenceStart = true
    }

    public var currentBuffer: String {
        TransformEngine.encode(state, encoding: configuration.outputEncoding)
    }

    // MARK: - Private

    private func handlePassThrough() -> EngineOutput {
        .passThrough
    }

    private mutating func processCharacter(_ character: Character, event: KeyEvent) -> EngineOutput {
        if event.hasModifiers {
            state.reset()
            quickWState = .none
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

        let previousLength = state.count
        let lower = character.lowercased().first ?? character
        if configuration.quickTelex,
           lower == "w",
           configuration.inputMethod == .telex || configuration.inputMethod == .simpleTelex {
            return processQuickW(character, previousLength: previousLength)
        }
        quickWState = .none
        let intent = resolveIntent(for: character)

        if case .addTone = intent, state.lastVowelIndex == nil {
            return fallbackPassThrough(character, previousLength: previousLength)
        }
        if case .addMark = intent, state.lastVowelIndex == nil {
            return fallbackPassThrough(character, previousLength: previousLength)
        }
        if case .transformDStroke = intent, state.isEmpty || !state.atoms.last.hasBase("d") {
            return fallbackPassThrough(character, previousLength: previousLength)
        }
        if case .revertDStroke = intent, state.isEmpty || state.atoms.last?.mark != .stroke {
            return fallbackPassThrough(character, previousLength: previousLength)
        }
        if case let .transformDoubleVowel(base, _) = intent, state.isEmpty || !state.atoms.last.hasBase(base) {
            return fallbackPassThrough(character, previousLength: previousLength)
        }
        if case let .revertDoubleVowel(base) = intent,
           state.isEmpty || !state.atoms.last.hasBase(base) || state.atoms.last?.mark != .circumflex {
            return fallbackPassThrough(character, previousLength: previousLength)
        }
        if case .transformW = intent {
            guard quickWVowelIndex != nil else {
                return fallbackPassThrough(character, previousLength: previousLength)
            }
        }

        if case let .addTone(newTone) = intent, state.tone == newTone {
            state.tone = .none
            return fallbackPassThrough(character, previousLength: previousLength)
        }

        let result = TransformEngine.apply(intent: intent, state: state, configuration: configuration)
        state = result.newState

        return EngineOutput(
            disposition: .suppress,
            edits: [.replaceBackward(deleteCount: previousLength, insert: result.newContent)],
            sessionEffect: .continueSession
        )
    }

    private mutating func processQuickW(_ character: Character, previousLength: Int) -> EngineOutput {
        switch quickWState {
        case let .transformedVowel(index):
            if state.atoms.indices.contains(index), state.atoms[index].mark != .none {
                state.atoms[index].mark = .none
                state.append(BufferAtom(base: "w", uppercase: character.isUppercase))
            } else {
                state.append(BufferAtom(base: "w", uppercase: character.isUppercase))
            }
            quickWState = .none

        case let .standaloneU(index):
            if state.atoms.indices.contains(index) {
                let uppercase = state.atoms[index].uppercase
                state.atoms[index] = BufferAtom(base: "o", mark: .horn, uppercase: uppercase)
                quickWState = .standaloneO(index)
            } else {
                state.append(BufferAtom(base: "w", uppercase: character.isUppercase))
                quickWState = .none
            }

        case let .standaloneO(index):
            if state.atoms.indices.contains(index) {
                let uppercase = state.atoms[index].uppercase
                state.atoms[index] = BufferAtom(base: "w", uppercase: uppercase)
                quickWState = .standaloneW(index)
            } else {
                state.append(BufferAtom(base: "w", uppercase: character.isUppercase))
                quickWState = .none
            }

        case let .standaloneW(index):
            if state.atoms.indices.contains(index) {
                let uppercase = state.atoms[index].uppercase
                state.atoms[index] = BufferAtom(base: "u", mark: .horn, uppercase: uppercase)
                quickWState = .standaloneU(index)
            } else {
                state.append(BufferAtom(base: "w", uppercase: character.isUppercase))
                quickWState = .none
            }

        case .none:
            if let eligibleIndex = quickWVowelIndex {
                let result = TransformEngine.apply(intent: .transformW, state: state, configuration: configuration)
                state = result.newState
                quickWState = .transformedVowel(eligibleIndex)
            } else if state.isEmpty || VietnameseCharacters.startConsonants.contains(bufferText.lowercased()) {
                let index = state.count
                state.append(BufferAtom(base: "u", mark: .horn, uppercase: character.isUppercase))
                quickWState = .standaloneU(index)
            } else {
                state.append(BufferAtom(base: "w", uppercase: character.isUppercase))
            }
        }

        return EngineOutput(
            disposition: .suppress,
            edits: [.replaceBackward(deleteCount: previousLength, insert: currentBuffer)],
            sessionEffect: .continueSession
        )
    }

    private var bufferText: String {
        String(state.atoms.map(\.character))
    }

    private var quickWVowelIndex: Int? {
        state.wTransformVowelIndex
    }

    private mutating func fallbackPassThrough(_ character: Character, previousLength: Int) -> EngineOutput {
        let result = TransformEngine.apply(intent: .passThrough(character), state: state, configuration: configuration)
        state = result.newState
        return EngineOutput(
            disposition: .suppress,
            edits: [.replaceBackward(deleteCount: previousLength, insert: result.newContent)],
            sessionEffect: .continueSession
        )
    }

    private func isWordBreakCharacter(_ character: Character) -> Bool {
        if character.isWhitespace {
            return true
        }
        let punctuation: Set<Character> = [
            ".", ",", ";", ":", "!", "?", "(", ")", "[", "]",
            "{", "}", "<", ">", "/", "\\", "|", "@", "#", "$",
            "%", "^", "&", "*", "+", "=", "~", "`", "'",
        ]
        return punctuation.contains(character)
    }

    private func resolveIntent(for character: Character) -> TransformIntent {
        let previousChar = state.lastAtom?.character

        switch configuration.inputMethod {
        case .telex:
            return TelexRules.intent(forCharacter: character, previousChar: previousChar) ?? .passThrough(character)
        case .vni:
            return VNIRules.intent(forCharacter: character) ?? .passThrough(character)
        case .simpleTelex:
            return SimpleTelexRules.intent(forCharacter: character, previousChar: previousChar) ?? .passThrough(character)
        }
    }

    private mutating func processBackspace() -> EngineOutput {
        quickWState = .none
        guard !state.isEmpty else {
            return .passThrough
        }

        let oldCount = state.count
        let lastIdx = state.count - 1

        if state.atoms[lastIdx].mark != .none {
            state.atoms[lastIdx].mark = .none
            state.tone = .none
            let encoded = TransformEngine.encode(state, encoding: configuration.outputEncoding)
            return EngineOutput(
                disposition: .suppress,
                edits: [.replaceBackward(deleteCount: oldCount, insert: encoded)],
                sessionEffect: .continueSession
            )
        }

        if state.tone != .none {
            state.tone = .none
            let encoded = TransformEngine.encode(state, encoding: configuration.outputEncoding)
            return EngineOutput(
                disposition: .suppress,
                edits: [.replaceBackward(deleteCount: oldCount, insert: encoded)],
                sessionEffect: .continueSession
            )
        }

        state.removeLast()
        if state.tone != .none {
            state.tone = .none
        }

        if state.isEmpty {
            return EngineOutput(
                disposition: .pass,
                edits: [],
                sessionEffect: .continueSession
            )
        }

        let encoded2 = TransformEngine.encode(state, encoding: configuration.outputEncoding)
        return EngineOutput(
            disposition: .suppress,
            edits: [.replaceBackward(deleteCount: oldCount, insert: encoded2)],
            sessionEffect: .continueSession
        )
    }

    private mutating func processWordBoundary(trailingChar: String) -> EngineOutput {
        guard !state.isEmpty else {
            return .passThrough
        }

        if Self.sentenceTerminators.contains(trailingChar) {
            atSentenceStart = true
        }

        let encoded = TransformEngine.encode(state, encoding: configuration.outputEncoding)
        state.reset()
        quickWState = .none

        return EngineOutput(
            disposition: .suppress,
            edits: [
                .replaceBackward(deleteCount: encoded.count, insert: encoded),
                .insert(trailingChar),
            ],
            sessionEffect: .resetSession
        )
    }

    private mutating func processMovement() -> EngineOutput {
        state.reset()
        quickWState = .none
        return .passThrough
    }

    private mutating func processEscape() -> EngineOutput {
        state.reset()
        quickWState = .none
        return .passThrough
    }

    private mutating func processReset() -> EngineOutput {
        state.reset()
        quickWState = .none
        return .passThrough
    }
}
