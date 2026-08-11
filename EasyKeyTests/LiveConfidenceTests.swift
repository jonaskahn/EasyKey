@testable import EasyEngineCore
import XCTest

final class LiveConfidenceTests: XCTestCase {
    func testIllegalOnsetRunScoresBelowLowThreshold() {
        let atoms = atoms(from: "str")

        let score = VietnameseOrthography.liveConfidenceScore(
            rawKeys: Array("str"),
            atoms: atoms
        )

        XCTAssertLessThan(score, LiveConfidenceDefaults.lowThreshold)
        XCTAssertEqual(band(for: score), .low)
    }

    func testVietnameseShapeWithModifiersScoresAtLeastMiddle() {
        let viet = TelexComposer.compose(
            rawKeys: Array("viet"),
            configuration: EngineConfiguration()
        )

        let score = VietnameseOrthography.liveConfidenceScore(
            rawKeys: Array("viet"),
            atoms: viet.atoms
        )

        XCTAssertGreaterThanOrEqual(score, LiveConfidenceDefaults.lowThreshold)
    }

    func testMarkedVietnameseWordScoresHigh() {
        let nguoiw = TelexComposer.compose(
            rawKeys: Array("nguoiw"),
            configuration: EngineConfiguration()
        )

        let score = VietnameseOrthography.liveConfidenceScore(
            rawKeys: Array("nguoiw"),
            atoms: nguoiw.atoms
        )

        XCTAssertGreaterThanOrEqual(score, LiveConfidenceDefaults.highThreshold)
        XCTAssertEqual(band(for: score), .high)
    }

    func testLongNoModifierEnglishLikeRunDepressesScoreBelowShortIllegalRun() {
        let shortIllegal = VietnameseOrthography.liveConfidenceScore(
            rawKeys: Array("bb"),
            atoms: atoms(from: "bb")
        )
        let longEnglish = VietnameseOrthography.liveConfidenceScore(
            rawKeys: Array("bbbccc"),
            atoms: atoms(from: "bbbccc")
        )

        XCTAssertLessThan(longEnglish, shortIllegal)
        XCTAssertLessThan(longEnglish, LiveConfidenceDefaults.lowThreshold)
    }

    func testDefaultThresholdsClassifyLowMiddleAndHighBands() {
        XCTAssertEqual(band(for: 0.20), .low)
        XCTAssertEqual(band(for: 0.55), .middle)
        XCTAssertEqual(band(for: 0.85), .high)
    }

    func testLowConfidenceLiveDisplayShowsRawWhileAtomsStayComposed() {
        var engine = VietnameseEngine(configuration: liveConfidenceEnabledConfiguration())

        typeKeys(&engine, "str")

        XCTAssertEqual(engine.currentBuffer, "str")
        XCTAssertEqual(engine.state.rawText, "str")
        XCTAssertFalse(engine.state.atoms.isEmpty)
        XCTAssertTrue(engine.displaysRawKeystrokes)
    }

    func testLiveDisplayFlipsToComposedWhenShapeBecomesVietnamese() {
        var engine = VietnameseEngine(configuration: liveConfidenceEnabledConfiguration())

        typeKeys(&engine, "bb")
        XCTAssertEqual(engine.currentBuffer, "bb")
        XCTAssertTrue(engine.displaysRawKeystrokes)

        typeKeys(&engine, "aw")

        XCTAssertFalse(engine.displaysRawKeystrokes)
        XCTAssertEqual(engine.state.rawText, "bbaw")
        XCTAssertEqual(engine.currentBuffer, "bbă")
    }

    func testForceRawOverridesLiveConfidenceBand() {
        var engine = VietnameseEngine(configuration: liveConfidenceEnabledConfiguration())

        typeKeys(&engine, "viet")
        XCTAssertFalse(engine.displaysRawKeystrokes)

        _ = engine.restoreRawKeys()

        XCTAssertTrue(engine.state.forceRaw)
        XCTAssertEqual(engine.currentBuffer, engine.state.rawText)
        XCTAssertTrue(engine.displaysRawKeystrokes)
    }

    func testLowBandDisplayStillCommitsComposedWhenWordIsValid() {
        var engine = VietnameseEngine(
            configuration: EngineConfiguration(
                spellCheck: true,
                autoRestoreKeys: true,
                liveConfidenceScoring: true,
                liveConfidenceLowThreshold: 1.01,
                liveConfidenceHighThreshold: 1.02
            )
        )
        typeKeys(&engine, "an")
        XCTAssertTrue(engine.displaysRawKeystrokes)
        let composedBefore = TransformEngine.encode(engine.state, configuration: engine.configuration)
        XCTAssertEqual(composedBefore, "an")

        let result = engine.process(event: KeyEvent(kind: .space))

        XCTAssertEqual(result.sessionEffect, .resetSession)
        guard case let .replaceBackward(_, insert) = result.edits.first else {
            return XCTFail("Expected replaceBackward at boundary")
        }
        XCTAssertEqual(insert, composedBefore)
    }

    func testInvalidWordStillAutoRestoresRawRegardlessOfLiveBand() {
        var engine = VietnameseEngine(
            configuration: liveConfidenceEnabledConfiguration(
                spellCheck: true,
                autoRestore: true
            )
        )
        typeKeys(&engine, "xyzzy")
        let raw = engine.state.rawText

        let result = engine.process(event: KeyEvent(kind: .space))

        guard case let .replaceBackward(_, insert) = result.edits.first else {
            return XCTFail("Expected replaceBackward at boundary")
        }
        XCTAssertEqual(insert, raw)
    }

    func testDisabledLiveConfidenceMatchesComposedLiveBuffer() {
        var liveOff = VietnameseEngine(configuration: EngineConfiguration())
        var liveOn = VietnameseEngine(configuration: liveConfidenceEnabledConfiguration())
        XCTAssertFalse(liveOff.configuration.liveConfidenceScoring)

        typeKeys(&liveOff, "vietj")
        typeKeys(&liveOn, "vietj")

        let composed = TransformEngine.encode(liveOff.state, configuration: liveOff.configuration)
        XCTAssertEqual(liveOff.currentBuffer, composed)
        XCTAssertEqual(liveOn.currentBuffer, composed)
    }

    func testDisabledLiveConfidenceShowsComposedBufferForEnglishLikeInput() {
        var engine = VietnameseEngine(configuration: EngineConfiguration())

        typeKeys(&engine, "str")

        XCTAssertFalse(engine.configuration.liveConfidenceScoring)
        XCTAssertEqual(
            engine.currentBuffer,
            TransformEngine.encode(engine.state, configuration: engine.configuration)
        )
        XCTAssertFalse(engine.displaysRawKeystrokes)
    }

    private func liveConfidenceEnabledConfiguration(
        spellCheck: Bool = true,
        autoRestore: Bool = true
    ) -> EngineConfiguration {
        EngineConfiguration(
            spellCheck: spellCheck,
            autoRestoreKeys: autoRestore,
            liveConfidenceScoring: true,
            liveConfidenceLowThreshold: LiveConfidenceDefaults.lowThreshold,
            liveConfidenceHighThreshold: LiveConfidenceDefaults.highThreshold
        )
    }

    private func band(for score: Double) -> LiveConfidenceBand {
        VietnameseOrthography.liveConfidenceBand(
            score: score,
            lowThreshold: LiveConfidenceDefaults.lowThreshold,
            highThreshold: LiveConfidenceDefaults.highThreshold
        )
    }

    private func atoms(from text: String) -> [BufferAtom] {
        text.map { BufferAtom(base: Character($0.lowercased())) }
    }

    private func typeKeys(_ engine: inout VietnameseEngine, _ keys: String) {
        for character in keys {
            _ = engine.process(event: .char(character))
        }
    }
}
