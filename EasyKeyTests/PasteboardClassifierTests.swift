import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class PasteboardClassifierTests: XCTestCase {
    private let classifier = PasteboardClassifier()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testClassifiesPlainText() {
        let snapshot = snapshot([[rep(PasteboardClassifier.plainText, "Hello")]])
        let result = classifier.classify(snapshot, source: nil, now: now)
        XCTAssertEqual(result?.entry.kind, .text)
        XCTAssertEqual(result?.entry.items.first?.representations.count, 1)
    }

    func testClassifiesTextWithHTMLAndRTFAndStoresRTFPayload() {
        let reps = [
            rep(PasteboardClassifier.plainText, "Hi"),
            rep(PasteboardClassifier.html, "<b>Hi</b>"),
            rep(PasteboardClassifier.rtf, "{\\rtf1 Hi}"),
        ]
        let snapshot = snapshot([reps])
        let result = classifier.classify(snapshot, source: nil, now: now)
        XCTAssertEqual(result?.entry.items.first?.kind, .text)
        XCTAssertEqual(result?.entry.items.first?.representations.count, 3)
        XCTAssertEqual(result?.payloads.count, 1)
    }

    func testClassifiesWebURL() {
        let snapshot = snapshot([[rep(PasteboardClassifier.webURL, "https://example.com/x")]])
        let result = classifier.classify(snapshot, source: nil, now: now)
        XCTAssertEqual(result?.entry.kind, .url)
    }

    func testClassifiesFileURLAndDetectsVideoExtension() {
        let file = snapshot([[rep(PasteboardClassifier.fileURL, "file:///Users/me/report.pdf")]])
        XCTAssertEqual(classifier.classify(file, source: nil, now: now)?.entry.kind, .file)

        let video = snapshot([[rep(PasteboardClassifier.fileURL, "file:///Users/me/clip.mp4")]])
        XCTAssertEqual(classifier.classify(video, source: nil, now: now)?.entry.kind, .video)
    }

    func testPrefersPNGOverTIFF() {
        let reps = [data(PasteboardClassifier.tiff, bytes: 10), data(PasteboardClassifier.png, bytes: 10)]
        let snapshot = snapshot([reps])
        let result = classifier.classify(snapshot, source: nil, now: now)
        XCTAssertEqual(result?.entry.kind, .image)
        if case let .data(typeIdentifier, _)? = result?.entry.items.first?.representations.first {
            XCTAssertEqual(typeIdentifier, PasteboardClassifier.png)
        } else {
            XCTFail("Expected image data representation")
        }
    }

    func testMultipleItemsWithDifferentKindsBecomeMixed() {
        let snapshot = snapshot([
            [rep(PasteboardClassifier.plainText, "text")],
            [rep(PasteboardClassifier.webURL, "https://a.b")],
        ])
        XCTAssertEqual(classifier.classify(snapshot, source: nil, now: now)?.entry.kind, .mixed)
    }

    func testFingerprintChangesWhenItemOrderChanges() {
        let forward = snapshot([[rep(PasteboardClassifier.plainText, "a")], [rep(PasteboardClassifier.plainText, "b")]])
        let reversed = snapshot([[rep(PasteboardClassifier.plainText, "b")], [rep(PasteboardClassifier.plainText, "a")]])
        XCTAssertNotEqual(
            classifier.classify(forward, source: nil, now: now)?.entry.fingerprint,
            classifier.classify(reversed, source: nil, now: now)?.entry.fingerprint
        )
    }

    func testEquivalentWithinItemOrderingProducesSameFingerprint() {
        let forwardReps = [rep(PasteboardClassifier.plainText, "x"), rep(PasteboardClassifier.html, "<i>x</i>")]
        let reversedReps = [rep(PasteboardClassifier.html, "<i>x</i>"), rep(PasteboardClassifier.plainText, "x")]
        XCTAssertEqual(
            classifier.classify(snapshot([forwardReps]), source: nil, now: now)?.entry.fingerprint,
            classifier.classify(snapshot([reversedReps]), source: nil, now: now)?.entry.fingerprint
        )
    }

    func testOversizedEventIsRejected() {
        let snapshot = snapshot([[data(PasteboardClassifier.png, bytes: ClipboardLimits.maximumEventBytes + 1)]])
        XCTAssertNil(classifier.classify(snapshot, source: nil, now: now))
    }

    func testUnsupportedOnlyContentReturnsNil() {
        let snapshot = snapshot([[rep("com.example.custom", "secret")]])
        XCTAssertNil(classifier.classify(snapshot, source: nil, now: now))
    }

    private func snapshot(_ items: [[CapturedPasteboardRepresentation]]) -> PasteboardSnapshot {
        PasteboardSnapshot(changeCount: 1, items: items.map { PasteboardItemSnapshot(representations: $0) })
    }

    private func rep(_ type: String, _ value: String) -> CapturedPasteboardRepresentation {
        CapturedPasteboardRepresentation(typeIdentifier: type, data: Data(value.utf8))
    }

    private func data(_ type: String, bytes: Int) -> CapturedPasteboardRepresentation {
        CapturedPasteboardRepresentation(typeIdentifier: type, data: Data(repeating: 0xAB, count: bytes))
    }
}
