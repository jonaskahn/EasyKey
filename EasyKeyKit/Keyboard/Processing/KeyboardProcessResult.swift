import Foundation

struct KeyboardProcessResult {
    let suppressesOriginal: Bool
    let outputCount: Int
    let disposition: KeyboardService.Diagnostic.Disposition

    static let passed = KeyboardProcessResult(suppressesOriginal: false, outputCount: 0, disposition: .passed)
    static let suppressed = KeyboardProcessResult(suppressesOriginal: true, outputCount: 0, disposition: .suppressed)
    static let bypassed = KeyboardProcessResult(suppressesOriginal: false, outputCount: 0, disposition: .bypassed)
}
