import AppKit
@testable import EasyKey
import SwiftUI
import XCTest

@MainActor
private final class FakeTranslationCancellation: TranslationCancelling {
    private(set) var callCount = 0

    func cancelActiveTranslation() {
        callCount += 1
    }
}

@MainActor
private final class FakeTranslationSpeechStopper: TranslationSpeechStopping {
    private(set) var callCount = 0

    func stopSpeaking() {
        callCount += 1
    }
}

@MainActor
private final class FakeTranslationPanel: TranslationPanelWindow {
    var isVisible = false
    let windowNumber = 42
    private(set) var replacementCount = 0
    private(set) var origins: [CGPoint] = []
    private(set) var frontCount = 0
    private(set) var orderOutCount = 0
    var onReplaceContent: (() -> Void)?
    private var closeHandler: (() -> Void)?

    func replaceContent(_: AnyView) {
        replacementCount += 1
        onReplaceContent?()
    }

    func setFrameOrigin(_ point: CGPoint) {
        origins.append(point)
    }

    func makeKeyAndOrderFront() {
        isVisible = true
        frontCount += 1
    }

    func orderOut() {
        isVisible = false
        orderOutCount += 1
    }

    func setCloseHandler(_ handler: @escaping () -> Void) {
        closeHandler = handler
    }

    func containsWindowNumber(_ windowNumber: Int) -> Bool {
        windowNumber == self.windowNumber
    }

    func addTitlebarAccessory(_: NSTitlebarAccessoryViewController) {}

    func requestClose() {
        closeHandler?()
    }
}

@MainActor
private final class FakeTranslationPanelEventMonitor: TranslationPanelEventMonitoring {
    private final class State {
        var activeIdentifiers: Set<UUID> = []
        var removeCount = 0
    }

    private var localHandler: ((TranslationPanelLocalEvent) -> Bool)?
    private var globalHandler: (() -> Void)?
    private let state = State()
    private(set) var localInstallCount = 0
    private(set) var globalInstallCount = 0
    private(set) var maximumActiveCount = 0

    var activeCount: Int {
        state.activeIdentifiers.count
    }

    var removeCount: Int {
        state.removeCount
    }

    func addLocalMonitor(
        isPanelOwnedWindow _: @escaping (Int) -> Bool,
        handler: @escaping (TranslationPanelLocalEvent) -> Bool
    ) -> TranslationPanelMonitorRegistration? {
        localInstallCount += 1
        localHandler = handler
        return addToken { [weak self] in self?.localHandler = nil }
    }

    func addGlobalClickMonitor(handler: @escaping () -> Void) -> TranslationPanelMonitorRegistration? {
        globalInstallCount += 1
        globalHandler = handler
        return addToken { [weak self] in self?.globalHandler = nil }
    }

    func sendLocal(_ event: TranslationPanelLocalEvent) -> Bool {
        localHandler?(event) ?? false
    }

    func sendGlobalClick() {
        globalHandler?()
    }

    private func addToken(onInvalidate: @escaping () -> Void) -> TranslationPanelMonitorRegistration {
        let identifier = UUID()
        let state = state
        state.activeIdentifiers.insert(identifier)
        maximumActiveCount = max(maximumActiveCount, state.activeIdentifiers.count)
        return TranslationPanelMonitorRegistration {
            if state.activeIdentifiers.remove(identifier) != nil {
                state.removeCount += 1
            }
            onInvalidate()
        }
    }
}

@MainActor
final class TranslationPanelPresenterTests: XCTestCase {
    private var cancellation: FakeTranslationCancellation!
    private var speech: FakeTranslationSpeechStopper!
    private var panel: FakeTranslationPanel!
    private var monitor: FakeTranslationPanelEventMonitor!
    private var presenter: TranslationPanelPresenter!
    private var userDefaults: UserDefaults!
    private var userDefaultsSuiteName: String!

    override func setUp() {
        cancellation = FakeTranslationCancellation()
        speech = FakeTranslationSpeechStopper()
        panel = FakeTranslationPanel()
        monitor = FakeTranslationPanelEventMonitor()
        userDefaultsSuiteName = "TranslationPanelPresenterTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)
        presenter = makePresenter()
    }

    override func tearDown() {
        presenter.close()
        presenter = nil
        monitor = nil
        panel = nil
        speech = nil
        cancellation = nil
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults = nil
    }

    func testShowCapturesPreviousApplicationBeforeContentAndActivation() {
        var events: [String] = []
        panel.onReplaceContent = { events.append("content") }
        presenter = makePresenter(
            frontmostApplication: {
                events.append("capture")
                return NSRunningApplication.current
            },
            activateEasyKey: { events.append("activate") }
        )

        presenter.show()

        XCTAssertEqual(events, ["capture", "content", "activate"])
        XCTAssertEqual(presenter.previousApplication?.processIdentifier, NSRunningApplication.current.processIdentifier)
        XCTAssertEqual(panel.frontCount, 1)
    }

    func testShowWithPreviouslyCapturedApplicationDoesNotRecaptureAfterTask12Activation() {
        presenter = makePresenter(frontmostApplication: {
            XCTFail("Previously captured application should be authoritative")
            return nil
        })

        presenter.show(previousApplication: NSRunningApplication.current)

        XCTAssertEqual(presenter.previousApplication?.processIdentifier, NSRunningApplication.current.processIdentifier)
    }

    func testShowPositionsPanelAndInstallsOneLocalAndOneGlobalMonitor() {
        presenter.show()

        XCTAssertTrue(presenter.isShown)
        XCTAssertEqual(panel.origins, [CGPoint(x: 108, y: 132)])
        XCTAssertEqual(monitor.localInstallCount, 1)
        XCTAssertEqual(monitor.globalInstallCount, 1)
        XCTAssertEqual(monitor.activeCount, 2)
    }

    func testRepeatedShowReusesPanelAndReplacesMonitorsWithoutDuplicates() {
        presenter.show()
        presenter.show()

        XCTAssertEqual(panel.replacementCount, 2)
        XCTAssertEqual(panel.frontCount, 2)
        XCTAssertEqual(monitor.localInstallCount, 2)
        XCTAssertEqual(monitor.globalInstallCount, 2)
        XCTAssertEqual(monitor.removeCount, 2)
        XCTAssertEqual(monitor.activeCount, 2)
        XCTAssertEqual(monitor.maximumActiveCount, 2)
    }

    func testPresenterDeallocationRemovesMonitorRegistrations() {
        var transientPresenter: TranslationPanelPresenter? = makePresenter()
        transientPresenter?.show()
        XCTAssertEqual(monitor.activeCount, 2)

        transientPresenter = nil

        XCTAssertEqual(monitor.activeCount, 0)
        XCTAssertEqual(monitor.removeCount, 2)
    }

    func testToggleShowsThenClosesAndCancelsWork() {
        presenter.toggle()
        presenter.toggle()

        XCTAssertFalse(presenter.isShown)
        XCTAssertEqual(cancellation.callCount, 1)
        XCTAssertEqual(speech.callCount, 1)
        XCTAssertEqual(monitor.activeCount, 0)
    }

    func testEscapeClosesAndConsumesEvent() {
        presenter.show()

        let consumed = monitor.sendLocal(.escape)

        XCTAssertTrue(consumed)
        XCTAssertFalse(presenter.isShown)
        XCTAssertEqual(cancellation.callCount, 1)
    }

    func testOrdinaryKeyRemainsAvailableForMultilineInput() {
        presenter.show()

        let consumed = monitor.sendLocal(.keyDown)

        XCTAssertFalse(consumed)
        XCTAssertTrue(presenter.isShown)
    }

    func testLocalMouseClicksNeverCloseSinceOutsideDismissalIsGlobalMonitorsJob() {
        presenter.show()
        XCTAssertFalse(monitor.sendLocal(.mouseDownInsidePanel))
        XCTAssertTrue(presenter.isShown)

        // A local "outside" click is an in-app popover/NSMenu (e.g. the language
        // pickers), not a dismissal gesture — it must leave the panel open.
        let consumed = monitor.sendLocal(.mouseDownOutsidePanel)

        XCTAssertFalse(consumed)
        XCTAssertTrue(presenter.isShown)
    }

    func testGlobalClickClosesPanel() {
        presenter.show()

        monitor.sendGlobalClick()

        XCTAssertFalse(presenter.isShown)
        XCTAssertEqual(monitor.activeCount, 0)
    }

    func testKeepOnTopSuppressesOutsideClickDismissal() {
        presenter.show()

        presenter.setKeepOnTop(true)

        let localConsumed = monitor.sendLocal(.mouseDownOutsidePanel)
        XCTAssertFalse(localConsumed)
        XCTAssertTrue(presenter.isShown)

        monitor.sendGlobalClick()
        XCTAssertTrue(presenter.isShown)
    }

    func testKeepOnTopStillClosesOnEscape() {
        presenter.show()
        presenter.setKeepOnTop(true)

        let consumed = monitor.sendLocal(.escape)

        XCTAssertTrue(consumed)
        XCTAssertFalse(presenter.isShown)
    }

    func testDisablingKeepOnTopRestoresOutsideClickDismissal() {
        presenter.show()
        presenter.setKeepOnTop(true)
        presenter.setKeepOnTop(false)

        monitor.sendGlobalClick()

        XCTAssertFalse(presenter.isShown)
    }

    func testKeepOnTopPersistsAndLoadsForNewPresenter() {
        presenter.setKeepOnTop(true)
        XCTAssertTrue(userDefaults.bool(forKey: "panel.translation.keepOnTop"))

        let reloaded = makePresenter()
        reloaded.show()
        monitor.sendGlobalClick()

        XCTAssertTrue(reloaded.isShown)
        reloaded.close()
    }

    func testNativeCloseRequestUsesFullCancellationLifecycle() {
        presenter.show()

        panel.requestClose()

        XCTAssertFalse(presenter.isShown)
        XCTAssertEqual(cancellation.callCount, 1)
        XCTAssertEqual(speech.callCount, 1)
        XCTAssertEqual(monitor.activeCount, 0)
    }

    func testCloseIsIdempotentForMonitorRemovalAndClearsPreviousApplication() {
        presenter.show()
        presenter.close()
        presenter.close()

        XCTAssertNil(presenter.previousApplication)
        XCTAssertEqual(monitor.removeCount, 2)
        XCTAssertEqual(monitor.activeCount, 0)
        XCTAssertEqual(cancellation.callCount, 2)
        XCTAssertEqual(speech.callCount, 2)
    }

    func testTranslationPanelSupportsFocusAndRequiredSpaceBehaviors() {
        let panel = TranslationPanel(size: TranslationPanelPresenter.panelSize)

        XCTAssertTrue(panel.canBecomeKey)
        XCTAssertTrue(panel.canBecomeMain)
        XCTAssertTrue(panel.isFloatingPanel)
        XCTAssertFalse(panel.hidesOnDeactivate)
        XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
        XCTAssertTrue(panel.collectionBehavior.contains(.fullScreenAuxiliary))
    }

    func testTranslationPanelTreatsChildPopoverWindowsAsInside() {
        let panel = TranslationPanel(size: TranslationPanelPresenter.panelSize)
        let child = NSPanel(
            contentRect: .init(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.addChildWindow(child, ordered: .above)
        defer { child.close() }

        XCTAssertTrue(panel.containsWindowNumber(panel.windowNumber))
        XCTAssertTrue(panel.containsWindowNumber(child.windowNumber))
    }

    private func makePresenter(
        frontmostApplication: @escaping () -> NSRunningApplication? = { nil },
        activateEasyKey: @escaping () -> Void = {}
    ) -> TranslationPanelPresenter {
        TranslationPanelPresenter(
            translation: cancellation,
            speech: speech,
            eventMonitor: monitor,
            panelFactory: { [panel] in panel! },
            frontmostApplication: frontmostApplication,
            activateEasyKey: activateEasyKey,
            pointerLocation: { CGPoint(x: 100, y: 700) },
            screenGeometries: {
                let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
                return [TranslationPanelScreenGeometry(frame: frame, visibleFrame: frame)]
            },
            userDefaults: userDefaults
        )
    }
}
