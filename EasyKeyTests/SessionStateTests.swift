@testable import EasyEngineCore
import XCTest

final class SessionStateTests: XCTestCase {
    func testAppendAndCount() {
        var state = SessionState()
        XCTAssertTrue(state.isEmpty)
        XCTAssertEqual(state.count, 0)
        state.append(BufferAtom(base: "a"))
        XCTAssertEqual(state.count, 1)
        XCTAssertFalse(state.isEmpty)
    }

    func testRemoveLastSingle() {
        var state = SessionState(atoms: [BufferAtom(base: "a"), BufferAtom(base: "b")])
        state.removeLast()
        XCTAssertEqual(state.count, 1)
        XCTAssertEqual(state.atoms.first?.base, "a")
    }

    func testRemoveLastMultiple() {
        var state = SessionState(atoms: [
            BufferAtom(base: "a"),
            BufferAtom(base: "b"),
            BufferAtom(base: "c"),
            BufferAtom(base: "d"),
        ])
        state.removeLast(2)
        XCTAssertEqual(state.count, 2)
        XCTAssertEqual(state.atoms.map(\.base), ["a", "b"])
    }

    func testLastVowelIndexWithVowels() {
        let state = SessionState(atoms: [
            BufferAtom(base: "t"),
            BufferAtom(base: "a"),
            BufferAtom(base: "i"),
        ])
        XCTAssertEqual(state.lastVowelIndex, 2)
    }

    func testLastVowelIndexNoVowels() {
        let state = SessionState(atoms: [
            BufferAtom(base: "t"),
            BufferAtom(base: "n"),
            BufferAtom(base: "g"),
        ])
        XCTAssertNil(state.lastVowelIndex)
    }

    func testLastVowelIndexEmpty() {
        let state = SessionState()
        XCTAssertNil(state.lastVowelIndex)
    }

    func testLastVowelIndexMultipleVowels() {
        let state = SessionState(atoms: [
            BufferAtom(base: "b"),
            BufferAtom(base: "u"),
            BufferAtom(base: "o"),
            BufferAtom(base: "n"),
        ])
        XCTAssertEqual(state.lastVowelIndex, 2)
    }

    func testCharacterVowelWithMark() {
        let atom = BufferAtom(base: "a", mark: .circumflex)
        XCTAssertEqual(atom.character, "â")
    }

    func testCharacterVowelWithMarkAndTone_notAffectsCharacter() {
        let atom = BufferAtom(base: "a", mark: .breve)
        XCTAssertEqual(atom.character, "ă")
    }

    func testCharacterDStroke() {
        let atom = BufferAtom(base: "d", mark: .stroke)
        XCTAssertEqual(atom.character, "đ")
    }

    func testCharacterDUppercaseStroke() {
        let atom = BufferAtom(base: "D", mark: .stroke, uppercase: true)
        XCTAssertEqual(atom.character, "Đ")
    }

    func testCharacterUppercaseConsonant() {
        let atom = BufferAtom(base: "t", uppercase: true)
        XCTAssertEqual(atom.character, "T")
    }

    func testCharacterLowercaseConsonant() {
        let atom = BufferAtom(base: "t")
        XCTAssertEqual(atom.character, "t")
    }

    func testCharacterNonDStrokeConsonantWithStrokeMark() {
        let atom = BufferAtom(base: "b", mark: .stroke)
        XCTAssertEqual(atom.character, "b")
    }

    func testResetClearsAll() {
        var state = SessionState(
            atoms: [BufferAtom(base: "a")],
            tone: .acute,
            wordStartIndex: 2,
            isDisabled: true,
            isSpellDisabled: true
        )
        state.reset()
        XCTAssertTrue(state.atoms.isEmpty)
        XCTAssertEqual(state.tone, .none)
        XCTAssertEqual(state.wordStartIndex, 0)
    }

    func testIsDisabledFlag() {
        var state = SessionState(isDisabled: true)
        XCTAssertTrue(state.isDisabled)
        state.isDisabled = false
        XCTAssertFalse(state.isDisabled)
    }

    func testLastAtomWhenEmpty() {
        let state = SessionState()
        XCTAssertNil(state.lastAtom)
    }

    func testLastAtomWhenNotEmpty() {
        let state = SessionState(atoms: [BufferAtom(base: "a")])
        XCTAssertEqual(state.lastAtom?.base, "a")
    }
}
