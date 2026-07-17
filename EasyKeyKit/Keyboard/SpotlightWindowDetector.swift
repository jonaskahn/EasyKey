import CoreGraphics
import Foundation

/// Detects the Spotlight search panel by scanning on-screen windows.
///
/// Spotlight is an agent overlay: opening it fires no workspace activation
/// notification and the frontmost application stays unchanged, so the only
/// dependable signal that keystrokes are going to Spotlight is an on-screen
/// window owned by the `Spotlight` process. `kCGWindowOwnerName` is readable
/// without the Screen Recording permission (only `kCGWindowName` requires it).
enum SpotlightWindowDetector {
    static func isSpotlightWindowVisible() -> Bool {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        return windows.contains { window in
            window[kCGWindowOwnerName as String] as? String == "Spotlight"
        }
    }
}
