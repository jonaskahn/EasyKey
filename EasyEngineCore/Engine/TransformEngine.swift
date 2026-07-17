import Foundation

public struct TransformResult: Equatable, Sendable {
    public var previousLength: Int
    public var newContent: String
    public var newState: SessionState

    public init(previousLength: Int, newContent: String, newState: SessionState) {
        self.previousLength = previousLength
        self.newContent = newContent
        self.newState = newState
    }
}

public enum TransformEngine {
    public static func apply(
        intent: TransformIntent,
        state: SessionState,
        configuration: EngineConfiguration
    ) -> TransformResult {
        var state = state
        let previousLength = state.count

        switch intent {
        case let .addTone(tone):
            state.tone = tone

        case let .addMark(mark):
            if let vowelIdx = state.lastVowelIndex {
                state.atoms[vowelIdx].mark = mark
            }

        case .transformDStroke:
            if state.count >= 1, state.atoms[state.count - 1].base == "d" {
                state.atoms[state.count - 1].mark = .stroke
            }

        case .revertDStroke:
            if state.count >= 1, state.atoms[state.count - 1].hasBase("d") {
                state.atoms[state.count - 1].mark = .none
            }

        case let .transformDoubleVowel(base, mark):
            if state.count >= 1, state.atoms[state.count - 1].base == base {
                state.atoms[state.count - 1].mark = mark
            }

        case let .revertDoubleVowel(base):
            if state.count >= 1, state.atoms[state.count - 1].hasBase(base),
               state.atoms[state.count - 1].mark == .circumflex {
                state.atoms[state.count - 1].mark = .none
            }

        case let .transformHorn(base):
            if let vowelIdx = state.lastVowelIndex, state.atoms[vowelIdx].base == base {
                state.atoms[vowelIdx].mark = .horn
            }

        case .transformW:
            applyTransformW(to: &state)

        case let .passThrough(character):
            let uppercase = character.isUppercase
            let base = character.lowercased().first ?? character
            let atom = BufferAtom(base: base, uppercase: uppercase)
            state.append(atom)
        }

        let newContent = encode(state, encoding: configuration.outputEncoding)
        return TransformResult(previousLength: previousLength, newContent: newContent, newState: state)
    }

    public static func encode(
        _ state: SessionState,
        encoding: EncodingTable = .unicode
    ) -> String {
        let encoder = EncodingFactory.encoding(for: encoding)
        let toneIdx = toneTargetIndex(state)
        return encoder.encode(atoms: state.atoms, tone: state.tone, toneTargetIndex: toneIdx)
    }

    private static func applyTransformW(to state: inout SessionState) {
        guard let vowelIdx = state.wTransformVowelIndex else { return }

        switch state.atoms[vowelIdx].base.lowercased().first ?? state.atoms[vowelIdx].base {
        case "u", "o":
            state.atoms[vowelIdx].mark = .horn
        case "a":
            state.atoms[vowelIdx].mark = .breve
        default:
            break
        }
    }

    public static func toneTargetIndex(_ state: SessionState) -> Int? {
        var vowelIndices: [Int] = []
        for index in 0 ..< state.atoms.count
            where VietnameseCharacters.isVowel(state.atoms[index].base) {
            vowelIndices.append(index)
        }
        guard !vowelIndices.isEmpty else { return nil }
        guard vowelIndices.count >= 2 else { return vowelIndices.first }

        let lastVowelIdx = vowelIndices.last!
        let lastAtom = state.atoms[lastVowelIdx]
        let closingOffglides: Set<Character> = ["i", "u", "o"]
        if closingOffglides.contains(lastAtom.base), lastAtom.mark == .none {
            return vowelIndices[vowelIndices.count - 2]
        }

        let firstAtom = state.atoms[vowelIndices[vowelIndices.count - 2]]

        if lastAtom.base == "y", lastAtom.mark == .none, firstAtom.base == "a" {
            return vowelIndices[vowelIndices.count - 2]
        }

        let isOpenSyllable = lastVowelIdx == state.atoms.count - 1
        let openNucleusLeaders: Set<Character> = ["u", "i"]
        if isOpenSyllable, lastAtom.base == "a", lastAtom.mark == .none,
           openNucleusLeaders.contains(firstAtom.base) {
            return vowelIndices[vowelIndices.count - 2]
        }

        return vowelIndices.last
    }
}
