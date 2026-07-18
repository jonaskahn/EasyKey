import Foundation

public enum TransformIntent: Equatable, Sendable {
    case addTone(Tone)
    case addMark(DiacriticalMark)
    case transformDStroke
    case revertDStroke
    case transformDoubleVowel(base: Character, mark: DiacriticalMark)
    case revertDoubleVowel(base: Character)
    case transformW
    case passThrough(Character)
}

public enum TelexRules {
    private static let toneKeys: [Character: Tone] = [
        "s": .acute, "f": .grave, "r": .hook, "x": .tilde, "j": .dotBelow,
    ]

    private static let doubleVowelKeys: Set<Character> = ["a", "e", "o"]

    public static func intent(forCharacter character: Character, previousChar: Character?) -> TransformIntent? {
        let lower = character.lowercased().first ?? character

        if let tone = toneKeys[lower] {
            return .addTone(tone)
        }

        if doubleVowelKeys.contains(lower), let previousChar {
            let previousLower = previousChar.lowercased().first
            let circumflexChar = VietnameseCharacters.vowel(base: lower, mark: .circumflex, tone: .none, uppercase: false)
            if previousLower == circumflexChar {
                return .revertDoubleVowel(base: lower)
            }
            if previousLower == lower {
                return .transformDoubleVowel(base: lower, mark: .circumflex)
            }
        }

        if lower == "d" {
            if previousChar?.lowercased().first == "d" {
                return .transformDStroke
            }
            if previousChar?.lowercased().first == "đ" {
                return .revertDStroke
            }
        }

        if lower == "w" {
            return .transformW
        }

        return .passThrough(character)
    }
}

public enum VNIRules {
    public static func intent(forCharacter character: Character) -> TransformIntent? {
        if let tone = VietnameseCharacters.toneNumberKeys[character] {
            return .addTone(tone)
        }
        if let mark = VietnameseCharacters.diacriticNumberKeys[character] {
            return mark == .stroke ? .transformDStroke : .addMark(mark)
        }
        return .passThrough(character)
    }
}

public enum SimpleTelexRules {
    private static let toneKeys: [Character: Tone] = [
        "s": .acute, "f": .grave, "r": .hook, "x": .tilde, "j": .dotBelow,
    ]

    public static func intent(forCharacter character: Character, previousChar: Character?) -> TransformIntent? {
        let lower = character.lowercased().first ?? character

        if let tone = toneKeys[lower] {
            return .addTone(tone)
        }

        if lower == "d" {
            if previousChar?.lowercased().first == "d" {
                return .transformDStroke
            }
            if previousChar?.lowercased().first == "đ" {
                return .revertDStroke
            }
        }

        return .passThrough(character)
    }
}
