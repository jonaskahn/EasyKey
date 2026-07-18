import Foundation

/// Ring buffer for keyboard event-tap diagnostics used by `KeyboardService`.
final class KeyboardDiagnosticsRecorder {
    private let capacity: Int
    private var enabled = false
    private var diagnostics: [KeyboardService.Diagnostic] = []

    init(capacity: Int = 128) {
        self.capacity = capacity
    }

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        if !enabled {
            diagnostics.removeAll(keepingCapacity: true)
        }
    }

    var snapshot: [KeyboardService.Diagnostic] {
        diagnostics
    }

    var medianCallbackLatencyNanoseconds: UInt64? {
        let durations = diagnostics.map(\.callbackDurationNanoseconds).sorted()
        guard !durations.isEmpty else { return nil }
        return durations[durations.count / 2]
    }

    func record(
        typeRawValue: UInt32,
        disposition: KeyboardService.Diagnostic.Disposition,
        outputCount: Int,
        bundleIdentifier: String?,
        startedAt: UInt64
    ) {
        guard enabled else { return }
        let diagnostic = KeyboardService.Diagnostic(
            eventType: typeRawValue,
            disposition: disposition,
            outputCount: outputCount,
            bundleIdentifier: bundleIdentifier,
            callbackDurationNanoseconds: DispatchTime.now().uptimeNanoseconds - startedAt
        )
        diagnostics.append(diagnostic)
        if diagnostics.count > capacity {
            diagnostics.removeFirst(diagnostics.count - capacity)
        }
    }
}
