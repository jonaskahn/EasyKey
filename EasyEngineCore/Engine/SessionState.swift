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
            ) ?? base
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

/// Engine buffer. `rawKeys` is the source of truth; `atoms`/`tone` are the
/// composed result derived from it by `TelexComposer`. Keeping raw keys makes
/// exact repeat-to-undo, backspace, and word restoration trivial.
public struct SessionState: Equatable, Sendable {
    public internal(set) var rawKeys: [Character]
    public internal(set) var atoms: [BufferAtom]
    public internal(set) var tone: Tone
    public internal(set) var isDisabled: Bool
    /// When true the buffer renders raw keys verbatim (per-word restore).
    public internal(set) var forceRaw: Bool
    /// True when Telex repeat-to-undo froze the rest of the word as literal
    /// text (iOS-UniKey-like mode). Derived deterministically from `rawKeys`.
    public internal(set) var isEscaped: Bool

    public init(
        rawKeys: [Character] = [],
        atoms: [BufferAtom] = [],
        tone: Tone = .none,
        isDisabled: Bool = false,
        forceRaw: Bool = false,
        isEscaped: Bool = false
    ) {
        self.rawKeys = rawKeys
        self.atoms = atoms
        self.tone = tone
        self.isDisabled = isDisabled
        self.forceRaw = forceRaw
        self.isEscaped = isEscaped
    }

    public var isEmpty: Bool {
        rawKeys.isEmpty
    }

    public var count: Int {
        atoms.count
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

    public var rawText: String {
        String(rawKeys)
    }

    public mutating func reset() {
        rawKeys = []
        atoms = []
        tone = .none
        forceRaw = false
        isEscaped = false
    }
}
