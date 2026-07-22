import ApplicationServices
@testable import EasyKey
import XCTest

final class AccessibilitySelectedTextReaderTests: XCTestCase {
    func testReadSelectedText_ReturnsSelection() {
        let access = FakeAccessibilitySelectedTextAccess(selectedText: .value("selected text"))

        XCTAssertEqual(AccessibilitySelectedTextReader(access: access).readSelectedText(), .text("selected text"))
        XCTAssertEqual(access.attributesRead, ["AXRole", "AXSubrole", "AXSelectedText"])
    }

    func testReadSelectedText_ReturnsAbsentForNoValueAndBlankSelection() {
        let noValue = FakeAccessibilitySelectedTextAccess(selectedText: .noValue)
        let blank = FakeAccessibilitySelectedTextAccess(selectedText: .value(" \n "))

        XCTAssertEqual(AccessibilitySelectedTextReader(access: noValue).readSelectedText(), .absent)
        XCTAssertEqual(AccessibilitySelectedTextReader(access: blank).readSelectedText(), .absent)
    }

    func testReadSelectedText_ReturnsPermissionDeniedWithoutQueryingElement() {
        let access = FakeAccessibilitySelectedTextAccess(isProcessTrusted: false)

        XCTAssertEqual(AccessibilitySelectedTextReader(access: access).readSelectedText(), .permissionDenied)
        XCTAssertEqual(access.focusedElementCallCount, 0)
        XCTAssertTrue(access.attributesRead.isEmpty)
    }

    func testReadSelectedText_ReturnsSecureFieldWithoutReadingSelection() {
        let access = FakeAccessibilitySelectedTextAccess(
            subrole: .value(kAXSecureTextFieldSubrole as String),
            selectedText: .value("must never be read")
        )

        XCTAssertEqual(AccessibilitySelectedTextReader(access: access).readSelectedText(), .secureField)
        XCTAssertEqual(access.attributesRead, ["AXRole", "AXSubrole"])
    }

    func testReadSelectedText_ReturnsUnsupportedRoleWithoutReadingSelection() {
        let access = FakeAccessibilitySelectedTextAccess(role: .value(kAXButtonRole as String))

        XCTAssertEqual(AccessibilitySelectedTextReader(access: access).readSelectedText(), .unsupportedRole)
        XCTAssertEqual(access.attributesRead, ["AXRole"])
    }

    func testReadSelectedText_ReturnsInaccessibleForMissingElementAndAttributeFailures() {
        let missing = FakeAccessibilitySelectedTextAccess(hasFocusedElement: false)
        let unsupported = FakeAccessibilitySelectedTextAccess(selectedText: .unsupported)
        let failedSubrole = FakeAccessibilitySelectedTextAccess(subrole: .failed)

        XCTAssertEqual(AccessibilitySelectedTextReader(access: missing).readSelectedText(), .inaccessible)
        XCTAssertEqual(AccessibilitySelectedTextReader(access: unsupported).readSelectedText(), .inaccessible)
        XCTAssertEqual(AccessibilitySelectedTextReader(access: failedSubrole).readSelectedText(), .inaccessible)
    }

    func testReadSelectedText_RejectsOversizedSelectionAtConfiguredLimit() {
        let accepted = FakeAccessibilitySelectedTextAccess(selectedText: .value("12345"))
        let oversized = FakeAccessibilitySelectedTextAccess(selectedText: .value("123456"))

        XCTAssertEqual(AccessibilitySelectedTextReader(access: accepted, maximumLength: 5).readSelectedText(), .text("12345"))
        XCTAssertEqual(AccessibilitySelectedTextReader(access: oversized, maximumLength: 5).readSelectedText(), .oversized)
    }
}

@MainActor
final class SelectedTextCaptureCoordinatorTests: XCTestCase {
    func testCapture_UsesAccessibilityTextWithoutReadingPasteboard() {
        let pasteboard = FakeSelectedTextPasteboard(changeCount: 4, items: [.plainText("clipboard")])
        let coordinator = makeCoordinator(selection: .text("selection"), pasteboard: pasteboard)

        let result = coordinator.capture()

        XCTAssertEqual(result, SelectedTextCaptureResult(
            text: "selection",
            source: .accessibility,
            accessibilityResult: .text("selection")
        ))
        XCTAssertEqual(pasteboard.descriptorCallCount, 0)
        XCTAssertPasteboardUnchanged(pasteboard)
    }

    func testCapture_NeverUsesExistingPasteboardAsFallback() {
        let pasteboard = FakeSelectedTextPasteboard(changeCount: 9, items: [.plainText("stale")])

        let result = makeCoordinator(selection: .absent, pasteboard: pasteboard).capture()

        XCTAssertEqual(result.source, .blank)
        XCTAssertEqual(pasteboard.descriptorCallCount, 0)
        XCTAssertEqual(pasteboard.snapshotCallCount, 0)
        XCTAssertPasteboardUnchanged(pasteboard)
    }

    func testCapture_SecureAndOversizedSelectionsStopWithoutSimulatedCopy() {
        for reason in [SelectedTextReadResult.secureField, .oversized] {
            let pasteboard = FakeSelectedTextPasteboard(changeCount: 9, items: [.plainText("stale")])
            let simulator = FakeSelectedTextSimulator(text: "copied")

            let result = makeCoordinator(selection: reason, pasteboard: pasteboard, simulatedCopy: simulator).capture()

            XCTAssertEqual(result.source, .blank)
            XCTAssertEqual(simulator.copyCallCount, 0)
            XCTAssertPasteboardUnchanged(pasteboard)
        }
    }

    func testCapture_MissingSelectionIsOrdinaryAbsence() {
        let pasteboard = FakeSelectedTextPasteboard(changeCount: 1, items: [])

        let result = makeCoordinator(selection: .absent, pasteboard: pasteboard).capture()

        XCTAssertEqual(result.accessibilityResult, .absent)
        XCTAssertEqual(result.source, .blank)
    }

    func testCapture_BlankFallbackForNonPlainTextInvalidUTF8BlankAndOversizedData() {
        let cases: [[FakeSelectedTextPasteboard.Item]] = [
            [.data(type: PasteboardClassifier.html, data: Data("<b>rich</b>".utf8))],
            [.data(type: PasteboardClassifier.plainText, data: Data([0xFF]))],
            [.plainText(" \n")],
            [.plainText("123456")],
        ]

        for items in cases {
            let pasteboard = FakeSelectedTextPasteboard(changeCount: 3, items: items)
            let result = makeCoordinator(selection: .absent, pasteboard: pasteboard, maximumLength: 5).capture()

            XCTAssertEqual(result.text, "")
            XCTAssertEqual(result.source, .blank)
            XCTAssertPasteboardUnchanged(pasteboard)
        }
    }

    func testCapture_RequestsOnlyPlainTextWhenOtherRepresentationsExist() {
        let pasteboard = FakeSelectedTextPasteboard(
            changeCount: 2,
            items: [
                .data(type: PasteboardClassifier.html, data: Data("secret rich value".utf8)),
                .plainText("plain"),
            ]
        )

        let result = makeCoordinator(selection: .absent, pasteboard: pasteboard).capture()

        XCTAssertEqual(result.text, "")
        XCTAssertEqual(result.source, .blank)
        XCTAssertTrue(pasteboard.requestedTypes.isEmpty)
        XCTAssertPasteboardUnchanged(pasteboard)
    }

    func testCapture_RejectsSensitiveMarkersWithoutReadingPayload() {
        let pasteboard = FakeSelectedTextPasteboard(
            changeCount: 8,
            items: [
                .data(type: "org.nspasteboard.ConcealedType", data: Data()),
                .plainText("password"),
            ]
        )

        let result = makeCoordinator(selection: .secureField, pasteboard: pasteboard).capture()

        XCTAssertEqual(result.source, .blank)
        XCTAssertEqual(pasteboard.snapshotCallCount, 0)
        XCTAssertPasteboardUnchanged(pasteboard)
    }

    func testCapture_RejectsPasteboardChangingDuringRead() {
        let pasteboard = FakeSelectedTextPasteboard(changeCount: 5, items: [.plainText("racing")])
        pasteboard.changeCountAfterSnapshot = 6

        let result = makeCoordinator(selection: .absent, pasteboard: pasteboard).capture()

        XCTAssertEqual(result.source, .blank)
        XCTAssertEqual(pasteboard.contents, pasteboard.originalContents)
        XCTAssertEqual(pasteboard.changeCount, pasteboard.originalChangeCount)
    }

    func testCapture_CapturesFrontmostAndTextBeforeActivation() {
        var events: [String] = []
        let reader = ClosureSelectedTextReader {
            events.append("accessibility")
            return .text("before activation")
        }
        let pasteboard = FakeSelectedTextPasteboard(changeCount: 1, items: [])
        let coordinator = SelectedTextCaptureCoordinator(
            selectedTextReader: reader,
            frontmostApplication: {
                events.append("frontmost")
                return nil
            },
            activateEasyKey: { events.append("activate") }
        )

        XCTAssertEqual(coordinator.capture().text, "before activation")
        XCTAssertEqual(events, ["frontmost", "accessibility", "activate"])
    }

    func testCapture_FallsBackToSimulatedCopyWhenAccessibilityFails() {
        let pasteboard = FakeSelectedTextPasteboard(changeCount: 1, items: [])
        let simulator = FakeSelectedTextSimulator(text: "simulated")
        let coordinator = makeCoordinator(selection: .absent, pasteboard: pasteboard, simulatedCopy: simulator)

        let result = coordinator.capture()

        XCTAssertEqual(result.text, "simulated")
        XCTAssertEqual(result.source, .simulatedCopy)
        XCTAssertEqual(simulator.copyCallCount, 1)
        XCTAssertPasteboardUnchanged(pasteboard)
    }

    func testCapture_SimulatedCopyNotCalledWhenAccessibilitySucceeds() {
        let pasteboard = FakeSelectedTextPasteboard(changeCount: 1, items: [])
        let simulator = FakeSelectedTextSimulator(text: "should-not-be-used")
        let coordinator = makeCoordinator(selection: .text("accessibility"), pasteboard: pasteboard, simulatedCopy: simulator)

        let result = coordinator.capture()

        XCTAssertEqual(result.text, "accessibility")
        XCTAssertEqual(result.source, .accessibility)
        XCTAssertEqual(simulator.copyCallCount, 0)
    }

    func testCapture_SimulatedCopyNotCalledWhenSimulatorIsNil() {
        let pasteboard = FakeSelectedTextPasteboard(changeCount: 1, items: [])
        let coordinator = makeCoordinator(selection: .absent, pasteboard: pasteboard, simulatedCopy: nil)

        let result = coordinator.capture()

        XCTAssertEqual(result.source, .blank)
    }

    func testCapture_SimulatedCopyResultRespectsMaxLength() {
        let pasteboard = FakeSelectedTextPasteboard(changeCount: 1, items: [])
        let simulator = FakeSelectedTextSimulator(text: "123456")
        let coordinator = makeCoordinator(selection: .absent, pasteboard: pasteboard, simulatedCopy: simulator, maximumLength: 5)

        let result = coordinator.capture()

        XCTAssertEqual(result.text, "")
        XCTAssertEqual(result.source, .blank)
    }

    func testCapture_SimulatedCopySkipsBlankText() {
        let pasteboard = FakeSelectedTextPasteboard(changeCount: 1, items: [.plainText("pasteboard")])
        let simulator = FakeSelectedTextSimulator(text: " ")
        let coordinator = makeCoordinator(selection: .absent, pasteboard: pasteboard, simulatedCopy: simulator)

        let result = coordinator.capture()

        XCTAssertEqual(result.text, "")
        XCTAssertEqual(result.source, .blank)
    }

    private func makeCoordinator(
        selection: SelectedTextReadResult,
        pasteboard _: FakeSelectedTextPasteboard,
        maximumLength: Int = 5000
    ) -> SelectedTextCaptureCoordinator {
        SelectedTextCaptureCoordinator(
            selectedTextReader: ClosureSelectedTextReader { selection },
            simulatedCopy: nil,
            frontmostApplication: { nil },
            activateEasyKey: {},
            maximumLength: maximumLength
        )
    }

    private func makeCoordinator(
        selection: SelectedTextReadResult,
        pasteboard _: FakeSelectedTextPasteboard,
        simulatedCopy: SelectedTextSimulating?,
        maximumLength: Int = 5000
    ) -> SelectedTextCaptureCoordinator {
        SelectedTextCaptureCoordinator(
            selectedTextReader: ClosureSelectedTextReader { selection },
            simulatedCopy: simulatedCopy,
            frontmostApplication: { nil },
            activateEasyKey: {},
            maximumLength: maximumLength
        )
    }

    private func XCTAssertPasteboardUnchanged(
        _ pasteboard: FakeSelectedTextPasteboard,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(pasteboard.changeCount, pasteboard.originalChangeCount, file: file, line: line)
        XCTAssertEqual(pasteboard.contents, pasteboard.originalContents, file: file, line: line)
    }
}

private final class FakeAccessibilitySelectedTextAccess: AccessibilitySelectedTextAccessing {
    let isProcessTrusted: Bool
    private let hasFocusedElement: Bool
    private let role: AccessibilityStringRead
    private let subrole: AccessibilityStringRead
    private let selectedText: AccessibilityStringRead

    private(set) var focusedElementCallCount = 0
    private(set) var attributesRead: [String] = []

    init(
        isProcessTrusted: Bool = true,
        hasFocusedElement: Bool = true,
        role: AccessibilityStringRead = .value(kAXTextAreaRole as String),
        subrole: AccessibilityStringRead = .noValue,
        selectedText: AccessibilityStringRead = .noValue
    ) {
        self.isProcessTrusted = isProcessTrusted
        self.hasFocusedElement = hasFocusedElement
        self.role = role
        self.subrole = subrole
        self.selectedText = selectedText
    }

    func focusedElement() -> AccessibilityElementReference? {
        focusedElementCallCount += 1
        return hasFocusedElement ? AccessibilityElementReference(NSObject()) : nil
    }

    func stringAttribute(_ attribute: String, of _: AccessibilityElementReference) -> AccessibilityStringRead {
        attributesRead.append(attribute)
        switch attribute {
        case "AXRole":
            return role
        case "AXSubrole":
            return subrole
        case "AXSelectedText":
            return selectedText
        default:
            return .unsupported
        }
    }
}

private struct ClosureSelectedTextReader: SelectedTextReading {
    let read: () -> SelectedTextReadResult

    func readSelectedText() -> SelectedTextReadResult {
        read()
    }
}

private final class FakeSelectedTextPasteboard: PasteboardReading {
    struct Item: Equatable {
        let type: String
        let data: Data

        static func plainText(_ text: String) -> Item {
            Item(type: PasteboardClassifier.plainText, data: Data(text.utf8))
        }

        static func data(type: String, data: Data) -> Item {
            Item(type: type, data: data)
        }
    }

    var changeCount: Int
    var changeCountAfterSnapshot: Int?
    let originalChangeCount: Int
    let originalContents: [Item]
    private(set) var contents: [Item]
    private(set) var descriptorCallCount = 0
    private(set) var snapshotCallCount = 0
    private(set) var requestedTypes: [[String]] = []

    init(changeCount: Int, items: [Item]) {
        self.changeCount = changeCount
        originalChangeCount = changeCount
        originalContents = items
        contents = items
    }

    func descriptor() -> PasteboardDescriptor {
        descriptorCallCount += 1
        return PasteboardDescriptor(
            changeCount: changeCount,
            items: contents.map { PasteboardItemDescriptor(typeIdentifiers: [$0.type]) }
        )
    }

    func snapshot(selecting typeIdentifiers: [[String]]) -> PasteboardSnapshot {
        snapshotCallCount += 1
        requestedTypes = typeIdentifiers
        let reportedCount = changeCount
        let items = contents.enumerated().map { index, item in
            let requested = index < typeIdentifiers.count ? typeIdentifiers[index] : []
            let representations = requested.contains(item.type)
                ? [CapturedPasteboardRepresentation(typeIdentifier: item.type, data: item.data)]
                : []
            return PasteboardItemSnapshot(representations: representations)
        }
        if let changeCountAfterSnapshot {
            changeCount = changeCountAfterSnapshot
        }
        return PasteboardSnapshot(changeCount: reportedCount, items: items)
    }
}

private final class FakeSelectedTextSimulator: SelectedTextSimulating {
    let text: String?
    private(set) var copyCallCount = 0

    init(text: String?) {
        self.text = text
    }

    func copySelection(from _: NSRunningApplication?) -> String? {
        copyCallCount += 1
        return text
    }
}
