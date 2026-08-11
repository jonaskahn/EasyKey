import Foundation

/// Advisory live-display confidence band. Boundary commit never consults this value.
enum LiveConfidenceBand: String, Sendable {
    case high
    case middle
    case low
}

public enum LiveConfidenceDefaults {
    public static let lowThreshold = 0.35
    public static let highThreshold = 0.80
}

/// Vietnamese orthography tables and syllable validation used for spell-check,
/// auto-restore, and checked-final tone rules. The validator is deliberately
/// permissive: it rejects only structurally impossible syllables (unknown
/// onset or final, impossible nucleus, or a checked final without sắc/nặng),
/// so auto-restore fires on clear non-Vietnamese input and leaves ambiguous
/// words alone.
enum VietnameseOrthography {
    static let onsets: Set<String> = [
        "", "b", "c", "ch", "d", "đ", "g", "gh", "gi", "h", "k", "kh", "l",
        "m", "n", "ng", "ngh", "nh", "p", "ph", "qu", "r", "s", "t", "th",
        "tr", "v", "x",
    ]

    static let onsetsByLength: [String] =
        onsets.sorted { $0.count > $1.count || ($0.count == $1.count && $0 < $1) }

    static let finals: Set<String> = [
        "c", "ch", "k", "m", "n", "ng", "nh", "p", "t",
    ]

    /// Finals that require sắc or nặng (checked syllables). Toneless checked
    /// finals are incomplete Vietnamese and fail Tier 1 validation.
    static let checkedFinals: Set<String> = ["c", "ch", "k", "p", "t"]

    static func isCheckedFinal(_ final: String) -> Bool {
        checkedFinals.contains(final)
    }

    static func toneIsValid(_ tone: Tone, forFinal final: String) -> Bool {
        guard isCheckedFinal(final) else { return true }
        return tone == .acute || tone == .dotBelow
    }

    /// Valid nuclei keyed by plain-base cluster (marks stripped). Bare `uo`
    /// is intentionally absent: it only exists as uô/ươ/uơ.
    static let plainNuclei: Set<String> = [
        "a", "e", "i", "o", "u", "y",
        "ai", "ao", "au", "ay", "eo", "eu", "ia", "ie", "iu", "oa", "oe",
        "oi", "oo", "ua", "ue", "ui", "uy", "ye",
        "oai", "oao", "oay", "oeo", "uay", "uya", "uye", "uyu", "yeu",
    ]

    /// Nuclei that only exist with a mark applied (keyed by marked form).
    static let markedNuclei: Set<String> = [
        "â", "ă", "ê", "ô", "ơ", "ư",
        "âu", "ây", "êu", "ôi", "ơi", "ưa", "ưi", "ưu", "uơ", "ươ",
        "iê", "uô", "yê",
        "iêu", "yêu", "uôi", "ươi", "ươu", "uây", "uyê",
    ]

    /// Whether a fully-composed (accented) word is orthographically valid.
    static func isValidWord(_ word: String) -> Bool {
        isValidSyllable(word)
    }

    static func isValidSyllable(_ text: String) -> Bool {
        let stripped = stripAllMarksAndTones(text).lowercased()
        guard let syllable = Syllable.parse(stripped) else { return false }

        guard onsets.contains(syllable.onset) else { return false }
        guard syllable.final.isEmpty || finals.contains(syllable.final) else { return false }

        let markedNucleus = composedNucleus(of: text, syllable: syllable)
        let plainNucleus = syllable.nucleus
        let nucleusIsValid =
            markedNuclei.contains(markedNucleus)
                || (plainNuclei.contains(plainNucleus) && markedNucleus == plainNucleus)
        guard nucleusIsValid else { return false }

        if isCheckedFinal(syllable.final) {
            var hasCheckedTone = false
            for character in text {
                let tone = VietnameseCharacters.tone(of: character)
                switch tone {
                case .acute, .dotBelow:
                    hasCheckedTone = true
                case .none:
                    break
                case .grave, .hook, .tilde:
                    return false
                }
            }
            guard hasCheckedTone else { return false }
        }
        return true
    }

    static func stripAllMarksAndTones(_ text: String) -> String {
        String(text.map { VietnameseCharacters.baseLetter($0) })
    }

    /// Advisory phonotactic confidence in `[0, 1]` for live display banding.
    static func liveConfidenceScore(rawKeys: [Character], atoms: [BufferAtom]) -> Double {
        var score = LiveConfidenceScoring.baseScore

        let onsetRun = leadingConsonantRun(of: atoms)
        if isLegalOnsetPrefix(onsetRun) {
            score += LiveConfidenceScoring.legalOnsetBonus
        } else {
            score -= LiveConfidenceScoring.illegalOnsetPenalty
            if onsetRun.count >= LiveConfidenceScoring.longIllegalOnsetMinimumCount {
                score -= LiveConfidenceScoring.longIllegalOnsetExtraPenalty
            }
        }

        let strippedAtoms = stripAllMarksAndTones(String(atoms.map(\.character))).lowercased()
        if Syllable.parse(strippedAtoms) != nil {
            score += LiveConfidenceScoring.parsableSyllableBonus
        }

        let density = modifierDensity(in: rawKeys)
        score += LiveConfidenceScoring.modifierDensityBonusScale
            * min(1.0, density * LiveConfidenceScoring.modifierDensitySaturationFactor)

        if density == 0 {
            if rawKeys.count >= LiveConfidenceScoring.longNoModifierMinimumKeyCount {
                score -= LiveConfidenceScoring.longNoModifierPenalty
            } else if rawKeys.count >= LiveConfidenceScoring.mediumNoModifierMinimumKeyCount {
                score -= LiveConfidenceScoring.mediumNoModifierPenalty
            }
        }

        return min(LiveConfidenceScoring.maximumScore, max(LiveConfidenceScoring.minimumScore, score))
    }

    static func liveConfidenceBand(
        score: Double,
        lowThreshold: Double,
        highThreshold: Double
    ) -> LiveConfidenceBand {
        if score < lowThreshold {
            return .low
        }
        if score >= highThreshold {
            return .high
        }
        return .middle
    }

    private enum LiveConfidenceScoring {
        static let baseScore = 0.55
        static let legalOnsetBonus = 0.25
        static let illegalOnsetPenalty = 0.40
        static let longIllegalOnsetExtraPenalty = 0.15
        static let longIllegalOnsetMinimumCount = 3
        static let parsableSyllableBonus = 0.20
        static let modifierDensityBonusScale = 0.20
        static let modifierDensitySaturationFactor = 4.0
        static let longNoModifierPenalty = 0.30
        static let mediumNoModifierPenalty = 0.20
        static let longNoModifierMinimumKeyCount = 8
        static let mediumNoModifierMinimumKeyCount = 6
        static let minimumScore = 0.0
        static let maximumScore = 1.0
    }

    private static func leadingConsonantRun(of atoms: [BufferAtom]) -> String {
        var run = ""
        for atom in atoms {
            let base = Character(VietnameseCharacters.baseLetter(atom.character).lowercased())
            if VietnameseCharacters.isVowel(base) {
                break
            }
            run.append(base)
        }
        return run
    }

    private static func isLegalOnsetPrefix(_ run: String) -> Bool {
        onsets.contains(run)
            || onsets.contains { $0.hasPrefix(run) && $0.count > run.count }
    }

    private static func modifierDensity(in rawKeys: [Character]) -> Double {
        guard !rawKeys.isEmpty else { return 0 }
        let modifierCount = rawKeys.filter(isModifierKey).count
        return Double(modifierCount) / Double(rawKeys.count)
    }

    private static let telexModifierKeys: Set<Character> = [
        "w", "j", "f", "x", "r", "s", "z",
    ]

    private static func isModifierKey(_ character: Character) -> Bool {
        let lower = Character(character.lowercased())
        guard !telexModifierKeys.contains(lower) else { return true }
        guard VietnameseCharacters.toneNumberKeys[character] == nil else { return true }
        return VietnameseCharacters.diacriticNumberKeys[character] != nil
    }

    private static func composedNucleus(of text: String, syllable: Syllable) -> String {
        let characters = Array(text.lowercased())
        let start = syllable.onset.count
        let end = characters.count - syllable.final.count
        guard start < end, characters.indices.contains(start), end <= characters.count else {
            return syllable.nucleus
        }
        return String(characters[start ..< end].map { VietnameseCharacters.removingTone(from: $0) })
    }
}
