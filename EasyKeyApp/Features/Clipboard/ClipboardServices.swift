import AppKit
import Combine
import EasyEngineCore
import SwiftUI

/// Composition container for the clipboard feature. Builds and wires the history
/// model, monitor, panel, hotkey, and action coordinator so `AppCoordinator`
/// stays a thin composition root. Owns no business rules of its own.
@MainActor
final class ClipboardServices: ObservableObject {
    let model: ClipboardHistoryModel
    let monitor: ClipboardMonitor
    let presenter: ClipboardPanelPresenter
    let hotKey: ClipboardHotKeyController
    let action: ClipboardActionCoordinator
    let writer: PasteboardWriter
    let thumbnailLoader: ClipboardThumbnailLoader

    @Published var hotkeyConflict = false

    private let frontmostProvider: () -> NSRunningApplication?
    private var options: ClipboardOptions
    private let localization: LocalizationStore

    /// Set by the coordinator so the panel footer can open settings.
    var openSettings: () -> Void = {}
    /// Invoked right before the shortcut opens or closes the clipboard panel.
    /// The coordinator uses this to dismiss the menu-bar popover first, since
    /// the two surfaces are never meant to be visible at the same time.
    var onWillActivate: (() -> Void)?

    init(
        options: ClipboardOptions,
        applicationSupportDirectory: URL,
        localization: LocalizationStore = .shared,
        keyProvider: ClipboardKeyProviding = KeychainClipboardKeyStore(),
        reader: PasteboardReading? = nil,
        hotKeyRegistrar: ClipboardHotKeyRegistrar? = nil,
        frontmostProvider: @escaping () -> NSRunningApplication? = { NSWorkspace.shared.frontmostApplication }
    ) {
        self.options = options
        self.localization = localization
        self.frontmostProvider = frontmostProvider

        let payloadStore = ClipboardPayloadStore()
        let suppressor = ClipboardWriteSuppressor()
        let persistence = ClipboardPersistence(
            directory: applicationSupportDirectory.appendingPathComponent("Clipboard", isDirectory: true),
            keyProvider: keyProvider
        )
        let model = ClipboardHistoryModel(options: options, payloadStore: payloadStore, persistence: persistence)
        let writer = PasteboardWriter(suppressor: suppressor, payloadStore: payloadStore)
        let thumbnailLoader = ClipboardThumbnailLoader { [weak model] reference in
            model?.payloadData(for: reference)
        }
        model.onPayloadsRemoved = { [weak thumbnailLoader] references in
            thumbnailLoader?.remove(references: references)
        }
        let presenter = ClipboardPanelPresenter()
        let action = ClipboardActionCoordinator(
            writeEntry: { [weak writer] entry in
                guard let writer else { throw PasteboardWriteError.unavailableRepresentation }
                try writer.copy(entry)
            },
            closePanel: { [weak presenter] in presenter?.close() },
            reactivatePrevious: { [weak presenter] in
                guard let application = presenter?.previousApplication, !application.isTerminated else { return false }
                return application.activate(options: [])
            },
            synthesizePaste: { ClipboardServices.synthesizePaste() }
        )
        let monitor = ClipboardMonitor(
            reader: reader ?? SystemPasteboardReader(),
            suppressor: suppressor,
            options: options,
            sourceProvider: { [frontmostProvider] in
                guard let application = frontmostProvider() else { return nil }
                return ClipboardSource(
                    applicationName: application.localizedName,
                    bundleIdentifier: application.bundleIdentifier
                )
            },
            onCapture: { [weak model] classified in model?.capture(classified) }
        )
        let registrar = hotKeyRegistrar ?? CarbonHotKeyRegistrar()
        // `self` cannot be captured until every stored property (including
        // `hotKey` itself) is initialized, so the activation closure calls
        // through this local relay instead; it is pointed at `self` once
        // initialization finishes below.
        var activationRelay: (() -> Void)?
        let hotKey = ClipboardHotKeyController(registrar: registrar) { [weak presenter, frontmostProvider] in
            activationRelay?()
            presenter?.toggle(previousApplication: frontmostProvider())
        }

        self.model = model
        self.writer = writer
        self.thumbnailLoader = thumbnailLoader
        self.presenter = presenter
        self.action = action
        self.monitor = monitor
        self.hotKey = hotKey
        activationRelay = { [weak self] in self?.onWillActivate?() }

        configurePanelContent()
    }

    private func configurePanelContent() {
        presenter.makeContent = { [model, action, thumbnailLoader, localization, weak self] in
            AnyView(ClipboardPanelView(
                model: model,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                actions: ClipboardPanelActions(
                    primary: { entry in action.perform(entry, action: model.currentSelectionAction) },
                    copy: { entry in action.copyOnly(entry) },
                    togglePin: { entry in model.setPinned(!entry.isPinned, entryID: entry.id) },
                    delete: { entry in model.remove(entryID: entry.id) },
                    reveal: { entry in ClipboardServices.reveal(entry) },
                    clearUnpinned: { model.clearUnpinned() },
                    openSettings: {
                        self?.presenter.close()
                        self?.openSettings()
                    }
                )
            ))
        }
    }

    func start(loadPersisted: Bool) async {
        hotkeyConflict = !hotKey.apply(options.shortcut)
        if loadPersisted {
            await model.loadPersistedHistory()
        }
        guard !Task.isCancelled, options.isCaptureEnabled else { return }
        monitor.start()
    }

    func apply(_ options: ClipboardOptions) {
        let shortcutChanged = options.shortcut != self.options.shortcut
        let captureChanged = options.isCaptureEnabled != self.options.isCaptureEnabled
        self.options = options
        model.apply(options)
        monitor.apply(options)
        if captureChanged {
            if options.isCaptureEnabled {
                monitor.refreshObservedCount()
                monitor.start()
            } else {
                monitor.stop()
            }
        }
        if shortcutChanged {
            hotkeyConflict = !hotKey.apply(options.shortcut)
        }
    }

    func showPanel() {
        presenter.toggle(previousApplication: frontmostProvider())
    }

    func handleWake() {
        monitor.refreshObservedCount()
    }

    func stop() async {
        monitor.stop()
        hotKey.unregister()
        presenter.close()
        await model.flushPendingSave()
    }

    private static func reveal(_ entry: ClipboardEntry) {
        for item in entry.items {
            for representation in item.representations {
                if case let .fileURL(url) = representation, FileManager.default.fileExists(atPath: url.path) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    return
                }
            }
        }
    }

    /// Posts Command-V after a short delay to allow the previous app to reactivate.
    /// Returns whether Accessibility is available; when it is not, no paste is sent.
    @discardableResult
    static func synthesizePaste() -> Bool {
        guard AXIsProcessTrusted() else { return false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let source = CGEventSource(stateID: .combinedSessionState)
            let vKey: CGKeyCode = 9
            let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
            let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
            down?.flags = .maskCommand
            up?.flags = .maskCommand
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
        return true
    }
}
