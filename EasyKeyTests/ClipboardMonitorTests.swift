import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class ClipboardMonitorTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testDisabledCaptureDoesNotCapture() {
        let reader = FakePasteboardReader()
        reader.setText("hello", changeCount: 2)
        var captured = 0
        let monitor = makeMonitor(reader: reader, enabled: false) { _ in captured += 1 }
        monitor.poll()
        XCTAssertEqual(captured, 0)
    }

    func testSingleChangeIsCaptured() {
        let reader = FakePasteboardReader()
        var captured: ClassifiedClipboard?
        let monitor = makeMonitor(reader: reader, enabled: true) { captured = $0 }
        reader.setText("hello", changeCount: 5)
        monitor.poll()
        XCTAssertEqual(captured?.entry.kind, .text)
    }

    func testUnchangedCountDoesNotRecapture() {
        let reader = FakePasteboardReader()
        var captured = 0
        let monitor = makeMonitor(reader: reader, enabled: true) { _ in captured += 1 }
        reader.setText("hello", changeCount: 5)
        monitor.poll()
        monitor.poll()
        XCTAssertEqual(captured, 1)
    }

    func testSensitiveMarkerRejectsEventWithoutReadingPayload() {
        let reader = FakePasteboardReader()
        var captured = 0
        let monitor = makeMonitor(reader: reader, enabled: true) { _ in captured += 1 }
        reader.setDescriptorOnly(
            types: ["org.nspasteboard.ConcealedType", PasteboardClassifier.plainText],
            changeCount: 7
        )
        monitor.poll()
        XCTAssertEqual(captured, 0)
        XCTAssertEqual(reader.snapshotCallCount, 0)
    }

    func testOwnWriteIsSuppressed() {
        let reader = FakePasteboardReader()
        let suppressor = ClipboardWriteSuppressor()
        var captured = 0
        let monitor = ClipboardMonitor(
            reader: reader,
            suppressor: suppressor,
            options: ClipboardOptions(isCaptureEnabled: true),
            now: { self.now },
            sourceProvider: { nil },
            onCapture: { _ in captured += 1 }
        )
        reader.setText("hello", changeCount: 9)
        suppressor.markWritten(changeCount: 9)
        monitor.poll()
        XCTAssertEqual(captured, 0)
    }

    func testIgnoredApplicationIsSkipped() {
        let reader = FakePasteboardReader()
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.ignoredApplicationBundleIdentifiers = ["com.secret.app"]
        var captured = 0
        let monitor = ClipboardMonitor(
            reader: reader,
            suppressor: ClipboardWriteSuppressor(),
            options: options,
            now: { self.now },
            sourceProvider: { ClipboardSource(applicationName: "Secret", bundleIdentifier: "com.secret.app") },
            onCapture: { _ in captured += 1 }
        )
        reader.setText("hello", changeCount: 3)
        monitor.poll()
        XCTAssertEqual(captured, 0)
    }

    func testMidReadChangeCountMutationDiscardsCandidate() {
        let reader = FakePasteboardReader()
        var captured = 0
        let monitor = makeMonitor(reader: reader, enabled: true) { _ in captured += 1 }
        reader.setText("hello", changeCount: 4)
        reader.changeCountAfterSnapshot = 6
        monitor.poll()
        XCTAssertEqual(captured, 0)
    }

    // MARK: - Helpers

    private func makeMonitor(
        reader: PasteboardReading,
        enabled: Bool,
        onCapture: @escaping (ClassifiedClipboard) -> Void
    ) -> ClipboardMonitor {
        ClipboardMonitor(
            reader: reader,
            suppressor: ClipboardWriteSuppressor(),
            options: ClipboardOptions(isCaptureEnabled: enabled),
            now: { self.now },
            sourceProvider: { nil },
            onCapture: onCapture
        )
    }
}

final class FakePasteboardReader: PasteboardReading {
    var changeCount = 0
    var changeCountAfterSnapshot: Int?
    private(set) var snapshotCallCount = 0
    private var descriptorItems: [PasteboardItemDescriptor] = []
    private var snapshotItems: [PasteboardItemSnapshot] = []

    func setText(_ text: String, changeCount: Int) {
        self.changeCount = changeCount
        descriptorItems = [PasteboardItemDescriptor(typeIdentifiers: [PasteboardClassifier.plainText])]
        let representation = CapturedPasteboardRepresentation(typeIdentifier: PasteboardClassifier.plainText, data: Data(text.utf8))
        snapshotItems = [PasteboardItemSnapshot(representations: [representation])]
    }

    func setDescriptorOnly(types: [String], changeCount: Int) {
        self.changeCount = changeCount
        descriptorItems = [PasteboardItemDescriptor(typeIdentifiers: types)]
        snapshotItems = []
    }

    func descriptor() -> PasteboardDescriptor {
        PasteboardDescriptor(changeCount: changeCount, items: descriptorItems)
    }

    func snapshot(selecting _: [[String]]) -> PasteboardSnapshot {
        snapshotCallCount += 1
        let reportedCount = changeCountAfterSnapshot ?? changeCount
        if let after = changeCountAfterSnapshot {
            changeCount = after
        }
        return PasteboardSnapshot(changeCount: reportedCount, items: snapshotItems)
    }
}
