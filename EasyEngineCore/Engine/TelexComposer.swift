import Foundation

/// Deterministic Vietnamese composition from raw keystrokes. Implements the
/// verified Telex / Simple Telex rule set documented in docs/_archive/TELEX.md:
/// pair modifiers (aa, aw, ee, oo, ow, uw, dd), tone keys (s/f/r/x/j, z
/// removes tone), full-Telex extensions (standalone `w`→ư, `[`→ơ, `]`→ư,
/// `{`→Ơ, `}`→Ư), position-free marks and tones, repeat-to-undo, and
/// checked-final tone restriction. VNI digit rules share the same pipeline.
public enum TelexComposer {
    private struct Profile: Equatable, Sendable {
        var isTelexFamily: Bool
        var allowStandaloneW: Bool
        var allowBrackets: Bool
        var quickConsonants: Bool

        init(isTelexFamily: Bool, allowStandaloneW: Bool, allowBrackets: Bool, quickConsonants: Bool) {
            self.isTelexFamily = isTelexFamily
            self.allowStandaloneW = allowStandaloneW
            self.allowBrackets = allowBrackets
            self.quickConsonants = quickConsonants
        }

        static let vni = Profile(
            isTelexFamily: false,
            allowStandaloneW: false,
            allowBrackets: false,
            quickConsonants: false
        )
    }

    struct Composition: Equatable, Sendable {
        var atoms: [BufferAtom]
        var tone: Tone
        /// True when a Telex repeat-to-undo explicitly cancelled a transformation;
        /// the rest of the word is then kept literal (iOS-UniKey-like mode).
        var isEscaped: Bool

        init(atoms: [BufferAtom], tone: Tone, isEscaped: Bool = false) {
            self.atoms = atoms
            self.tone = tone
            self.isEscaped = isEscaped
        }

        static let empty = Composition(atoms: [], tone: .none)
    }

    static func usesBracketShortcuts(_ configuration: EngineConfiguration) -> Bool {
        profile(for: configuration).allowBrackets
    }

    private static func profile(for configuration: EngineConfiguration) -> Profile {
        switch configuration.inputMethod {
        case .telex:
            return Profile(
                isTelexFamily: true,
                allowStandaloneW: configuration.standaloneWShortcut,
                allowBrackets: configuration.bracketShortcuts,
                quickConsonants: configuration.quickTelexConsonants
            )
        case .simpleTelex:
            return Profile(
                isTelexFamily: true,
                allowStandaloneW: false,
                allowBrackets: false,
                quickConsonants: configuration.quickTelexConsonants
            )
        case .vni:
            return .vni
        }
    }

    /// Recomposes the full buffer from raw keystrokes. Words are short, so a
    /// single deterministic pass per edit keeps every state transition exact.
    /// When `iosUniKeyLikeMode` is enabled, the first repeat-to-undo (a key
    /// that cancels its own mark or tone) freezes the remainder of the word as
    /// literal text, matching iOS UniKey-style input for English words.
    static func compose(rawKeys: [Character], configuration: EngineConfiguration) -> Composition {
        let profile = profile(for: configuration)
        var atoms: [BufferAtom] = []
        var tone: Tone = .none
        var pending: (key: Character, undo: PendingUndo)?
        var escaped = false

        for key in rawKeys {
            let lower = Character(String(key).lowercased())

            if escaped {
                appendLiteral(key, to: &atoms)
                continue
            }

            if let active = pending, active.key == lower {
                apply(undo: active.undo, atoms: &atoms, tone: &tone)
                appendLiteral(key, to: &atoms)
                pending = nil
                escaped = profile.isTelexFamily && configuration.iosUniKeyLikeMode
                continue
            }
            pending = nil

            if profile.isTelexFamily {
                pending = processTelexKey(key, lower: lower, profile: profile, atoms: &atoms, tone: &tone)
            } else {
                pending = processVNIKey(key, atoms: &atoms, tone: &tone)
            }
        }

        if !escaped {
            normalizeVietnameseNucleus(atoms: &atoms, tone: tone)
        }
        return Composition(atoms: atoms, tone: tone, isEscaped: escaped)
    }

    /// Ordered tone-target algorithm (bamboo-core / vi-rs): single vowel,
    /// then ơ, then another marked vowel, then the last nucleus vowel for
    /// closed syllables; bare oo always takes its last vowel, while open
    /// oa/oe/uy shift from the penultimate to last vowel under new style.
    public static func toneTargetIndex(atoms: [BufferAtom], style: ToneStyle) -> Int? {
        var vowelIndices: [Int] = []
        for index in atoms.indices where VietnameseCharacters.isVowel(atoms[index].base) {
            vowelIndices.append(index)
        }
        guard !vowelIndices.isEmpty else { return nil }

        if vowelIndices.count >= 2 {
            let first = vowelIndices[0]
            if atoms[first].hasBase("u"), first > 0, atoms[first - 1].hasBase("q") {
                vowelIndices.removeFirst()
            } else if atoms[first].hasBase("i"), first > 0, atoms[first - 1].hasBase("g"),
                      first == 1 {
                vowelIndices.removeFirst()
            }
        }
        guard vowelIndices.count >= 2 else { return vowelIndices.first }

        for index in vowelIndices where atoms[index].hasBase("o") && atoms[index].mark == .horn {
            return index
        }
        for index in vowelIndices where atoms[index].mark != .none {
            return index
        }

        guard let lastVowelIndex = vowelIndices.last else { return nil }
        if lastVowelIndex < atoms.count - 1 {
            return lastVowelIndex
        }

        let nucleus = String(vowelIndices.map { atoms[$0].base })
        if nucleus == "oo" || (style == .new && ["oa", "oe", "uy"].contains(nucleus)) {
            return vowelIndices.last
        }
        return vowelIndices[vowelIndices.count - 2]
    }

    /// Trailing consonants that form a valid Vietnamese final cluster.
    static func trailingFinalConsonants(_ atoms: [BufferAtom]) -> String {
        guard let lastVowel = atoms.lastIndex(where: { VietnameseCharacters.isVowel($0.base) }),
              lastVowel < atoms.count - 1
        else {
            return ""
        }
        let trailing = String(atoms[(lastVowel + 1)...].map { Character(String($0.base).lowercased()) })
        for length in stride(from: min(2, trailing.count), through: 1, by: -1) {
            let candidate = String(trailing.suffix(length))
            if VietnameseOrthography.finals.contains(candidate) {
                return candidate
            }
        }
        return ""
    }

    private enum PendingUndo: Equatable {
        case tone(previous: Tone)
        case mark(index: Int, previous: DiacriticalMark)
        case doubleMark(first: Int, second: Int)
        case removeAtom(Int)
    }

    private static let toneKeys: [Character: Tone] = [
        "s": .acute, "f": .grave, "r": .hook, "x": .tilde, "j": .dotBelow,
    ]

    private static let quickConsonantMap: [Character: [Character]] = [
        "c": ["c", "h"], "g": ["g", "i"], "k": ["k", "h"], "n": ["n", "g"],
        "q": ["q", "u"], "p": ["p", "h"], "t": ["t", "h"],
    ]

    private static let standaloneWOnsets: Set<String> = {
        var onsets = VietnameseOrthography.onsets
        onsets.remove("")
        onsets.remove("qu")
        onsets.remove("gi")
        return onsets
    }()

    private static func apply(undo: PendingUndo, atoms: inout [BufferAtom], tone: inout Tone) {
        switch undo {
        case let .tone(previous):
            tone = previous
        case let .mark(index, previous):
            guard atoms.indices.contains(index) else { return }
            atoms[index].mark = previous
        case let .doubleMark(first, second):
            guard atoms.indices.contains(first), atoms.indices.contains(second) else { return }
            atoms[first].mark = .none
            atoms[second].mark = .none
        case let .removeAtom(index):
            guard atoms.indices.contains(index) else { return }
            atoms.remove(at: index)
        }
    }

    private static func appendLiteral(_ key: Character, to atoms: inout [BufferAtom]) {
        atoms.append(BufferAtom(
            base: Character(String(key).lowercased()),
            uppercase: key.isUppercase
        ))
    }

    private static func processTelexKey(
        _ key: Character,
        lower: Character,
        profile: Profile,
        atoms: inout [BufferAtom],
        tone: inout Tone
    ) -> (key: Character, undo: PendingUndo)? {
        if let newTone = toneKeys[lower] {
            guard atoms.contains(where: { VietnameseCharacters.isVowel($0.base) }) else {
                appendLiteral(key, to: &atoms)
                return nil
            }
            let final = trailingFinalConsonants(atoms)
            guard VietnameseOrthography.toneIsValid(newTone, forFinal: final) else {
                appendLiteral(key, to: &atoms)
                return nil
            }
            let previous = tone
            tone = newTone
            return (lower, .tone(previous: previous))
        }

        if lower == "z" {
            if tone != .none {
                tone = .none
            } else {
                appendLiteral(key, to: &atoms)
            }
            return nil
        }

        if lower == "a" || lower == "e" || lower == "o" {
            if let index = atoms.indices.reversed().first(where: {
                atoms[$0].hasBase(lower) && atoms[$0].mark == .none
            }) {
                atoms[index].mark = .circumflex
                return (lower, .mark(index: index, previous: .none))
            }
            appendLiteral(key, to: &atoms)
            return nil
        }

        if lower == "d", let last = atoms.indices.last, atoms[last].hasBase("d"),
           atoms[last].mark == .none {
            atoms[last].mark = .stroke
            return (lower, .mark(index: last, previous: .none))
        }

        if lower == "w" {
            return processWKey(key, profile: profile, atoms: &atoms)
        }

        if profile.allowBrackets {
            switch key {
            case "[", "{":
                atoms.append(BufferAtom(base: "o", mark: .horn, uppercase: key == "{"))
                return nil
            case "]", "}":
                atoms.append(BufferAtom(base: "u", mark: .horn, uppercase: key == "}"))
                return nil
            default:
                break
            }
        }

        if profile.quickConsonants, let digraph = quickConsonantMap[lower],
           let last = atoms.indices.last, atoms[last].hasBase(lower),
           atoms[last].mark == .none {
            let uppercase = atoms[last].uppercase
            atoms[last] = BufferAtom(base: digraph[0], uppercase: uppercase)
            atoms.append(BufferAtom(base: digraph[1], uppercase: false))
            return nil
        }

        appendLiteral(key, to: &atoms)
        return nil
    }

    private static func processWKey(
        _ key: Character,
        profile: Profile,
        atoms: inout [BufferAtom]
    ) -> (key: Character, undo: PendingUndo)? {
        if let lastIndex = atoms.indices.last, VietnameseCharacters.isVowel(atoms[lastIndex].base) {
            if let pair = lastPlainUOPair(in: atoms, endingAt: lastIndex) {
                atoms[pair.u].mark = .horn
                atoms[pair.o].mark = .horn
                return ("w", .doubleMark(first: pair.u, second: pair.o))
            }
            for index in stride(from: lastIndex, through: 0, by: -1) {
                guard VietnameseCharacters.isVowel(atoms[index].base) else { break }
                switch atoms[index].base {
                case "a" where atoms[index].mark == .none:
                    atoms[index].mark = .breve
                    return ("w", .mark(index: index, previous: .none))
                case "o", "u" where atoms[index].mark == .none && !isQuGlide(atoms: atoms, uIndex: index):
                    atoms[index].mark = .horn
                    return ("w", .mark(index: index, previous: .none))
                default:
                    continue
                }
            }
            appendLiteral(key, to: &atoms)
            return nil
        }

        let final = trailingFinalConsonants(atoms)
        if !final.isEmpty, atoms.count > final.count + 1 {
            let oIndex = atoms.count - final.count - 1
            let uIndex = oIndex - 1
            if uIndex >= 0, atoms[oIndex].hasBase("o"), atoms[oIndex].mark == .none,
               atoms[uIndex].hasBase("u"), atoms[uIndex].mark == .none,
               !isQuGlide(atoms: atoms, uIndex: uIndex) {
                atoms[uIndex].mark = .horn
                atoms[oIndex].mark = .horn
                return ("w", .doubleMark(first: uIndex, second: oIndex))
            }
        }

        if profile.allowStandaloneW {
            let buffer = String(atoms.map { Character(String($0.base).lowercased()) })
            if atoms.isEmpty || standaloneWOnsets.contains(buffer) {
                atoms.append(BufferAtom(base: "u", mark: .horn, uppercase: key.isUppercase))
                return ("w", .removeAtom(atoms.count - 1))
            }
        }

        appendLiteral(key, to: &atoms)
        return nil
    }

    private static func isQuGlide(atoms: [BufferAtom], uIndex: Int) -> Bool {
        guard uIndex > 0, atoms[uIndex].hasBase("u") else { return false }
        return atoms[uIndex - 1].hasBase("q")
    }

    private static func lastPlainUOPair(
        in atoms: [BufferAtom],
        endingAt lastIndex: Int
    ) -> (u: Int, o: Int)? {
        guard lastIndex > 0 else { return nil }
        for oIndex in stride(from: lastIndex, through: 1, by: -1) {
            guard VietnameseCharacters.isVowel(atoms[oIndex].base) else { break }
            let uIndex = oIndex - 1
            if atoms[oIndex].hasBase("o"), atoms[oIndex].mark == .none,
               atoms[uIndex].hasBase("u"), atoms[uIndex].mark == .none,
               !isQuGlide(atoms: atoms, uIndex: uIndex) {
                return (uIndex, oIndex)
            }
        }
        return nil
    }

    private static func normalizeVietnameseNucleus(atoms: inout [BufferAtom], tone: Tone) {
        if tone != .none {
            for index in atoms.indices where atoms[index].hasBase("e") && atoms[index].mark == .none {
                guard index > 0 else { continue }
                let previous = atoms[index - 1]
                if previous.hasBase("i") || previous.hasBase("y") {
                    atoms[index].mark = .circumflex
                }
            }
        }

        let rendered = String(atoms.map(\.character)).lowercased()
        let shouldUseUHorn =
            (rendered == "thươ" && tone == .hook)
                || (rendered == "hươ" && tone == .none)
                || (rendered == "khươ" && tone == .none)
        guard shouldUseUHorn else { return }
        guard let index = atoms.firstIndex(where: { $0.hasBase("u") && $0.mark == .horn }) else { return }
        atoms[index].mark = .none
    }

    /// Processes a single VNI key.
    ///
    /// Invariant: A successful tone or diacritic mark assignment returns a tuple with `pending` undo state.
    /// An invalid tone digit for the current final or an unmatched key returns `nil` without setting `pending`,
    /// dropping the invalid key digit so it does not pollute raw text or break repeat-to-undo semantics.
    private static func processVNIKey(
        _ key: Character,
        atoms: inout [BufferAtom],
        tone: inout Tone
    ) -> (key: Character, undo: PendingUndo)? {
        if let newTone = VietnameseCharacters.toneNumberKeys[key] {
            guard atoms.contains(where: { VietnameseCharacters.isVowel($0.base) }) else {
                appendLiteral(key, to: &atoms)
                return nil
            }
            let final = trailingFinalConsonants(atoms)
            guard VietnameseOrthography.toneIsValid(newTone, forFinal: final) else {
                // VNI: drop the invalid tone digit entirely.
                return nil
            }
            let previous = tone
            tone = newTone
            return (key, .tone(previous: previous))
        }
        if let mark = VietnameseCharacters.diacriticNumberKeys[key] {
            if mark == .stroke {
                guard let last = atoms.indices.last, atoms[last].hasBase("d") else {
                    appendLiteral(key, to: &atoms)
                    return nil
                }
                atoms[last].mark = .stroke
                return (key, .mark(index: last, previous: .none))
            }
            guard let vowelIndex = atoms.lastIndex(where: { VietnameseCharacters.isVowel($0.base) }) else {
                appendLiteral(key, to: &atoms)
                return nil
            }
            let previous = atoms[vowelIndex].mark
            atoms[vowelIndex].mark = mark
            return (key, .mark(index: vowelIndex, previous: previous))
        }
        appendLiteral(key, to: &atoms)
        return nil
    }
}
