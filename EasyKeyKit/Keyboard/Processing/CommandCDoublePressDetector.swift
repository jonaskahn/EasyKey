import Carbon.HIToolbox
import CoreGraphics
import Foundation

/// Detects double-press of Command-C from event timestamps and delivers the
/// action asynchronously on the main queue.
final class CommandCDoublePressDetector {
    private var handler: (@MainActor () -> Void)?
    private var windowMs: Int = 400
    private var lastTimestamp: UInt64?

    func setHandler(windowMs: Int, handler: @escaping @MainActor () -> Void) {
        self.windowMs = windowMs
        self.handler = handler
    }

    func clearHandler() {
        handler = nil
        lastTimestamp = nil
    }

    func record(keyCode: UInt16, event: CGEvent) {
        guard let handler else { return }
        guard keyCode == UInt16(kVK_ANSI_C),
              event.flags.contains(.maskCommand),
              !event.flags.contains(.maskAlternate),
              !event.flags.contains(.maskControl)
        else {
            lastTimestamp = nil
            return
        }

        let now = event.timestamp

        if let last = lastTimestamp,
           timestampDeltaMs(lhs: last, rhs: now) <= Double(windowMs) {
            lastTimestamp = nil
            DispatchQueue.main.async { handler() }
            return
        }

        lastTimestamp = now
    }

    private func timestampDeltaMs(lhs: UInt64, rhs: UInt64) -> Double {
        let delta: UInt64
        if rhs >= lhs {
            delta = rhs - lhs
        } else {
            delta = lhs - rhs
        }
        return Double(delta) / 1_000_000.0
    }
}
