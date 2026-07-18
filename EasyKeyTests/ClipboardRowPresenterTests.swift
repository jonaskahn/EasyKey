import EasyEngineCore
@testable import EasyKey
import XCTest

final class ClipboardRowPresenterTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testSymbolNamePerKind() {
        XCTAssertEqual(ClipboardRowPresenter.symbolName(for: .text), "text.alignleft")
        XCTAssertEqual(ClipboardRowPresenter.symbolName(for: .url), "link")
        XCTAssertEqual(ClipboardRowPresenter.symbolName(for: .image), "photo")
        XCTAssertEqual(ClipboardRowPresenter.symbolName(for: .file), "doc")
        XCTAssertEqual(ClipboardRowPresenter.symbolName(for: .video), "film")
        XCTAssertEqual(ClipboardRowPresenter.symbolName(for: .mixed), "square.on.square")
    }

    func testNormalizedTextPreviewCollapsesToTwoMeaningfulLines() {
        let text = "  line one  \n\n   \n line two \n line three "
        XCTAssertEqual(ClipboardRowPresenter.normalizedTextPreview(text), "line one\nline two")
    }

    func testFormattedBytesUsesFileStyle() {
        XCTAssertFalse(ClipboardRowPresenter.formattedBytes(2048).isEmpty)
    }

    func testPrimaryTextAppendsItemCountForMixed() {
        let entry = ClipboardEntry(
            fingerprint: "f",
            capturedAt: now,
            items: [
                ClipboardItem(
                    kind: .url,
                    preview: ClipboardItemPreview(primaryText: "https://a.b"),
                    representations: [.string(typeIdentifier: "public.url", value: "https://a.b")]
                ),
                ClipboardItem(
                    kind: .text,
                    preview: ClipboardItemPreview(primaryText: "x"),
                    representations: [.string(typeIdentifier: "public.utf8-plain-text", value: "x")]
                ),
            ]
        )
        XCTAssertEqual(ClipboardRowPresenter.primaryText(for: entry), "https://a.b +1")
    }

    func testIsUnavailableDetectsMissingFile() {
        let item = ClipboardItem(
            kind: .file,
            preview: ClipboardItemPreview(primaryText: "x"),
            representations: [.fileURL(URL(fileURLWithPath: "/nope/\(UUID()).bin"))]
        )
        let entry = ClipboardEntry(fingerprint: "f", capturedAt: now, items: [item])
        XCTAssertTrue(ClipboardRowPresenter.isUnavailable(entry))
    }

    func testMetadataIncludesSourceAndType() {
        let item = ClipboardItem(
            kind: .image,
            preview: ClipboardItemPreview(primaryText: "PNG", typeLabel: "PNG", byteCount: 2048),
            representations: [.data(typeIdentifier: "public.png", payloadReference: "r")]
        )
        let entry = ClipboardEntry(
            fingerprint: "f",
            capturedAt: now,
            source: ClipboardSource(applicationName: "Safari"),
            items: [item]
        )
        let metadata = ClipboardRowPresenter.metadata(for: entry, now: now.addingTimeInterval(60))
        XCTAssertTrue(metadata.contains("PNG"))
        XCTAssertTrue(metadata.contains("Safari"))
    }
}
