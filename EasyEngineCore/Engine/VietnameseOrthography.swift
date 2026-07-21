import Foundation

/// Vietnamese orthography tables and syllable validation used for spell-check,
/// auto-restore, and checked-final tone rules. The validator is deliberately
/// permissive: it rejects only structurally impossible syllables (unknown
/// onset or final, impossible nucleus, checked final with a non-checked tone),
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

    /// Finals that only permit sắc or nặng (checked syllables).
    static let checkedFinals: Set<String> = ["c", "ch", "k", "p", "t"]

    static func isCheckedFinal(_ final: String) -> Bool {
        checkedFinals.contains(final)
    }

    static func toneIsValid(_ tone: Tone, forFinal final: String) -> Bool {
        guard isCheckedFinal(final) else { return true }
        return tone == .none || tone == .acute || tone == .dotBelow
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
            for character in text {
                let tone = VietnameseCharacters.tone(of: character)
                if tone != .none, tone != .acute, tone != .dotBelow {
                    return false
                }
            }
        }
        return true
    }

    static func stripAllMarksAndTones(_ text: String) -> String {
        String(text.map { VietnameseCharacters.baseLetter($0) })
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
