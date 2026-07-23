import AppKit
import EasyEngineCore

/// Polls `NSPasteboard` for external clipboard changes while capture is enabled,
/// rejecting sensitive and own-authored events, then hands classified entries to
/// a capture callback. `poll()` is directly test-callable; the production timer
/// only invokes it.
@MainActor
final class ClipboardMonitor {
    private let reader: PasteboardReading
    private let classifier: PasteboardClassifier
    private let suppressor: ClipboardWriteSuppressor
    private let now: () -> Date
    private let sourceProvider: () -> ClipboardSource?
    private let onCapture: (ClassifiedClipboard) -> Void

    private var options: ClipboardOptions
    private var observedChangeCount: Int
    private var timer: Timer?

    static let pollInterval: TimeInterval = 0.3

    init(
        reader: PasteboardReading,
        classifier: PasteboardClassifier = PasteboardClassifier(),
        suppressor: ClipboardWriteSuppressor,
        options: ClipboardOptions,
        now: @escaping () -> Date = { Date() },
        sourceProvider: @escaping () -> ClipboardSource? = { nil },
        onCapture: @escaping (ClassifiedClipboard) -> Void
    ) {
        self.reader = reader
        self.classifier = classifier
        self.suppressor = suppressor
        self.options = options
        self.now = now
        self.sourceProvider = sourceProvider
        self.onCapture = onCapture
        observedChangeCount = reader.changeCount
    }

    var isRunning: Bool {
        timer != nil
    }

    func start() {
        guard timer == nil else { return }
        observedChangeCount = reader.changeCount
        let timer = Timer(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func apply(_ options: ClipboardOptions) {
        self.options = options
    }

    /// Re-syncs the observed count without capturing, e.g. after wake, so stale
    /// pre-sleep clipboard contents are not replayed.
    func refreshObservedCount() {
        observedChangeCount = reader.changeCount
    }

    func poll() {
        guard options.isCaptureEnabled, !options.capturedKinds.isEmpty else { return }
        let current = reader.changeCount
        guard current != observedChangeCount else { return }

        if suppressor.shouldSuppress(current) {
            observedChangeCount = current
            return
        }

        let descriptor = reader.descriptor()
        guard descriptor.changeCount == current else {
            observedChangeCount = current
            return
        }

        let allTypes = descriptor.items.flatMap(\.typeIdentifiers)
        guard !SensitivePasteboardMarkers.contains(allTypes) else {
            observedChangeCount = current
            return
        }

        let source = sourceProvider()
        if let bundle = source?.bundleIdentifier,
           options.ignoredApplicationBundleIdentifiers.contains(bundle) {
            observedChangeCount = current
            return
        }

        let snapshot = reader.snapshot(selecting: classifier.selection(for: descriptor, capturedKinds: options.capturedKinds))
        guard snapshot.changeCount == current, reader.changeCount == current else {
            return
        }

        guard let classified = classifier.classify(
            snapshot,
            source: source,
            now: now(),
            capturedKinds: options.capturedKinds
        )
        else {
            observedChangeCount = current
            return
        }

        observedChangeCount = current
        onCapture(classified)
    }
}
