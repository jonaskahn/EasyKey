import Foundation

public protocol VietnameseEncoding {
    func encode(atoms: [BufferAtom], tone: Tone, toneTargetIndex: Int?) -> String
}

public struct UnicodePrecomposedEncoding: VietnameseEncoding {
    public init() {}

    public func encode(atoms: [BufferAtom], tone: Tone, toneTargetIndex: Int?) -> String {
        var result = ""
        for (i, atom) in atoms.enumerated() {
            if VietnameseCharacters.isVowel(atom.base) {
                let appliedTone: Tone = (i == toneTargetIndex) ? tone : .none
                if let composed = VietnameseCharacters.vowel(
                    base: atom.base, mark: atom.mark, tone: appliedTone, uppercase: atom.uppercase
                ) {
                    result.append(composed)
                } else {
                    result.append(atom.character)
                }
            } else if atom.base == "d", atom.mark == .stroke {
                result.append(VietnameseCharacters.d(withStroke: true, uppercase: atom.uppercase))
            } else {
                result.append(atom.character)
            }
        }
        return result
    }
}

public struct TCVN3Encoding: VietnameseEncoding {
    public init() {}

    private static let baseMap: [Character: Character] = [
        "â": "\u{00A2}", "Ă": "\u{00C2}", "ă": "\u{00E2}",
        "ê": "\u{00CA}", "Ê": "\u{00CA}",
        "ô": "\u{00D4}", "Ô": "\u{00D4}",
        "ơ": "\u{00A3}", "Ơ": "\u{00A3}",
        "ư": "\u{00B5}", "Ư": "\u{00B5}",
        "đ": "\u{00D0}", "Đ": "\u{00D0}",
    ]

    public func encode(atoms: [BufferAtom], tone: Tone, toneTargetIndex: Int?) -> String {
        let precomposed = UnicodePrecomposedEncoding()
        let unicode = precomposed.encode(atoms: atoms, tone: tone, toneTargetIndex: toneTargetIndex)
        return EncodingCodec.encode(unicode, as: .tcvn3)
    }
}

public struct VNIWindowsEncoding: VietnameseEncoding {
    public init() {}

    public func encode(atoms: [BufferAtom], tone: Tone, toneTargetIndex: Int?) -> String {
        let precomposed = UnicodePrecomposedEncoding()
        let unicode = precomposed.encode(atoms: atoms, tone: tone, toneTargetIndex: toneTargetIndex)
        return EncodingCodec.encode(unicode, as: .vniWindows)
    }
}

public struct UnicodeCombiningEncoding: VietnameseEncoding {
    public init() {}

    private static let toneCombining: [Tone: Character] = [
        .acute: "\u{0301}",
        .grave: "\u{0300}",
        .hook: "\u{0309}",
        .tilde: "\u{0303}",
        .dotBelow: "\u{0323}",
    ]

    private static let markCombining: [DiacriticalMark: Character] = [
        .circumflex: "\u{0302}",
        .breve: "\u{0306}",
        .horn: "\u{031B}",
    ]

    public func encode(atoms: [BufferAtom], tone: Tone, toneTargetIndex: Int?) -> String {
        var result = ""
        for (i, atom) in atoms.enumerated() {
            if atom.base == "d" && atom.mark == .stroke {
                result.append(VietnameseCharacters.d(withStroke: true, uppercase: atom.uppercase))
                continue
            }

            let base = atom.uppercase ? Character(atom.base.uppercased()) : atom.base
            result.append(base)

            if let markChar = Self.markCombining[atom.mark] {
                result.append(markChar)
            }

            if i == toneTargetIndex, let toneChar = Self.toneCombining[tone] {
                result.append(toneChar)
            }
        }
        return result
    }
}

public struct CP1258Encoding: VietnameseEncoding {
    public init() {}

    public func encode(atoms: [BufferAtom], tone: Tone, toneTargetIndex: Int?) -> String {
        let combining = UnicodeCombiningEncoding()
        return combining.encode(atoms: atoms, tone: tone, toneTargetIndex: toneTargetIndex)
    }
}

public enum EncodingFactory {
    public static func encoding(for table: EncodingTable) -> VietnameseEncoding {
        switch table {
        case .unicode: UnicodePrecomposedEncoding()
        case .unicodeCombining: UnicodeCombiningEncoding()
        case .tcvn3: TCVN3Encoding()
        case .vniWindows: VNIWindowsEncoding()
        case .cp1258: CP1258Encoding()
        }
    }
}
