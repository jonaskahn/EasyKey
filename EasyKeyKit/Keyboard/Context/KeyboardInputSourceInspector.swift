import Carbon.HIToolbox
import Foundation

/// Reads the current keyboard input source to decide whether the active
/// layout is foreign to Vietnamese processing.
enum KeyboardInputSourceInspector {
    static func isCurrentInputSourceForeign() -> Bool {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let languages = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages)
        else {
            return false
        }
        let languageCodes = Unmanaged<CFArray>.fromOpaque(languages).takeUnretainedValue() as NSArray
        guard let languageCodes = languageCodes as? [String] else { return false }
        return !languageCodes.contains { $0.lowercased().hasPrefix("en") }
    }
}
