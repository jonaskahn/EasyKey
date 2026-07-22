import AppKit
import EasyEngineCore
@testable import EasyKey
import SwiftUI
import XCTest

@MainActor
final class ClipboardViewRenderingTests: XCTestCase {
    private var coordinator: AppCoordinator!
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        let made = TestCoordinatorFactory.make()
        coordinator = made.coordinator
        tempDirectory = made.tempDirectory
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        coordinator = nil
    }

    private func render(@ViewBuilder _ makeView: () -> some View) {
        let host = NSHostingView(rootView: AnyView(makeView()))
        host.frame = NSRect(x: 0, y: 0, width: 900, height: 620)
        host.layoutSubtreeIfNeeded()
        XCTAssertNotNil(host)
    }

    func testClipboardPanelView_Renders() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true))
        let action = makeAction()
        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let localization = LocalizationStore.shared
        let actions = ClipboardPanelActions(
            primary: { _ in },
            copy: { _ in },
            togglePin: { _ in },
            delete: { _ in },
            reveal: { _ in },
            clearUnpinned: {},
            openSettings: {}
        )
        render {
            ClipboardPanelView(
                model: model,
                action: action,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                actions: actions
            )
        }
    }

    func testClipboardPanelView_WithEntry_Renders() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true))
        let action = makeAction()
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: "test"),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: "test")]
        )
        let entry = ClipboardEntry(fingerprint: "fp", capturedAt: Date(), items: [item])
        model.capture(ClassifiedClipboard(entry: entry, payloads: [:]))

        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let localization = LocalizationStore.shared
        let actions = ClipboardPanelActions(
            primary: { _ in },
            copy: { _ in },
            togglePin: { _ in },
            delete: { _ in },
            reveal: { _ in },
            clearUnpinned: {},
            openSettings: {}
        )
        render {
            ClipboardPanelView(
                model: model,
                action: action,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                actions: actions
            )
        }
    }

    func testClipboardEntryRow_Renders() {
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: "test"),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: "test")]
        )
        let entry = ClipboardEntry(fingerprint: "fp", capturedAt: Date(), items: [item])
        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let localization = LocalizationStore.shared
        render {
            ClipboardEntryRow(
                entry: entry,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                togglePin: {}
            )
        }
    }

    func testClipboardEntryRow_Pinned_Renders() {
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: "pinned item"),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: "test")]
        )
        var entry = ClipboardEntry(fingerprint: "fp", capturedAt: Date(), items: [item])
        entry.isPinned = true
        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let localization = LocalizationStore.shared
        render {
            ClipboardEntryRow(
                entry: entry,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                togglePin: {}
            )
        }
    }

    func testClipboardEntryRow_Unavailable_Renders() {
        let item = ClipboardItem(
            kind: .file,
            preview: ClipboardItemPreview(primaryText: "missing.txt"),
            representations: [.fileURL(URL(fileURLWithPath: "/nonexistent/file.txt"))]
        )
        let entry = ClipboardEntry(fingerprint: "fp", capturedAt: Date(), items: [item])
        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let localization = LocalizationStore.shared
        render {
            ClipboardEntryRow(
                entry: entry,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                togglePin: {}
            )
        }
    }

    func testClipboardPanelView_WithPinned_Renders() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true))
        let action = makeAction()
        let item1 = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: "pinned"),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: "pinned")]
        )
        var entry1 = ClipboardEntry(fingerprint: "fp1", capturedAt: Date(), items: [item1])
        entry1.isPinned = true
        model.capture(ClassifiedClipboard(entry: entry1, payloads: [:]))

        let item2 = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: "recent"),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: "recent")]
        )
        let entry2 = ClipboardEntry(fingerprint: "fp2", capturedAt: Date(), items: [item2])
        model.capture(ClassifiedClipboard(entry: entry2, payloads: [:]))

        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let localization = LocalizationStore.shared
        let actions = ClipboardPanelActions(
            primary: { _ in },
            copy: { _ in },
            togglePin: { _ in },
            delete: { _ in },
            reveal: { _ in },
            clearUnpinned: {},
            openSettings: {}
        )
        render {
            ClipboardPanelView(
                model: model,
                action: action,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                actions: actions
            )
        }
    }

    func testClipboardPanelView_Empty_Renders() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true))
        let action = makeAction()
        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let localization = LocalizationStore.shared
        let actions = ClipboardPanelActions(
            primary: { _ in },
            copy: { _ in },
            togglePin: { _ in },
            delete: { _ in },
            reveal: { _ in },
            clearUnpinned: {},
            openSettings: {}
        )
        render {
            ClipboardPanelView(
                model: model,
                action: action,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                actions: actions
            )
        }
    }

    private func makeAction() -> ClipboardActionCoordinator {
        ClipboardActionCoordinator(
            writeEntry: { _ in },
            closePanel: {},
            reactivatePrevious: { true },
            synthesizePaste: { true }
        )
    }
}
