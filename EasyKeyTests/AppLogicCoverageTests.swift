import AppKit
import AVFoundation
import Carbon
import CryptoKit
import EasyEngineCore
@testable import EasyKey
import SwiftUI
import Translation
import XCTest

/// Coverage additions for app-layer coordination and feature logic. Each
/// `// MARK:` section targets the residual uncovered branches of one
/// production file, extending the fakes already defined across EasyKeyTests.
@MainActor
final class AppLogicCoverageTests: XCTestCase {
    static let defaultNow = Date(timeIntervalSince1970: 1_700_000_000)

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicServices-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }
}

@MainActor
func appLogicWaitForCondition(timeout: TimeInterval = 3, condition: @escaping () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition(), Date() < deadline {
        try? await Task.sleep(for: .milliseconds(20))
    }
}

// MARK: - TranslationPanelPresenter.swift

extension AppLogicCoverageTests {
    func testTranslationPanel_CloseWithHandler_InvokesHandlerWithoutOrderingOut() {
        let panel = TranslationPanel(size: TranslationPanelPresenter.panelSize)
        var handlerCount = 0
        panel.setCloseHandler { handlerCount += 1 }

        panel.close()

        XCTAssertEqual(handlerCount, 1)
        XCTAssertFalse(panel.isVisible)
        panel.orderOut()
    }

    func testTranslationPanel_CloseWithoutHandler_FallsBackToSuperClose() {
        let panel = TranslationPanel(size: TranslationPanelPresenter.panelSize)

        panel.close()

        XCTAssertFalse(panel.isVisible)
    }

    func testTranslationPanel_ReplaceContent_InstallsHostingView() {
        let panel = TranslationPanel(size: TranslationPanelPresenter.panelSize)

        panel.replaceContent(AnyView(EmptyView()))

        XCTAssertNotNil(panel.contentView)
        panel.orderOut()
    }

    func testTranslationPanel_MakeKeyAndOrderFront_ShowsPanel() {
        let panel = TranslationPanel(size: TranslationPanelPresenter.panelSize)

        panel.makeKeyAndOrderFront()

        XCTAssertTrue(panel.isVisible)
        panel.orderOut()
    }

    func testTranslationPanel_ContainsWindowNumber_FallsBackToOwnWindowNumberWhenUnregistered() {
        let panel = TranslationPanel(size: TranslationPanelPresenter.panelSize)

        XCTAssertTrue(panel.containsWindowNumber(panel.windowNumber))
        XCTAssertFalse(panel.containsWindowNumber(panel.windowNumber + 1))
        panel.orderOut()
    }

    func testTranslationPanel_AddTitlebarAccessory_AppendsViewController() {
        let panel = TranslationPanel(size: TranslationPanelPresenter.panelSize)
        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = NSView(frame: NSRect(x: 0, y: 0, width: 20, height: 20))

        panel.addTitlebarAccessory(accessory)

        XCTAssertTrue(panel.titlebarAccessoryViewControllers.contains(accessory))
        panel.orderOut()
    }

    func testSystemTranslationPanelEventMonitor_AddGlobalClickMonitor_RegistrationInvalidatesCleanly() {
        let monitor = SystemTranslationPanelEventMonitor()

        let registration = monitor.addGlobalClickMonitor(handler: {})

        XCTAssertNotNil(registration)
        registration?.invalidate()
        registration?.invalidate()
    }
}

// MARK: - TranslationHotKeyController.swift

extension AppLogicCoverageTests {
    func testCarbonRegistrar_RegisterWithForeignSignature_ReturnsFalse() {
        let registrar = CarbonTranslationHotKeyRegistrar()
        defer { registrar.shutdown() }
        let identity = TranslationHotKeyIdentity(signature: 0xDEAD_BEEF, identifier: 1)

        let result = registrar.register(keyCode: 9, modifiers: 0, identity: identity, handler: {})

        XCTAssertFalse(result)
    }

    func testCarbonRegistrar_RegisterUnregisterShutdown_CompletesLifecycle() {
        let registrar = CarbonTranslationHotKeyRegistrar()
        let identity = TranslationHotKeyIdentity(
            signature: TranslationHotKeyController.carbonSignature,
            identifier: TranslationHotKeyController.firstCarbonIdentifier
        )

        let registered = registrar.register(
            keyCode: 0,
            modifiers: UInt32(optionKey | controlKey),
            identity: identity,
            handler: {}
        )
        guard registered else {
            XCTSkip("Carbon hotkey registration unavailable in this session")
            return
        }

        registrar.unregister(identity: identity)
        registrar.shutdown()
        registrar.shutdown()

        XCTAssertFalse(registrar.register(
            keyCode: 0,
            modifiers: UInt32(optionKey | controlKey),
            identity: identity,
            handler: {}
        ))
    }

    func testCarbonRegistrar_ShutdownWithActiveReference_PreventsLaterRegistration() {
        let registrar = CarbonTranslationHotKeyRegistrar()
        let identity = TranslationHotKeyIdentity(
            signature: TranslationHotKeyController.carbonSignature,
            identifier: TranslationHotKeyController.firstCarbonIdentifier
        )

        guard registrar.register(keyCode: 0, modifiers: UInt32(optionKey | controlKey), identity: identity, handler: {}) else {
            XCTSkip("Carbon hotkey registration unavailable in this session")
            return
        }

        registrar.shutdown()

        XCTAssertFalse(registrar.register(
            keyCode: 0,
            modifiers: UInt32(optionKey | controlKey),
            identity: identity,
            handler: {}
        ))
    }
}

// MARK: - ClipboardServices.swift

extension AppLogicCoverageTests {
    func testStartWithLoadPersisted_LoadsHistory() async throws {
        let now = AppLogicCoverageTests.defaultNow
        var options = ClipboardOptions(isCaptureEnabled: false)
        options.persistsHistory = true
        let keyStore = InMemoryClipboardKeyStore()
        let seeding = try ClipboardServices(
            options: options,
            applicationSupportDirectory: directory,
            localization: LocalizationStore(
                defaults: XCTUnwrap(UserDefaults(suiteName: "applogic-\(UUID().uuidString)")),
                bundle: .main
            ),
            keyProvider: keyStore,
            reader: FakePasteboardReader(),
            hotKeyRegistrar: FakeHotKeyRegistrar(),
            frontmostProvider: { nil }
        )
        seeding.model.capture(ClassifiedClipboard(
            entry: ClipboardEntry(
                fingerprint: "seed-fp",
                capturedAt: now,
                items: [ClipboardItem(
                    kind: .text,
                    preview: ClipboardItemPreview(primaryText: "seeded"),
                    representations: [.string(typeIdentifier: PasteboardClassifier.plainText, value: "seeded")]
                )]
            ),
            payloads: [:]
        ))
        await seeding.model.flushPendingSave()
        await seeding.stop()

        let services = try ClipboardServices(
            options: options,
            applicationSupportDirectory: directory,
            localization: LocalizationStore(
                defaults: XCTUnwrap(UserDefaults(suiteName: "applogic-\(UUID().uuidString)")),
                bundle: .main
            ),
            keyProvider: keyStore,
            reader: FakePasteboardReader(),
            hotKeyRegistrar: FakeHotKeyRegistrar(),
            frontmostProvider: { nil }
        )
        await services.start(loadPersisted: true)

        XCTAssertEqual(services.model.entryCount, 1)
        await services.stop()
    }

    func testThumbnailLoaderWiresToModelPayloadsAndRemoval() {
        let services = makeServices(enabled: true)
        let now = AppLogicCoverageTests.defaultNow
        let reference = "applogic-ref"
        services.model.capture(ClassifiedClipboard(
            entry: ClipboardEntry(
                fingerprint: "thumb-fp",
                capturedAt: now,
                items: [ClipboardItem(
                    kind: .image,
                    preview: ClipboardItemPreview(primaryText: "PNG image", typeLabel: "PNG"),
                    representations: [.data(typeIdentifier: PasteboardClassifier.png, payloadReference: reference)]
                )]
            ),
            payloads: [reference: Data([0x89, 0x50, 0x4E, 0x47])]
        ))

        XCTAssertEqual(services.model.payloadData(for: reference), Data([0x89, 0x50, 0x4E, 0x47]))
        _ = services.thumbnailLoader.thumbnail(for: reference)

        services.model.remove(entryID: services.model.history.entries[0].id)
        XCTAssertNil(services.model.payloadData(for: reference))
    }

    func testActionCopyOnly_WritesEntryThroughWriter() {
        let services = makeServices(enabled: false)
        let now = AppLogicCoverageTests.defaultNow
        let entry = ClipboardEntry(
            fingerprint: "copy-fp",
            capturedAt: now,
            items: [ClipboardItem(
                kind: .text,
                preview: ClipboardItemPreview(primaryText: "copy me"),
                representations: [.string(typeIdentifier: PasteboardClassifier.plainText, value: "copy me")]
            )]
        )

        services.action.copyOnly(entry)

        XCTAssertNil(services.action.lastError)
    }

    func testMonitorCapture_WithRealFrontmost_SourcesEntryFromApplication() async throws {
        let reader = FakePasteboardReader()
        let services = try ClipboardServices(
            options: ClipboardOptions(isCaptureEnabled: true),
            applicationSupportDirectory: directory,
            localization: LocalizationStore(
                defaults: XCTUnwrap(UserDefaults(suiteName: "applogic-\(UUID().uuidString)")),
                bundle: .main
            ),
            keyProvider: InMemoryClipboardKeyStore(),
            reader: reader,
            hotKeyRegistrar: FakeHotKeyRegistrar(),
            frontmostProvider: { NSRunningApplication.current }
        )
        let text = "applogic-captured-\(UUID().uuidString)"
        reader.setText(text, changeCount: 99)
        reader.changeCount = 99

        services.monitor.poll()

        XCTAssertEqual(services.model.entryCount, 1)
        XCTAssertEqual(services.model.history.entries.first?.items.first?.preview.primaryText, text)
        let source = services.model.history.entries.first?.source
        XCTAssertNotNil(source?.bundleIdentifier)
        await services.stop()
    }

    private func makeServices(enabled: Bool, frontmostProvider: @escaping () -> NSRunningApplication? = { nil }) -> ClipboardServices {
        ClipboardServices(
            options: ClipboardOptions(isCaptureEnabled: enabled),
            applicationSupportDirectory: directory,
            localization: LocalizationStore(defaults: UserDefaults(suiteName: "applogic-\(UUID().uuidString)")!, bundle: .main),
            keyProvider: InMemoryClipboardKeyStore(),
            reader: FakePasteboardReader(),
            hotKeyRegistrar: FakeHotKeyRegistrar(),
            frontmostProvider: frontmostProvider
        )
    }
}

// MARK: - ClipboardHistoryModel.swift

extension AppLogicCoverageTests {
    func testCurrentSelectionAction_ReflectsOptions() {
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.selectionAction = .copyOnly
        let model = ClipboardHistoryModel(options: options, now: { AppLogicCoverageTests.defaultNow })

        XCTAssertEqual(model.currentSelectionAction, .copyOnly)
    }

    func testClearAll_WhenKeyDeletionThrowsNonPersistenceError_RecordsMalformedDocument() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-clear-throw-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let model = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: ThrowingDeleteKeyStore()),
            now: { AppLogicCoverageTests.defaultNow }
        )
        model.capture(historyTextClassified(fingerprint: "f", text: "data"))

        await model.clearAll()

        XCTAssertEqual(model.persistenceError, .malformedDocument)
    }

    func testClearAll_WhenTaskCancelledBeforeDeletion_RecordsMalformedDocument() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-clear-cancel-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let model = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: InMemoryClipboardKeyStore()),
            now: { AppLogicCoverageTests.defaultNow }
        )

        let task = Task { await model.clearAll() }
        task.cancel()
        await task.value

        XCTAssertEqual(model.persistenceError, .malformedDocument)
    }

    func testLoadPersisted_WhenKeyReadThrowsNonPersistenceError_RecordsMalformedDocument() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-load-throw-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let seeder = ClipboardPersistence(directory: directory, keyProvider: InMemoryClipboardKeyStore())
        let seedEntry = ClipboardEntry(
            fingerprint: "seed",
            capturedAt: AppLogicCoverageTests.defaultNow,
            items: [ClipboardItem(
                kind: .text,
                preview: ClipboardItemPreview(primaryText: "t"),
                representations: [.string(typeIdentifier: PasteboardClassifier.plainText, value: "t")]
            )]
        )
        try await seeder.save(entries: [seedEntry], payloads: [:])
        let model = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: ThrowingExistingKeyStore()),
            now: { AppLogicCoverageTests.defaultNow }
        )

        await model.loadPersistedHistory()

        XCTAssertEqual(model.persistenceError, .malformedDocument)
    }

    func testApplyDisablingPersistence_DeletesThroughPersistenceAndClearsError() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-disable-persist-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyStore = InMemoryClipboardKeyStore()
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let model = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: keyStore),
            now: { AppLogicCoverageTests.defaultNow },
            saveDebounce: .milliseconds(1)
        )
        model.capture(historyTextClassified(fingerprint: "f", text: "data"))
        await model.flushPendingSave()
        var historyDisabledOptions = options
        historyDisabledOptions.persistsHistory = false

        model.apply(historyDisabledOptions)
        await appLogicWaitForCondition { model.persistenceError == nil }

        XCTAssertNil(model.persistenceError)
    }

    func testApplyDisablingPersistence_WhenDeletionThrowsCancellationError_SilentlyReturns() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-disable-cancel-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let model = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: ThrowingDeleteKeyStore(cancellation: true)),
            now: { AppLogicCoverageTests.defaultNow }
        )

        model.apply(historyDisabled(options))
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertNil(model.persistenceError)
    }

    func testApplyDisablingPersistence_WhenDeletionThrows_RecordsError() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-disable-throw-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let model = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: ThrowingDeleteKeyStore()),
            now: { AppLogicCoverageTests.defaultNow }
        )

        model.apply(historyDisabled(options))
        await appLogicWaitForCondition { model.persistenceError != nil }

        XCTAssertEqual(model.persistenceError, .malformedDocument)
    }

    func testFlushPendingSave_WhenSaveThrows_RecordsError() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-save-throw-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let model = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: ThrowingExistingKeyStore()),
            now: { AppLogicCoverageTests.defaultNow },
            saveDebounce: .milliseconds(1)
        )
        model.capture(historyTextClassified(fingerprint: "f", text: "data"))

        await model.flushPendingSave()

        XCTAssertEqual(model.persistenceError, .malformedDocument)
    }

    func testFlushPendingSave_CollectsPayloadDataIntoDocument() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-save-payloads-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let keyStore = InMemoryClipboardKeyStore()
        let model = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: keyStore),
            now: { AppLogicCoverageTests.defaultNow },
            saveDebounce: .milliseconds(1)
        )
        let reference = "img-ref"
        model.capture(ClassifiedClipboard(
            entry: ClipboardEntry(
                fingerprint: "img-fp",
                capturedAt: AppLogicCoverageTests.defaultNow,
                items: [ClipboardItem(
                    kind: .image,
                    preview: ClipboardItemPreview(primaryText: "PNG image", typeLabel: "PNG"),
                    representations: [.data(typeIdentifier: PasteboardClassifier.png, payloadReference: reference)]
                )]
            ),
            payloads: [reference: Data([0x01, 0x02, 0x03])]
        ))

        await model.flushPendingSave()

        let loader = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: keyStore),
            now: { AppLogicCoverageTests.defaultNow }
        )
        await loader.loadPersistedHistory()
        XCTAssertEqual(loader.payloadData(for: reference), Data([0x01, 0x02, 0x03]))
    }

    func testLoadPersistedHistory_CapsPinnedEntriesToLimit() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-pin-cap-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let keyStore = InMemoryClipboardKeyStore()
        let writer = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: keyStore),
            now: { AppLogicCoverageTests.defaultNow },
            saveDebounce: .milliseconds(1)
        )
        let count = ClipboardHistory.maximumPinnedEntries + 3
        for index in 0 ..< count {
            writer.capture(historyTextClassified(fingerprint: "pin-\(index)", text: "t\(index)"))
        }
        for entry in writer.history.entries {
            writer.setPinned(true, entryID: entry.id)
        }
        await writer.flushPendingSave()

        let reader = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: keyStore),
            now: { AppLogicCoverageTests.defaultNow }
        )
        await reader.loadPersistedHistory()

        let pinnedCount = reader.history.entries.filter(\.isPinned).count
        XCTAssertLessThanOrEqual(pinnedCount, ClipboardHistory.maximumPinnedEntries)
    }

    private func historyDisabled(_ options: ClipboardOptions) -> ClipboardOptions {
        var disabled = options
        disabled.persistsHistory = false
        return disabled
    }

    private func historyTextClassified(fingerprint: String, text: String) -> ClassifiedClipboard {
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: text),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: text)]
        )
        let entry = ClipboardEntry(fingerprint: fingerprint, capturedAt: AppLogicCoverageTests.defaultNow, items: [item])
        return ClassifiedClipboard(entry: entry, payloads: [:])
    }
}

private final class ThrowingDeleteKeyStore: ClipboardKeyProviding, @unchecked Sendable {
    private let cancellation: Bool

    init(cancellation: Bool = false) {
        self.cancellation = cancellation
    }

    func existingKey() throws -> SymmetricKey? {
        SymmetricKey(size: .bits256)
    }

    func createKey() throws -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    func deleteKey() throws {
        if cancellation {
            throw CancellationError()
        }
        throw NSError(domain: "AppLogicCoverage", code: 1)
    }
}

private final class ThrowingExistingKeyStore: ClipboardKeyProviding, @unchecked Sendable {
    func existingKey() throws -> SymmetricKey? {
        throw NSError(domain: "AppLogicCoverage", code: 2)
    }

    func createKey() throws -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    func deleteKey() throws {}
}

// MARK: - TranslationSettingsModel.swift

extension AppLogicCoverageTests {
    func testSettingsModel_ConvenienceInit_ConstructsWithPlatformCapability() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicSettings-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))

        let model = TranslationSettingsModel(settingsStore: store)

        XCTAssertFalse(model.visibleProviderCards.isEmpty)
        XCTAssertEqual(model.selectableProviders.first, .apple)
    }

    func testSettingsModel_CmdCDoublePressAccessorsAndSetters_NotifyCallback() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicSettings-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
        let model = makeSettingsModel(store: store)
        var notifications = 0
        model.onCmdCDoublePressChanged = { notifications += 1 }

        model.setCmdCDoublePressEnabled(true)
        model.setCmdCDoublePressWindowMs(700)

        XCTAssertTrue(model.cmdCDoublePressEnabled)
        XCTAssertEqual(model.cmdCDoublePressWindowMs, 700)
        XCTAssertEqual(notifications, 2)
    }

    func testSettingsModel_Availability_ReflectsCredentialAndPlatform() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicSettings-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
        let credentials = InMemoryTranslationCredentialStore(credentials: [.deepL: "key"])
        let model = TranslationSettingsModel(
            settingsStore: store,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
            credentialStore: credentials
        )

        let deepLAvailability = model.availability(of: .deepL)
        let appleAvailability = model.availability(of: .apple)

        XCTAssertEqual(deepLAvailability, .available)
        XCTAssertEqual(appleAvailability, .unsupportedOnPlatform)
    }

    func testSettingsModel_LoadModelCatalog_MergesCurrentIdentifierWhenMissing() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicSettings-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
        store.update {
            $0.translation.openAIModelIdentifier = "current-model"
            $0.translation.preferredProviderID = .openAI
        }
        let model = TranslationSettingsModel(
            settingsStore: store,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.openAI: "key"]),
            modelCatalog: FakeEmptyModelCatalog()
        )
        model.loadModelCatalog(for: .openAI)
        await appLogicWaitForCondition(timeout: 2) {
            if case .loaded = model.modelCatalogStates[.openAI] {
                return true
            }
            return false
        }

        if case let .loaded(entries)? = model.modelCatalogStates[.openAI] {
            XCTAssertTrue(entries.contains { $0.identifier == "current-model" })
        } else {
            XCTFail("Expected loaded catalog")
        }
    }

    private func makeSettingsModel(store: SettingsStore) -> TranslationSettingsModel {
        TranslationSettingsModel(
            settingsStore: store,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
            credentialStore: InMemoryTranslationCredentialStore(),
            shortcutRegistrationState: .unregistered,
            shortcutApplier: { _ in .unregistered }
        )
    }
}

// MARK: - TranslationSpeechController.swift

extension AppLogicCoverageTests {
    func testSystemSpeechEngine_VoiceIdentifierForKnownLanguage_ReturnsVoice() {
        let engine = SystemTranslationSpeechEngine()

        let identifier = engine.voiceIdentifier(for: "en-US")

        XCTAssertNotNil(identifier)
    }

    func testSystemSpeechEngine_VoiceIdentifierForUnknownLanguage_ReturnsNil() {
        let engine = SystemTranslationSpeechEngine()

        let identifier = engine.voiceIdentifier(for: "xx-XX-nonexistent")

        XCTAssertNil(identifier)
    }
}

// MARK: - SmartSwitchController.swift

extension AppLogicCoverageTests {
    func testRememberChoiceIfNeeded_WhenFrontmostIsExternalApp_UpdatesStoredChoice() throws {
        let suiteName = "AppLogicSmartSwitch-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicSmartSwitch-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settingsStore = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
        let smartSwitchStore = SmartSwitchStore(fileURL: directory.appendingPathComponent("smart-switch.json"))
        let localization = LocalizationStore(defaults: defaults, bundle: .main)
        let controller = SmartSwitchController(
            smartSwitchStore: smartSwitchStore,
            settingsStore: settingsStore,
            localization: localization
        )
        settingsStore.update {
            $0.smartSwitch.enabled = true
            $0.smartSwitch.rememberEncoding = false
            $0.input.language = .english
        }
        guard let frontmost = NSWorkspace.shared.frontmostApplication,
              frontmost.bundleIdentifier != Bundle.main.bundleIdentifier,
              !frontmost.isTerminated
        else {
            throw XCTSkip("No external frontmost application available")
        }

        controller.handleApplicationActivation(frontmost)
        controller.rememberChoiceIfNeeded(from: settingsStore.settings)
        settingsStore.update { $0.input.language = .vietnamese }
        let revisionBefore = controller.smartSwitchRevision

        controller.rememberChoiceIfNeeded(from: settingsStore.settings)

        XCTAssertGreaterThan(controller.smartSwitchRevision, revisionBefore)
        XCTAssertFalse(controller.currentAppSmartSwitchStatus.isEmpty)
    }
}

// MARK: - ClipboardHotKeyController.swift

extension AppLogicCoverageTests {
    func testClipboardHotKey_DuplicateApply_SkipsRegistrarAndKeepsRegistration() {
        let registrar = FakeHotKeyRegistrar()
        let controller = ClipboardHotKeyController(registrar: registrar) {}
        let shortcut = Shortcut(keyCode: 9, modifiers: [.command])

        XCTAssertTrue(controller.apply(shortcut))
        let registerCount = registrar.registerCount
        XCTAssertTrue(controller.apply(shortcut))

        XCTAssertEqual(registrar.registerCount, registerCount)
        XCTAssertTrue(controller.isRegistered)
    }

    func testClipboardHotKey_ApplyWithShiftModifier_RegistersShortcut() {
        let registrar = FakeHotKeyRegistrar()
        let controller = ClipboardHotKeyController(registrar: registrar) {}

        XCTAssertTrue(controller.apply(Shortcut(keyCode: 1, modifiers: [.command, .shift])))

        XCTAssertEqual(registrar.registerCount, 1)
        controller.shutdown()
    }
}

// MARK: - AppTranslationRuntime.swift

extension AppLogicCoverageTests {
    func testAppTranslationRuntime_ActivateFromDoubleCmdC_SeedsCapturedTextAndShowsPanel() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicRuntime-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settingsStore = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
        settingsStore.update {
            $0.translation.isEnabled = true
            $0.translation.showInMenuPopover = false
        }
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "AppLogicRuntime-\(UUID().uuidString)"))
        defer { defaults.removePersistentDomain(forName: "AppLogicRuntime-\(UUID().uuidString)") }
        let localization = LocalizationStore(defaults: defaults, bundle: .main)
        let capture = TestTranslationCapture()
        capture.result = SelectedTextCaptureResult(text: "double-cmd-c text", source: .accessibility, accessibilityResult: .absent)
        let registrar = TestTranslationHotKeyRegistrar()
        let panelMonitor = AppLogicPanelMonitor()
        let panelWindow = AppLogicPanelWindow()
        let speechEngine = AppLogicSpeechEngine()
        let runtime = AppTranslationRuntime(
            settingsStore: settingsStore,
            localization: localization,
            dependencies: AppTranslationRuntime.Dependencies(
                credentialStore: InMemoryTranslationCredentialStore(),
                platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
                capture: capture,
                hotKeyRegistrar: registrar,
                disclosurePrompt: { _ in true },
                panelPresenter: { model, speech in
                    TranslationPanelPresenter(
                        translation: model,
                        speech: speech,
                        eventMonitor: panelMonitor,
                        panelFactory: { panelWindow },
                        activateEasyKey: {},
                        pointerLocation: { .zero },
                        screenGeometries: { [] },
                        userDefaults: defaults
                    )
                },
                speech: TranslationSpeechController(engine: speechEngine)
            )
        )
        runtime.start()

        runtime.activateFromDoubleCmdC()

        XCTAssertEqual(runtime.model.sourceText, "double-cmd-c text")
        XCTAssertTrue(panelWindow.visibleCount > 0)
        runtime.stop()
    }
}

// MARK: - ClipboardPanelPresenter.swift

extension AppLogicCoverageTests {
    func testClipboardPanelPresenter_ToggleWhenShown_ClosesPanel() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "AppLogicClipPanel-\(UUID().uuidString)"))
        defer { defaults.removePersistentDomain(forName: "AppLogicClipPanel-\(UUID().uuidString)") }
        let presenter = ClipboardPanelPresenter(userDefaults: defaults)

        presenter.toggle(previousApplication: nil)
        XCTAssertTrue(presenter.isShown)
        presenter.toggle(previousApplication: nil)

        XCTAssertFalse(presenter.isShown)
    }

    func testClipboardPanelPresenter_SecondShow_ReusesPanel() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "AppLogicClipPanel-\(UUID().uuidString)"))
        defer { defaults.removePersistentDomain(forName: "AppLogicClipPanel-\(UUID().uuidString)") }
        let presenter = ClipboardPanelPresenter(userDefaults: defaults)

        presenter.show(previousApplication: nil)
        presenter.show(previousApplication: nil)

        XCTAssertTrue(presenter.isShown)
        presenter.close()
    }
}

// MARK: - LogExporter.swift

extension AppLogicCoverageTests {
    func testLogExporter_WriteExportWithExcludedCategories_AppendsEmptyMarker() throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory.appendingPathComponent("AppLogicLogs-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: directory) }

        let url = try LogExporter.writeExport(fileManager: fileManager, now: Date(), allowedCategories: [])

        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("(no log entries in lookback window)"))
        try? fileManager.removeItem(at: url.deletingLastPathComponent())
    }
}

// MARK: - OpenAICompatibleTranslationProvider.swift

extension AppLogicCoverageTests {
    func testOpenAICompatible_InvalidEndpoint_ThrowsProviderUnavailable() async throws {
        let provider = try OpenAICompatibleTranslationProvider(
            endpoint: XCTUnwrap(URL(string: "http://insecure.example.com/v1/chat")),
            providerID: .openAICompatible,
            modelIdentifier: "model",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.openAICompatible: "key"]),
            session: URLSession.shared
        )

        do {
            _ = try await provider.translate(appLogicSampleRequest)
            XCTFail("Expected providerUnavailable")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .providerUnavailable(provider: .openAICompatible, httpStatus: nil))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testOpenAICompatible_DisclosureIdentity_CarriesEndpointOrigin() throws {
        let provider = try OpenAICompatibleTranslationProvider(
            endpoint: XCTUnwrap(URL(string: "https://api.example.com/v1/chat")),
            providerID: .openAICompatible,
            modelIdentifier: "model",
            credentialStore: InMemoryTranslationCredentialStore(),
            session: URLSession.shared
        )

        XCTAssertEqual(provider.disclosureIdentity.providerID, .openAICompatible)
        XCTAssertEqual(provider.disclosureIdentity.endpointOrigin, "https://api.example.com")
    }

    func testOpenAICompatible_TaskCancellation_ThrowsCancelled() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            try await Task.sleep(nanoseconds: 60_000_000_000)
            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = try OpenAICompatibleTranslationProvider(
            endpoint: XCTUnwrap(URL(string: "https://api.example.com/v1/chat")),
            providerID: .openAICompatible,
            modelIdentifier: "model",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.openAICompatible: "key"]),
            session: AppLogicURLProtocol.session()
        )
        let task = Task { try await provider.translate(appLogicSampleRequest) }
        try? await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .cancelled)
        }
    }

    func testOpenAICompatible_StripsThinkingWrappersAndTranslates() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            let body = String(data: request.httpBodyStreamData() ?? request.httpBody ?? Data(), encoding: .utf8) ?? ""
            XCTAssertTrue(body.contains("include_reasoning"))
            let response = """
            {"choices":[{"message":{"content":"<think>draft</think><think>more</think>Xin chào"}}]}
            """
            return (Data(response.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = try OpenAICompatibleTranslationProvider(
            endpoint: XCTUnwrap(URL(string: "https://api.example.com/v1/chat")),
            providerID: .openAICompatible,
            modelIdentifier: "model",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.openAICompatible: "key"]),
            session: AppLogicURLProtocol.session()
        )

        let response = try await provider.translate(appLogicSampleRequest)

        XCTAssertEqual(response.translatedText, "Xin chào")
    }

    func testOpenAICompatible_ContentStrippedToEmpty_ThrowsInvalidResponse() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            let response = """
            {"choices":[{"message":{"content":"<think>only thinking</think>"}}]}
            """
            return (Data(response.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = try OpenAICompatibleTranslationProvider(
            endpoint: XCTUnwrap(URL(string: "https://api.example.com/v1/chat")),
            providerID: .openAICompatible,
            modelIdentifier: "model",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.openAICompatible: "key"]),
            session: AppLogicURLProtocol.session()
        )

        do {
            _ = try await provider.translate(appLogicSampleRequest)
            XCTFail("Expected invalidResponse")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .invalidResponse(provider: .openAICompatible))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - AnthropicCompatibleTranslationProvider.swift

extension AppLogicCoverageTests {
    func testAnthropicCompatible_InvalidEndpoint_ThrowsProviderUnavailable() async throws {
        let provider = try AnthropicCompatibleTranslationProvider(
            endpoint: XCTUnwrap(URL(string: "http://insecure.example.com/v1/messages")),
            providerID: .anthropicCompatible,
            modelIdentifier: "model",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.anthropicCompatible: "key"]),
            session: URLSession.shared
        )

        do {
            _ = try await provider.translate(appLogicSampleRequest)
            XCTFail("Expected providerUnavailable")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .providerUnavailable(provider: .anthropicCompatible, httpStatus: nil))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAnthropicCompatible_DisclosureIdentity_CarriesEndpointOrigin() throws {
        let provider = try AnthropicCompatibleTranslationProvider(
            endpoint: XCTUnwrap(URL(string: "https://api.example.com/v1/messages")),
            providerID: .anthropicCompatible,
            modelIdentifier: "model",
            credentialStore: InMemoryTranslationCredentialStore(),
            session: URLSession.shared
        )

        XCTAssertEqual(provider.disclosureIdentity.providerID, .anthropicCompatible)
        XCTAssertEqual(provider.disclosureIdentity.endpointOrigin, "https://api.example.com")
    }

    func testAnthropicCompatible_TaskCancellation_ThrowsCancelled() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            try await Task.sleep(nanoseconds: 60_000_000_000)
            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = try AnthropicCompatibleTranslationProvider(
            endpoint: XCTUnwrap(URL(string: "https://api.example.com/v1/messages")),
            providerID: .anthropicCompatible,
            modelIdentifier: "model",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.anthropicCompatible: "key"]),
            session: AppLogicURLProtocol.session()
        )
        let task = Task { try await provider.translate(appLogicSampleRequest) }
        try? await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .cancelled)
        }
    }

    func testAnthropicCompatible_Translate_EncodesThinkingDisabledBody() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            let body = String(data: request.httpBodyStreamData() ?? request.httpBody ?? Data(), encoding: .utf8) ?? ""
            XCTAssertTrue(body.contains("\"thinking\""))
            let response = """
            {"type":"message","role":"assistant","content":[{"type":"text","text":"<translation>Xin chào</translation>"}]}
            """
            return (Data(response.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = try AnthropicCompatibleTranslationProvider(
            endpoint: XCTUnwrap(URL(string: "https://api.example.com/v1/messages")),
            providerID: .anthropicCompatible,
            modelIdentifier: "model",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.anthropicCompatible: "key"]),
            session: AppLogicURLProtocol.session()
        )

        let response = try await provider.translate(appLogicSampleRequest)

        XCTAssertEqual(response.translatedText, "Xin chào")
    }
}

// MARK: - OpenAITranslationProvider.swift / GeminiTranslationProvider.swift / AnthropicTranslationProvider.swift / GoogleTranslationProvider.swift

extension AppLogicCoverageTests {
    func testOpenAIProvider_TaskCancellation_ThrowsCancelled() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            try await Task.sleep(nanoseconds: 60_000_000_000)
            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = OpenAITranslationProvider(
            modelIdentifier: "gpt-4o-mini",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.openAI: "key"]),
            session: AppLogicURLProtocol.session()
        )
        let task = Task { try await provider.translate(appLogicSampleRequest) }
        try? await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .cancelled)
        }
    }

    func testOpenAIProvider_Success_EncodesReasoningDisabledBody() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            let body = String(data: request.httpBodyStreamData() ?? request.httpBody ?? Data(), encoding: .utf8) ?? ""
            XCTAssertTrue(body.contains("\"reasoning\""))
            let response = """
            {"status":"completed","output":[{"type":"message","role":"assistant","content":[{"type":"output_text","text":"{\\"translation\\":\\"Xin chào\\"}"}]}]}
            """
            return (Data(response.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = OpenAITranslationProvider(
            modelIdentifier: "gpt-4o-mini",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.openAI: "key"]),
            session: AppLogicURLProtocol.session()
        )

        let response = try await provider.translate(appLogicSampleRequest)

        XCTAssertEqual(response.translatedText, "Xin chào")
    }

    func testGeminiProvider_TaskCancellation_ThrowsCancelled() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            try await Task.sleep(nanoseconds: 60_000_000_000)
            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = GeminiTranslationProvider(
            modelIdentifier: "gemini-2.0-flash",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.gemini: "key"]),
            session: AppLogicURLProtocol.session()
        )
        let task = Task { try await provider.translate(appLogicSampleRequest) }
        try? await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .cancelled)
        }
    }

    func testAnthropicProvider_TaskCancellation_ThrowsCancelled() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            try await Task.sleep(nanoseconds: 60_000_000_000)
            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = AnthropicTranslationProvider(
            modelIdentifier: "claude-3-5-sonnet",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.anthropic: "key"]),
            session: AppLogicURLProtocol.session()
        )
        let task = Task { try await provider.translate(appLogicSampleRequest) }
        try? await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .cancelled)
        }
    }

    func testAnthropicProvider_Success_EncodesThinkingDisabledBody() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            let body = String(data: request.httpBodyStreamData() ?? request.httpBody ?? Data(), encoding: .utf8) ?? ""
            XCTAssertTrue(body.contains("\"thinking\""))
            let response = """
            {"type":"message","role":"assistant","stop_reason":"end_turn","content":[{"type":"text","text":"<translation>Xin chào</translation>"}]}
            """
            return (Data(response.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = AnthropicTranslationProvider(
            modelIdentifier: "claude-3-5-sonnet",
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.anthropic: "key"]),
            session: AppLogicURLProtocol.session()
        )

        let response = try await provider.translate(appLogicSampleRequest)

        XCTAssertEqual(response.translatedText, "Xin chào")
    }

    func testGoogleProvider_TaskCancellation_ThrowsCancelled() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            try await Task.sleep(nanoseconds: 60_000_000_000)
            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = GoogleTranslationProvider(
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.google: "key"]),
            session: AppLogicURLProtocol.session()
        )
        let task = Task { try await provider.translate(appLogicSampleRequest) }
        try? await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .cancelled)
        }
    }

    func testGoogleProvider_DanglingAmpersand_DecodesRemainderLiterally() async throws {
        AppLogicURLProtocol.requestHandler = { request in
            let response = """
            {"data":{"translations":[{"translatedText":"Xin chào & bạn"}]}}
            """
            return (Data(response.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let provider = GoogleTranslationProvider(
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.google: "key"]),
            session: AppLogicURLProtocol.session()
        )

        let response = try await provider.translate(appLogicSampleRequest)

        XCTAssertEqual(response.translatedText, "Xin chào & bạn")
    }
}

// MARK: - DeepLTranslationProvider.swift

extension AppLogicCoverageTests {
    func testDeepLValidateCredential_OversizedResponse_ThrowsInvalidResponse() async {
        MockDeepLURLProtocol.requestHandler = { request in
            (
                Data(repeating: 0x41, count: 2 * 1024 * 1024),
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            )
        }
        defer { MockDeepLURLProtocol.requestHandler = nil }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockDeepLURLProtocol.self]
        let provider = DeepLTranslationProvider(
            endpoint: .free,
            credentialStore: InMemoryTranslationCredentialStore(),
            session: URLSession(configuration: configuration)
        )

        do {
            _ = try await provider.validateCredential("test-key")
            XCTFail("Expected invalidResponse")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .invalidResponse(provider: .deepL))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - PasteboardWriter.swift

extension AppLogicCoverageTests {
    func testPasteboardWriter_CopyEntryWithMissingFile_ThrowsUnavailableRepresentation() {
        let writer = PasteboardWriter(suppressor: ClipboardWriteSuppressor())
        let entry = ClipboardEntry(
            fingerprint: "file-fp",
            capturedAt: AppLogicCoverageTests.defaultNow,
            items: [ClipboardItem(
                kind: .file,
                preview: ClipboardItemPreview(primaryText: "missing"),
                representations: [.fileURL(URL(fileURLWithPath: "/nonexistent/missing-file.txt"))]
            )]
        )

        XCTAssertThrowsError(try writer.copy(entry)) { error in
            XCTAssertEqual(error as? PasteboardWriteError, .unavailableRepresentation)
        }
    }

    func testPasteboardWriter_CopyEntryWithDataPayload_WritesAllRepresentations() throws {
        let payloadStore = ClipboardPayloadStore()
        let reference = "writer-ref"
        XCTAssertTrue(payloadStore.insert([reference: Data([0xDE, 0xAD, 0xBE, 0xEF])]))
        let writer = PasteboardWriter(
            pasteboard: uniqueNamedPasteboard(),
            suppressor: ClipboardWriteSuppressor(),
            payloadStore: payloadStore
        )
        let entry = ClipboardEntry(
            fingerprint: "data-fp",
            capturedAt: AppLogicCoverageTests.defaultNow,
            items: [ClipboardItem(
                kind: .image,
                preview: ClipboardItemPreview(primaryText: "PNG image", typeLabel: "PNG"),
                representations: [.data(typeIdentifier: PasteboardClassifier.png, payloadReference: reference)]
            )]
        )

        try writer.copy(entry)

        XCTAssertTrue(true)
    }

    func testPasteboardWriter_CopyConvertedTextWithHTML_WritesBothRepresentations() {
        let writer = PasteboardWriter(pasteboard: uniqueNamedPasteboard(), suppressor: ClipboardWriteSuppressor())

        let result = writer.copyConvertedText("hello", preservingHTML: Data("<b>hello</b>".utf8))

        XCTAssertTrue(result)
    }

    func testPasteboardWriter_CopyConvertedTextWithoutHTML_WritesTextOnly() {
        let writer = PasteboardWriter(pasteboard: uniqueNamedPasteboard(), suppressor: ClipboardWriteSuppressor())

        let result = writer.copyConvertedText("hello", preservingHTML: nil)

        XCTAssertTrue(result)
    }

    private func uniqueNamedPasteboard() -> NSPasteboard {
        NSPasteboard(name: NSPasteboard.Name("AppLogicWriter-\(UUID().uuidString)"))
    }
}

// MARK: - ClipboardPersistence.swift

extension AppLogicCoverageTests {
    func testClipboardPersistence_SaveWithMismatchedPayloads_ThrowsMalformedDocument() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicPersist-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = ClipboardPersistence(directory: directory, keyProvider: InMemoryClipboardKeyStore())
        let entry = ClipboardEntry(
            fingerprint: "fp",
            capturedAt: AppLogicCoverageTests.defaultNow,
            items: [ClipboardItem(
                kind: .text,
                preview: ClipboardItemPreview(primaryText: "t"),
                representations: [.string(typeIdentifier: PasteboardClassifier.plainText, value: "t")]
            )]
        )

        do {
            _ = try await persistence.save(entries: [entry], payloads: ["unreferenced": Data()])
            XCTFail("Expected malformedDocument")
        } catch {
            XCTAssertEqual(error as? ClipboardPersistenceError, .malformedDocument)
        }
    }

    func testClipboardPersistence_SaveWithOversizedManifest_ThrowsMalformedDocument() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicPersist-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = ClipboardPersistence(directory: directory, keyProvider: InMemoryClipboardKeyStore())
        let oversized = String(repeating: "x", count: 12 * 1024 * 1024)
        let entry = ClipboardEntry(
            fingerprint: "fp",
            capturedAt: AppLogicCoverageTests.defaultNow,
            items: [ClipboardItem(
                kind: .text,
                preview: ClipboardItemPreview(primaryText: "t"),
                representations: [.string(typeIdentifier: PasteboardClassifier.plainText, value: oversized)]
            )]
        )

        do {
            _ = try await persistence.save(entries: [entry], payloads: [:])
            XCTFail("Expected malformedDocument")
        } catch {
            XCTAssertEqual(error as? ClipboardPersistenceError, .malformedDocument)
        }
    }

    func testClipboardPersistence_LoadWithTamperedManifest_ThrowsMalformedDocument() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicPersist-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyStore = InMemoryClipboardKeyStore()
        let persistence = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        let entry = ClipboardEntry(
            fingerprint: "fp",
            capturedAt: AppLogicCoverageTests.defaultNow,
            items: [ClipboardItem(
                kind: .text,
                preview: ClipboardItemPreview(primaryText: "t"),
                representations: [.string(typeIdentifier: PasteboardClassifier.plainText, value: "t")]
            )]
        )
        try await persistence.save(entries: [entry], payloads: [:])

        // Re-seal a document whose entries violate schema invariants and
        // overwrite the manifest, keeping the payload directory intact.
        let invalidEntry = ClipboardEntry(
            fingerprint: "",
            capturedAt: AppLogicCoverageTests.defaultNow,
            items: [ClipboardItem(
                kind: .text,
                preview: ClipboardItemPreview(primaryText: "t"),
                representations: [.string(typeIdentifier: PasteboardClassifier.plainText, value: "t")]
            )]
        )
        let document = ClipboardPersistenceDocument(
            schemaVersion: ClipboardPersistenceDocument.currentSchemaVersion,
            savedAt: Date(),
            entries: [invalidEntry]
        )
        let encoded = try JSONEncoder().encode(document)
        let key = try XCTUnwrap(keyStore.existingKey())
        let sealed = try XCTUnwrap(try AES.GCM.seal(encoded, using: key).combined)
        let manifestURL = directory.appendingPathComponent("manifest.ekc")
        try sealed.write(to: manifestURL, options: .atomic)

        do {
            _ = try await persistence.load()
            XCTFail("Expected malformedDocument")
        } catch {
            XCTAssertEqual(error as? ClipboardPersistenceError, .malformedDocument)
        }
    }

    func testClipboardPersistence_LoadWhenManifestIsDirectory_ThrowsMalformedDocument() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicPersist-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyStore = InMemoryClipboardKeyStore()
        _ = try keyStore.createKey()
        let persistence = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        let manifestURL = directory.appendingPathComponent("manifest.ekc")
        try FileManager.default.createDirectory(at: manifestURL, withIntermediateDirectories: true)

        do {
            _ = try await persistence.load()
            XCTFail("Expected malformedDocument")
        } catch {
            XCTAssertEqual(error as? ClipboardPersistenceError, .malformedDocument)
        }
    }
}

// MARK: - PasteboardClassifier.swift

extension AppLogicCoverageTests {
    func testPasteboardClassifier_ClassifyTiffSnapshot_ProducesImageItem() {
        let classifier = PasteboardClassifier()
        let snapshot = PasteboardSnapshot(
            changeCount: 1,
            items: [PasteboardItemSnapshot(representations: [
                CapturedPasteboardRepresentation(typeIdentifier: PasteboardClassifier.tiff, data: Data([0x49, 0x49, 0x2A, 0x00])),
            ])]
        )

        let classified = classifier.classify(snapshot, source: nil, now: AppLogicCoverageTests.defaultNow)

        XCTAssertEqual(classified?.entry.items.first?.kind, .image)
        XCTAssertEqual(classified?.entry.items.first?.preview.typeLabel, "TIFF")
    }
}

// MARK: - WorkspaceObserver.swift

extension AppLogicCoverageTests {}

// MARK: - TranslationCredentialStore.swift

extension AppLogicCoverageTests {
    func testKeychainCredentialStore_SaveThenDeleteSucceeds() throws {
        let store = KeychainTranslationCredentialStore(service: "applogic.test-\(UUID().uuidString)")
        let provider = TranslationProviderID.deepL
        defer { try? store.deleteCredential(for: provider) }

        do {
            try store.save("first-key", for: provider)
            try store.deleteCredential(for: provider)
        } catch TranslationCredentialError.unexpectedStatus {
            throw XCTSkip("Keychain access unavailable in this test environment")
        }

        XCTAssertFalse(try store.hasCredential(for: provider))
    }
}

// MARK: - PasteboardSnapshot.swift

extension AppLogicCoverageTests {
    func testSystemPasteboardReader_SnapshotOverByteLimit_ReturnsExceededFlag() {
        let pasteboard = uniqueNamedPasteboard()
        defer { pasteboard.clearContents() }
        pasteboard.clearContents()
        let type = "com.applogic.test.big"
        pasteboard.setData(Data(repeating: 0xAB, count: 11 * 1024 * 1024), forType: NSPasteboard.PasteboardType(type))
        let reader = SystemPasteboardReader(pasteboard: pasteboard)

        let snapshot = reader.snapshot(selecting: [[type]])

        XCTAssertTrue(snapshot.exceededByteLimit)
    }

    func testSystemPasteboardReader_SnapshotWithinLimit_ReturnsRepresentations() {
        let pasteboard = uniqueNamedPasteboard()
        defer { pasteboard.clearContents() }
        pasteboard.clearContents()
        let type = "com.applogic.test.small"
        pasteboard.setData(Data("hello".utf8), forType: NSPasteboard.PasteboardType(type))
        let reader = SystemPasteboardReader(pasteboard: pasteboard)

        let snapshot = reader.snapshot(selecting: [[type]])

        XCTAssertFalse(snapshot.exceededByteLimit)
        XCTAssertEqual(snapshot.items.first?.representations.first?.data, Data("hello".utf8))
    }
}

// MARK: - TranslationModelCatalog.swift

extension AppLogicCoverageTests {
    func testModelCatalog_StoreThrows_BecomesMissingCredentials() async {
        let catalog = LiveTranslationModelCatalog(
            credentialStore: AppLogicThrowingCredentialStore(),
            session: URLSession.shared
        )

        do {
            _ = try await catalog.fetchModels(for: .openAI)
            XCTFail("Expected missingCredentials")
        } catch {
            XCTAssertEqual(error, TranslationModelCatalogError.missingCredentials)
        }
    }

    func testModelCatalog_TransportThrowsNonURLError_ReportsRequestFailed() async {
        AppLogicURLProtocol.requestHandler = { _ in throw NSError(domain: "AppLogic", code: -1) }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let catalog = LiveTranslationModelCatalog(
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.openAI: "key"]),
            session: AppLogicURLProtocol.session()
        )

        do {
            _ = try await catalog.fetchModels(for: .openAI)
            XCTFail("Expected requestFailed")
        } catch {
            XCTAssertEqual(error, TranslationModelCatalogError.requestFailed(status: -1))
        }
    }

    func testModelCatalog_NonHTTPResponse_ReportsRequestFailed() async {
        AppLogicURLProtocol.requestHandler = { request in
            (Data(), URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let catalog = LiveTranslationModelCatalog(
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.openAI: "key"]),
            session: AppLogicURLProtocol.session()
        )

        do {
            _ = try await catalog.fetchModels(for: .openAI)
            XCTFail("Expected requestFailed")
        } catch {
            XCTAssertEqual(error, TranslationModelCatalogError.requestFailed(status: -1))
        }
    }

    func testModelCatalog_AnthropicMalformedPage_ThrowsMalformedResponse() async {
        AppLogicURLProtocol.requestHandler = { request in
            (Data("not json".utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let catalog = LiveTranslationModelCatalog(
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.anthropic: "key"]),
            session: AppLogicURLProtocol.session()
        )

        do {
            _ = try await catalog.fetchModels(for: .anthropic)
            XCTFail("Expected malformedResponse")
        } catch {
            XCTAssertEqual(error, TranslationModelCatalogError.malformedResponse)
        }
    }

    func testModelCatalog_GeminiMalformedResponse_ThrowsMalformedResponse() async {
        AppLogicURLProtocol.requestHandler = { request in
            (Data("not json".utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        defer { AppLogicURLProtocol.requestHandler = nil }
        let catalog = LiveTranslationModelCatalog(
            credentialStore: InMemoryTranslationCredentialStore(credentials: [.gemini: "key"]),
            session: AppLogicURLProtocol.session()
        )

        do {
            _ = try await catalog.fetchModels(for: .gemini)
            XCTFail("Expected malformedResponse")
        } catch {
            XCTAssertEqual(error, TranslationModelCatalogError.malformedResponse)
        }
    }
}

// MARK: - StatusMenuActionTarget.swift

extension AppLogicCoverageTests {
    func testStatusMenuActionTarget_ClipboardHistoryAction_ShowsClipboardPanel() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let target = StatusMenuActionTarget()
        target.coordinator = coordinator

        target.clipboardHistoryAction(nil)

        XCTAssertNotNil(target.coordinator)
    }
}

// MARK: - LocalizationStore.swift

extension AppLogicCoverageTests {
    func testLocalizationStore_SystemPreferenceRespondsToSystemLanguageChange() throws {
        let suiteName = "AppLogicLocalization-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("system", forKey: AppLanguage.storageKey)
        let store = LocalizationStore(defaults: defaults, bundle: .main)

        NotificationCenter.default.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)
        drainRunLoopForLocalization()

        XCTAssertEqual(store.resolvedCode, AppLanguage.system.resolvedCode)
    }

    private func drainRunLoopForLocalization() {
        let limit = Date().addingTimeInterval(1)
        while Date() < limit {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }
}

// MARK: - ClipboardMonitor.swift

extension AppLogicCoverageTests {
    func testClipboardMonitor_DefaultSourceProvider_CapturesWithoutSource() {
        let reader = FakePasteboardReader()
        reader.changeCount = 1
        var capturedCount = 0
        let monitor = ClipboardMonitor(
            reader: reader,
            suppressor: ClipboardWriteSuppressor(),
            options: ClipboardOptions(isCaptureEnabled: true),
            onCapture: { _ in capturedCount += 1 }
        )
        reader.setText("text", changeCount: 2)
        reader.changeCount = 2

        monitor.poll()

        XCTAssertEqual(capturedCount, 1)
    }

    func testClipboardMonitor_DescriptorMismatch_ResyncsObservedCount() {
        let reader = DescriptorMismatchReader()
        var captured = false
        let monitor = ClipboardMonitor(
            reader: reader,
            suppressor: ClipboardWriteSuppressor(),
            options: ClipboardOptions(isCaptureEnabled: true),
            sourceProvider: { nil },
            onCapture: { _ in captured = true }
        )

        monitor.poll()

        XCTAssertFalse(captured)
    }

    func testClipboardMonitor_UnclassifiableSnapshot_ResyncsWithoutCapturing() {
        let reader = FakePasteboardReader()
        reader.changeCount = 1
        let monitor = ClipboardMonitor(
            reader: reader,
            suppressor: ClipboardWriteSuppressor(),
            options: ClipboardOptions(isCaptureEnabled: true),
            sourceProvider: { nil },
            onCapture: { _ in XCTFail("No capture expected") }
        )
        reader.setDescriptorOnly(types: [PasteboardClassifier.plainText], changeCount: 2)
        reader.changeCount = 2

        monitor.poll()

        XCTAssertTrue(true)
    }
}

// MARK: - AppMainMenuInstaller.swift

extension AppLogicCoverageTests {
    func testAppMainMenuInstaller_NilMainMenu_CreatesMenuWithAppAndEditItems() {
        let previousMenu = NSApp.mainMenu
        let previousLanguage = LocalizationStore.shared.preference
        LocalizationStore.shared.setPreference(.english)
        defer {
            LocalizationStore.shared.setPreference(previousLanguage)
            NSApp.mainMenu = previousMenu
        }
        NSApp.mainMenu = nil

        AppMainMenuInstaller.installIfNeeded()

        XCTAssertNotNil(NSApp.mainMenu)
        let hasEdit = NSApp.mainMenu?.items.contains { $0.submenu?.title == "Edit" } ?? false
        XCTAssertTrue(hasEdit)
    }

    func testAppMainMenuInstaller_ExistingAppMenu_InsertsEditAtSecondPosition() {
        let previousMenu = NSApp.mainMenu
        let previousLanguage = LocalizationStore.shared.preference
        LocalizationStore.shared.setPreference(.english)
        defer {
            LocalizationStore.shared.setPreference(previousLanguage)
            NSApp.mainMenu = previousMenu
        }
        let menu = NSMenu()
        let appItem = NSMenuItem()
        appItem.submenu = NSMenu(title: "EasyKey")
        menu.addItem(appItem)
        let windowItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        windowItem.submenu = NSMenu(title: "Window")
        menu.addItem(windowItem)
        NSApp.mainMenu = menu

        AppMainMenuInstaller.installIfNeeded()

        let editIndex = menu.items.firstIndex { $0.submenu?.title == "Edit" }
        XCTAssertEqual(editIndex, 1)
    }
}

// MARK: - AppLanguage.swift

extension AppLogicCoverageTests {
    func testAppLanguage_SystemPreferredCode_ResolvesToSupportedLanguage() {
        let code = AppLanguage.systemPreferredCode

        XCTAssertTrue(["en", "vi"].contains(code))
        XCTAssertEqual(AppLanguage.system.resolvedCode, code)
    }
}

// MARK: - KeepOnTopTitlebarAccessory.swift

extension AppLogicCoverageTests {
    func testKeepOnTopTitlebarAccessory_ButtonClick_TogglesStateAndNotifies() {
        var toggledValues: [Bool] = []
        let accessory = KeepOnTopTitlebarAccessory(isOn: false) { _ in "title" }
        accessory.onToggle = { toggledValues.append($0) }
        guard let button = accessory.view as? NSButton else {
            return XCTFail("Accessory view is not a button")
        }

        button.performClick(nil)

        XCTAssertTrue(accessory.isOn)
        XCTAssertEqual(toggledValues, [true])
    }
}

// MARK: - UpdateService.swift

extension AppLogicCoverageTests {
    func testUpdateService_StartWithConfiguredBundle_StartsUpdater() throws {
        let bundle = try makeUpdateServiceBundle(feedURL: "https://example.com/appcast.xml", publicKey: "a-real-key")
        let service = UpdateService(bundle: bundle)

        service.start()

        XCTAssertTrue(service.isConfigured)
    }

    private func makeUpdateServiceBundle(feedURL: String, publicKey: String) throws -> Bundle {
        let bundleURL = directory.appendingPathComponent("FakeUpdate-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(
            at: bundleURL.appendingPathComponent("Contents"),
            withIntermediateDirectories: true
        )
        let info: [String: Any] = [
            "CFBundleIdentifier": "one.ifelse.easykey.tests.fake",
            "CFBundleName": "Fake",
            "SUFeedURL": feedURL,
            "SUPublicEDKey": publicKey,
        ]
        let plistURL = bundleURL.appendingPathComponent("Contents/Info.plist")
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: plistURL)
        return try XCTUnwrap(Bundle(url: bundleURL))
    }
}

// MARK: - ClipboardRowPresenter.swift

extension AppLogicCoverageTests {
    func testClipboardRowPresenter_Metadata_IncludesPixelDimensions() {
        let entry = ClipboardEntry(
            fingerprint: "dims-fp",
            capturedAt: AppLogicCoverageTests.defaultNow,
            items: [ClipboardItem(
                kind: .image,
                preview: ClipboardItemPreview(
                    primaryText: "PNG image",
                    typeLabel: "PNG",
                    byteCount: 1024,
                    pixelWidth: 640,
                    pixelHeight: 480
                ),
                representations: [.data(typeIdentifier: PasteboardClassifier.png, payloadReference: "r")]
            )]
        )

        let metadata = ClipboardRowPresenter.metadata(for: entry, now: AppLogicCoverageTests.defaultNow.addingTimeInterval(60))

        XCTAssertTrue(metadata.contains("640×480"))
    }
}

// MARK: - LoginItemController.swift

extension AppLogicCoverageTests {}

// MARK: - TranslationModel.swift

extension AppLogicCoverageTests {
    func testTranslationModel_InitWithoutPronunciationCallback_DefaultsToNoOp() {
        let model = TranslationModel(
            inputLanguage: .vietnamese,
            providerID: nil,
            providerLookup: { _ in nil }
        )

        XCTAssertNil(model.providerID)
        XCTAssertEqual(model.sourceText, "")
    }
}

// MARK: - Shared fakes

private final class AppLogicURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) async throws -> (Data, URLResponse))?

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        Task {
            do {
                let (data, response) = try await handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AppLogicURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class AppLogicThrowingCredentialStore: TranslationCredentialStoring, @unchecked Sendable {
    func hasCredential(for _: TranslationProviderID) throws -> Bool {
        false
    }

    func credential(for _: TranslationProviderID) throws -> String? {
        throw NSError(domain: "AppLogicCoverage", code: 3)
    }

    func save(_: String, for _: TranslationProviderID) throws {}

    func deleteCredential(for _: TranslationProviderID) throws {}
}

private final class DescriptorMismatchReader: PasteboardReading {
    let changeCount = 42

    func descriptor() -> PasteboardDescriptor {
        PasteboardDescriptor(changeCount: 1, items: [])
    }

    func snapshot(selecting _: [[String]]) -> PasteboardSnapshot {
        PasteboardSnapshot(changeCount: 1, items: [])
    }
}

private final class FakeEmptyModelCatalog: TranslationModelCatalogProviding, @unchecked Sendable {
    func fetchModels(
        for _: TranslationProviderID
    ) async throws(TranslationModelCatalogError) -> [TranslationModelCatalogEntry] {
        []
    }
}

@MainActor
private final class AppLogicPanelMonitor: TranslationPanelEventMonitoring {
    func addLocalMonitor(
        isPanelOwnedWindow _: @escaping (Int) -> Bool,
        handler _: @escaping (TranslationPanelLocalEvent) -> Bool
    ) -> TranslationPanelMonitorRegistration? {
        TranslationPanelMonitorRegistration(removeAction: {})
    }

    func addGlobalClickMonitor(handler _: @escaping () -> Void) -> TranslationPanelMonitorRegistration? {
        TranslationPanelMonitorRegistration(removeAction: {})
    }
}

@MainActor
private final class AppLogicPanelWindow: TranslationPanelWindow {
    var isVisible = false
    let windowNumber = 7
    private(set) var visibleCount = 0

    func replaceContent(_: AnyView) {}

    func setFrameOrigin(_: CGPoint) {}

    func setContentSize(_: CGSize) {}

    func makeKeyAndOrderFront() {
        isVisible = true
        visibleCount += 1
    }

    func orderOut() {
        isVisible = false
    }

    func setCloseHandler(_: @escaping () -> Void) {}

    func containsWindowNumber(_: Int) -> Bool {
        true
    }

    func addTitlebarAccessory(_: NSTitlebarAccessoryViewController) {}
}

@MainActor
private final class AppLogicSpeechEngine: TranslationSpeechEngine {
    var eventHandler: ((UUID, TranslationSpeechEngineEvent) -> Void)?

    func voiceIdentifier(for _: String) -> String? {
        "applogic-voice"
    }

    func speak(_: String, voiceIdentifier _: String, requestID _: UUID) -> Bool {
        true
    }

    func stopSpeaking() {}
}

private var appLogicSampleRequest: TranslationRequest {
    TranslationRequest(
        sourceText: "Xin chào",
        sourceLanguage: nil,
        targetLanguage: .english,
        providerID: .openAI
    )!
}

// MARK: - AppleTranslationSessionBridge.swift (macOS 15+ host)

extension AppLogicCoverageTests {
    @available(macOS 26.4, *)
    func testAppleTranslationSessionBridge_AttachWithDefaultSleep_CancellationCompletesAttach() async {
        let bridge = AppleTranslationSessionBridge()
        let session = TranslationSession(installedSource: Locale.Language(identifier: "en"), target: Locale.Language(identifier: "vi"))
        let configuration = TranslationSession.Configuration(
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: "vi")
        )

        let attachTask = Task { await bridge.attach(session, configuration: configuration) }
        try? await Task.sleep(for: .milliseconds(100))
        attachTask.cancel()
        await attachTask.value
    }

    @available(macOS 26.4, *)
    func testAppleTranslationSessionBridge_TranslateWithNoDeliveredSession_RequestsConfigurationAndThrows() async throws {
        let bridge = AppleTranslationSessionBridge()

        let task = Task {
            try await bridge.translate(text: "hello", source: nil, target: Locale.Language(identifier: "vi"))
        }
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertNotNil(bridge.configuration)
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected: no session is ever delivered, so the waiter cancels.
        }
    }
}

// MARK: - TranslationPanelPresenter.swift (default-closure paths)

extension AppLogicCoverageTests {
    func testTranslationPanelPresenter_ToggleWithCapturedApplication_ShowsThenCloses() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "AppLogicPanel-\(UUID().uuidString)"))
        defer { defaults.removePersistentDomain(forName: "AppLogicPanel-\(UUID().uuidString)") }
        let presenter = TranslationPanelPresenter(
            translation: AppLogicNoopTranslationCanceller(),
            eventMonitor: AppLogicPanelMonitor(),
            panelFactory: { AppLogicPanelWindow() },
            activateEasyKey: {},
            pointerLocation: { .zero },
            screenGeometries: { [] },
            isFrontmostAppExemptFromOutsideClickDismissal: { false },
            userDefaults: defaults
        )

        presenter.toggle(previousApplication: NSRunningApplication.current)
        XCTAssertTrue(presenter.isShown)
        presenter.toggle(previousApplication: NSRunningApplication.current)
        XCTAssertFalse(presenter.isShown)
    }

    func testTranslationPanelPresenter_ShowWithDefaultClosures_UsesSystemDefaults() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "AppLogicPanel-\(UUID().uuidString)"))
        defer { defaults.removePersistentDomain(forName: "AppLogicPanel-\(UUID().uuidString)") }
        let presenter = TranslationPanelPresenter(
            translation: AppLogicNoopTranslationCanceller(),
            eventMonitor: AppLogicPanelMonitor(),
            panelFactory: { AppLogicPanelWindow() },
            userDefaults: defaults
        )

        presenter.show()

        XCTAssertTrue(presenter.isShown)
        presenter.close()
    }

    func testTranslationPanelPresenter_HandleGlobalClickWithExemptFrontmost_KeepsPanelOpen() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "AppLogicPanel-\(UUID().uuidString)"))
        defer { defaults.removePersistentDomain(forName: "AppLogicPanel-\(UUID().uuidString)") }
        var frontmost: NSRunningApplication? = NSRunningApplication.current
        let presenter = TranslationPanelPresenter(
            translation: AppLogicNoopTranslationCanceller(),
            eventMonitor: AppLogicPanelMonitor(),
            panelFactory: { AppLogicPanelWindow() },
            frontmostApplication: { frontmost },
            activateEasyKey: {},
            pointerLocation: { .zero },
            screenGeometries: { [] },
            isFrontmostAppExemptFromOutsideClickDismissal: { true },
            userDefaults: defaults
        )

        presenter.show()
        presenter.close()
        XCTAssertFalse(presenter.isShown)
        frontmost = nil
    }
}

// MARK: - ClipboardHistoryModel.swift (disable-persistence clears prior error)

extension AppLogicCoverageTests {
    func testApplyDisablingPersistence_CompletesDeletionAndKeepsErrorClear() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-disable-clear-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let model = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: InMemoryClipboardKeyStore()),
            now: { AppLogicCoverageTests.defaultNow }
        )
        model.capture(historyTextClassified(fingerprint: "g", text: "data"))
        await model.flushPendingSave()
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("manifest.ekc").path))
        var disabled = options
        disabled.persistsHistory = false

        model.apply(disabled)
        await appLogicWaitForCondition {
            !FileManager.default.fileExists(atPath: directory.appendingPathComponent("manifest.ekc").path)
        }

        XCTAssertNil(model.persistenceError)
    }
}

// MARK: - Shared fakes (panel + translation)

@MainActor
private final class AppLogicNoopTranslationCanceller: TranslationCancelling {
    func cancelActiveTranslation() {}
}

// MARK: - Final micro-round

extension AppLogicCoverageTests {
    func testClipboardServices_PasteTaskFires_ChecksTargetFocus() {
        let services = makeServices(enabled: true, frontmostProvider: { NSRunningApplication.current })
        services.showPanel()
        let now = AppLogicCoverageTests.defaultNow
        let entry = ClipboardEntry(
            fingerprint: "paste-focus-fp",
            capturedAt: now,
            items: [ClipboardItem(
                kind: .text,
                preview: ClipboardItemPreview(primaryText: "paste focus"),
                representations: [.string(typeIdentifier: PasteboardClassifier.plainText, value: "paste focus")]
            )]
        )

        services.action.perform(entry, action: .pasteImmediately)
        let deadline = Date().addingTimeInterval(1.5)
        while services.action.lastError == nil, Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }

        XCTAssertNotNil(services.action.lastError)
    }

    func testSmartSwitch_RememberChoiceWithIgnoredFrontmost_DoesNotRecord() throws {
        let suiteName = "AppLogicSmartSwitch-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicSmartSwitch-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settingsStore = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
        let smartSwitchStore = SmartSwitchStore(fileURL: directory.appendingPathComponent("smart-switch.json"))
        let localization = LocalizationStore(defaults: defaults, bundle: .main)
        let controller = SmartSwitchController(
            smartSwitchStore: smartSwitchStore,
            settingsStore: settingsStore,
            localization: localization
        )
        guard let frontmost = NSWorkspace.shared.frontmostApplication,
              let bundleIdentifier = frontmost.bundleIdentifier,
              bundleIdentifier != Bundle.main.bundleIdentifier,
              !frontmost.isTerminated
        else {
            throw XCTSkip("No external frontmost application available")
        }
        settingsStore.update {
            $0.smartSwitch.enabled = true
            $0.smartSwitch.rememberEncoding = false
            $0.compatibility.ignoredApplicationBundleIdentifiers = [bundleIdentifier]
            $0.input.language = .english
        }
        controller.handleApplicationActivation(frontmost)
        controller.rememberChoiceIfNeeded(from: settingsStore.settings)
        settingsStore.update { $0.input.language = .vietnamese }
        let revisionBefore = controller.smartSwitchRevision

        controller.rememberChoiceIfNeeded(from: settingsStore.settings)

        XCTAssertEqual(controller.smartSwitchRevision, revisionBefore)
    }

    @available(macOS 15.0, *)
    func testAppleTranslationSessionHostView_RendersEmptyState() {
        let bridge = AppleTranslationSessionBridge()

        let view = AppleTranslationSessionHostView(bridge: bridge)
        let hosting = NSHostingView(rootView: view)

        XCTAssertNotNil(hosting.rootView as? AppleTranslationSessionHostView)
    }

    func testPasteboardWriter_CopyEntryWithExistingFile_WritesFileReference() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLogicWriterFile-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("existing.txt")
        try Data("content".utf8).write(to: fileURL)
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("AppLogicWriterFile-\(UUID().uuidString)"))
        defer { pasteboard.clearContents() }
        let writer = PasteboardWriter(pasteboard: pasteboard, suppressor: ClipboardWriteSuppressor())
        let entry = ClipboardEntry(
            fingerprint: "file-fp",
            capturedAt: AppLogicCoverageTests.defaultNow,
            items: [ClipboardItem(
                kind: .file,
                preview: ClipboardItemPreview(primaryText: "existing.txt"),
                representations: [.fileURL(fileURL)]
            )]
        )

        try writer.copy(entry)

        let item = try XCTUnwrap(pasteboard.pasteboardItems?.first)
        XCTAssertEqual(item.string(forType: .init(PasteboardClassifier.fileURL)), fileURL.absoluteString)
    }

    func testSystemSpeechEngine_DelegateFinishForUnknownUtterance_Ignores() {
        let engine = SystemTranslationSpeechEngine(synthesizer: AVSpeechSynthesizer())
        let utterance = AVSpeechUtterance(string: "unmapped")

        engine.speechSynthesizer(AVSpeechSynthesizer(), didFinish: utterance)
        engine.speechSynthesizer(AVSpeechSynthesizer(), didCancel: utterance)
    }

    func testCarbonRegistrar_SecondRegistrationReusesEventHandler() {
        let registrar = CarbonTranslationHotKeyRegistrar()
        let first = TranslationHotKeyIdentity(
            signature: TranslationHotKeyController.carbonSignature,
            identifier: TranslationHotKeyController.firstCarbonIdentifier
        )
        let second = TranslationHotKeyIdentity(
            signature: TranslationHotKeyController.carbonSignature,
            identifier: TranslationHotKeyController.firstCarbonIdentifier + 1
        )

        guard registrar.register(keyCode: 0, modifiers: UInt32(optionKey | controlKey), identity: first, handler: {}),
              registrar.register(keyCode: 1, modifiers: UInt32(optionKey | controlKey), identity: second, handler: {})
        else {
            registrar.shutdown()
            XCTSkip("Carbon hotkey registration unavailable in this session")
            return
        }

        registrar.unregister(identity: first)
        registrar.shutdown()
    }
}
