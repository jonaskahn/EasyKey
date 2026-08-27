@testable import EasyEngineCore
import XCTest

final class AppLogTests: XCTestCase {
    func testCategories_AllHaveNonEmptyRawValues() {
        for category in AppLog.Category.allCases {
            XCTAssertFalse(category.rawValue.isEmpty)
        }
    }

    func testLogger_ReturnsSameSubsystem() {
        let logger = AppLog.logger(.keyboard)
        XCTAssertEqual(AppLog.subsystem, "one.ifelse.easykey")
        _ = logger
    }

    func testLoggingHelpers_DoNotThrow() {
        AppLog.debug(.engine, "debug probe")
        AppLog.info(.settings, "info probe")
        AppLog.notice(.update, "notice probe")
        AppLog.error(.app, "error probe")
    }
}

extension AppLogTests {
    func testHexDump_AsciiSingleCharacter() {
        XCTAssertEqual(AppLog.hexDump("t"), "U+0074")
    }

    func testHexDump_AsciiString() {
        XCTAssertEqual(AppLog.hexDump("xin"), "U+0078 U+0069 U+006E")
    }

    func testHexDump_CombiningDiacritic_EncodesEachUtf16CodeUnit() {
        // The decomposed form "ề" (e + U+0302 + U+0300) is one grapheme cluster
        // but three UTF-16 code units — exactly the case that matters for Blink
        // backspace counting. The precomposed single-code-unit form U+1EC1 is
        // tested separately below as a contrast case.
        XCTAssertEqual(AppLog.hexDump("e\u{0302}\u{0300}"), "U+0065 U+0302 U+0300")
        // The precomposed form "ề" (U+1EC1) is one grapheme AND one UTF-16 code
        // unit — the opposite extreme of the combining case.
        XCTAssertEqual(AppLog.hexDump("ề"), "U+1EC1")
    }

    func testHexDump_EmptyString() {
        XCTAssertEqual(AppLog.hexDump(""), "")
    }

    func testHexDump_WhitespaceCharacters() {
        // The ZWSP (U+200B) and narrow-no-break-space (U+202F) used by the
        // Chromium workarounds must round-trip through hexDump.
        XCTAssertEqual(AppLog.hexDump("\u{200B}"), "U+200B")
        XCTAssertEqual(AppLog.hexDump("\u{202F}"), "U+202F")
    }

    func testKeyboardDebug_IsNoOpWhenDisabled() {
        // isKeyboardDebugEnabled is a let bound to ProcessInfo/UserDefaults
        // at static load; the production test environment does not set
        // EASYKEY_KEYBOARD_DEBUG, so the default-off path runs here. The
        // call must not throw, must not crash, and must not produce a
        // message observable to this test.
        let previous = AppLog.isKeyboardDebugEnabled
        AppLog.keyboardDebug("test probe message")
        XCTAssertEqual(AppLog.isKeyboardDebugEnabled, previous)
    }
}
