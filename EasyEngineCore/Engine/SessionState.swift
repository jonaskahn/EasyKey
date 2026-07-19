public struct BufferAtom: Equatable, Sendable {
    public var base: Character
    public var mark: DiacriticalMark
    public var uppercase: Bool

    public init(base: Character, mark: DiacriticalMark = .none, uppercase: Bool = false) {
        self.base = base
        self.mark = mark
        self.uppercase = uppercase
    }

    public var character: Character {
        if VietnameseCharacters.isVowel(base) {
            return VietnameseCharacters.vowel(
                base: base, mark: mark, tone: .none, uppercase: uppercase
            )!
        }
        if base.lowercased().first == "d" && mark == .stroke {
            return VietnameseCharacters.d(withStroke: true, uppercase: uppercase)
        }
        return uppercase ? Character(base.uppercased()) : base
    }

    /// Case-insensitive base comparison — guards against a future change that
    /// stores an uppercase `base` instead of relying solely on the `uppercase` flag.
    public func hasBase(_ character: Character) -> Bool {
        base.lowercased().first == character.lowercased().first
    }
}

public extension BufferAtom? {
    func hasBase(_ character: Character) -> Bool {
        self?.hasBase(character) ?? false
    }
}

public struct SessionState: Equatable, Sendable {
    public var atoms: [BufferAtom]
    public var tone: Tone
    public var isDisabled: Bool

    public init(
        atoms: [BufferAtom] = [],
        tone: Tone = .none,
        isDisabled: Bool = false
    ) {
        self.atoms = atoms
        self.tone = tone
        self.isDisabled = isDisabled
    }

    public var isEmpty: Bool {
        atoms.isEmpty
    }

    public var count: Int {
        atoms.count
    }

    public mutating func append(_ atom: BufferAtom) {
        atoms.append(atom)
    }

    public mutating func removeLast() {
        atoms.removeLast()
    }

    public var lastAtom: BufferAtom? {
        atoms.last
    }

    public var lastVowelIndex: Int? {
        for index in stride(from: atoms.count - 1, through: 0, by: -1)
            where VietnameseCharacters.isVowel(atoms[index].base) {
            return index
        }
        return nil
    }

    /// Nearest vowel eligible for the Telex `w` breve/horn transform, bounded
    /// to the current syllable's vowel nucleus: the backward scan continues
    /// through other vowels (diphthong continuations, e.g. "ui" in "Cuiw")
    /// but stops as soon as it hits a plain consonant, since `w` only ever
    /// modifies a vowel typed immediately before it, never across an
    /// intervening consonant (e.g. "alw" must not reach back to the "a").
    public var wTransformVowelIndex: Int? {
        let onsetEndIndex: Int
        if atoms.count >= 2 {
            let prefix = String(atoms.prefix(2).map(\.base))
            onsetEndIndex = prefix == "qu" || prefix == "gi" ? 2 : 0
        } else {
            onsetEndIndex = 0
        }

        let wBases: Set<Character> = ["u", "o", "a"]
        for index in stride(from: atoms.count - 1, through: onsetEndIndex, by: -1) {
            let rawBase = atoms[index].base
            let baseChar = Character(rawBase.lowercased())
            if !VietnameseCharacters.isVowel(baseChar) {
                return nil
            }
            if wBases.contains(baseChar), atoms[index].mark == .none {
                return index
            }
        }
        return nil
    }

    public mutating func reset() {
        atoms = []
        tone = .none
    }
}
