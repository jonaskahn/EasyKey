@testable import EasyEngineCore
import XCTest

func typeKeys(_ engine: inout VietnameseEngine, _ keys: String) {
    for character in keys {
        _ = engine.process(event: .char(character))
    }
}
