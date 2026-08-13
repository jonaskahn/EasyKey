import CoreGraphics
import EasyEngineCore
@testable import EasyKeyKit
import XCTest

@MainActor
final class KeyboardTapIsolationTests: XCTestCase {
    func testKeyboardEventTapCallback_RunsOnMainThread() {
        var settings = EasyKeySettings()
        settings.input.language = .english
        let service = KeyboardService(settings: settings)
        let unmanagedService = Unmanaged.passUnretained(service)
        let opaquePointer = unmanagedService.toOpaque()

        let source = CGEventSource(stateID: .privateState)
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) else {
            XCTFail("Failed to create CGEvent")
            return
        }

        let proxy = unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
        let result = keyboardEventTapCallback(
            proxy: proxy,
            type: .keyDown,
            event: event,
            userInfo: opaquePointer
        )

        XCTAssertNotNil(result)
    }
}
