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

/// Phonotactic confidence scoring for live display banding. Deliberately
/// advisory: boundary commit never consults these values.
enum LiveConfidence {
    static func score(rawKeys: [Character], atoms: [BufferAtom]) -> Double {
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

        let strippedAtoms = VietnameseOrthography.stripAllMarksAndTones(String(atoms.map(\.character))).lowercased()
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

    static func band(
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
        VietnameseOrthography.onsets.contains(run)
            || VietnameseOrthography.onsets.contains { $0.hasPrefix(run) && $0.count > run.count }
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
}
