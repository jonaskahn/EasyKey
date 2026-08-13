import AppKit
import EasyEngineCore
@testable import EasyKey
import SwiftUI
import UniformTypeIdentifiers
import XCTest

@MainActor
final class ViewRenderingTests: XCTestCase {
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

    func testKeepOnTopTitlebarAccessory_InitWithCoder_ReturnsNilWithoutCrashing() throws {
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
        let accessory = KeepOnTopTitlebarAccessory(coder: unarchiver)
        XCTAssertNil(accessory)
    }

    func testContentView_Renders() {
        render { ContentView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testSettingsShell_Renders() {
        render { SettingsShell(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testTypingSettingsView_Renders() {
        render { TypingSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testClipboardPersistenceRemainsEnabledUntilDisableIsConfirmed() {
        coordinator.settingsStore.update { $0.clipboard.persistsHistory = true }
        let view = ClipboardSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)

        view.persistBinding.wrappedValue = false

        XCTAssertTrue(coordinator.settingsStore.settings.clipboard.persistsHistory)

        view.confirmDisablePersistence()

        XCTAssertFalse(coordinator.settingsStore.settings.clipboard.persistsHistory)
    }

    func testEncodingSettingsView_Renders() {
        render {
            EncodingSettingsView(
                settingsStore: coordinator.settingsStore,
                coordinator: coordinator,
                copyPreviewAction: { _ in }
            )
        }
    }

    func testEncodingSettingsView_CopyPreviewUsesInjectedWriterAndSuppressesMonitor() {
        let suppressor = ClipboardWriteSuppressor()
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("ViewRenderingTests-\(UUID().uuidString)"))
        let writer = PasteboardWriter(pasteboard: pasteboard, suppressor: suppressor)
        var copiedText: String?
        let view = EncodingSettingsView(
            settingsStore: coordinator.settingsStore,
            coordinator: coordinator,
            copyPreviewAction: { text in
                copiedText = text
                XCTAssertTrue(writer.copyText(text))
            }
        )
        _ = view.preview
        view.copyPreview()
        XCTAssertEqual(copiedText, view.preview)
        XCTAssertEqual(pasteboard.string(forType: .string), view.preview)
        XCTAssertTrue(suppressor.shouldSuppress(pasteboard.changeCount))
    }

    func testBehaviorSettingsView_Renders() {
        render { BehaviorSettingsView(settingsStore: coordinator.settingsStore) }
    }

    func testBehaviorSettingsView_AddsUniqueApplicationsToBothLists() throws {
        let firstApp = try makeApplicationBundle(name: "First", bundleIdentifier: "dev.example.First")
        let secondApp = try makeApplicationBundle(name: "Second", bundleIdentifier: "dev.example.Second")
        let invalidURL = tempDirectory.appendingPathComponent("Invalid.txt")
        try Data().write(to: invalidURL)
        let view = BehaviorSettingsView(settingsStore: coordinator.settingsStore)

        view.addApplications(at: [firstApp, firstApp, invalidURL], to: .compatibilityMode)
        view.addApplications(at: [secondApp], to: .ignored)

        let compatibilityIdentifiers = coordinator.settingsStore.settings.compatibility
            .compatibilityModeApplicationBundleIdentifiers
        let ignoredIdentifiers = coordinator.settingsStore.settings.compatibility
            .ignoredApplicationBundleIdentifiers
        XCTAssertEqual(compatibilityIdentifiers.filter { $0 == "dev.example.First" }.count, 1)
        XCTAssertTrue(ignoredIdentifiers.contains("dev.example.Second"))
    }

    func testBehaviorSettingsView_ForgetsApplicationsFromBothLists() {
        coordinator.settingsStore.update {
            $0.compatibility.compatibilityModeApplicationBundleIdentifiers = ["dev.example.First", "dev.example.Keep"]
            $0.compatibility.ignoredApplicationBundleIdentifiers = ["dev.example.Second", "dev.example.Keep"]
        }
        let view = BehaviorSettingsView(settingsStore: coordinator.settingsStore)

        view.forget("dev.example.First", from: .compatibilityMode)
        view.forget("dev.example.Second", from: .ignored)

        XCTAssertEqual(
            coordinator.settingsStore.settings.compatibility.compatibilityModeApplicationBundleIdentifiers,
            ["dev.example.Keep"]
        )
        XCTAssertEqual(
            coordinator.settingsStore.settings.compatibility.ignoredApplicationBundleIdentifiers,
            ["dev.example.Keep"]
        )
    }

    func testBehaviorSettingsView_SettingBindingReadsAndWrites() {
        let view = BehaviorSettingsView(settingsStore: coordinator.settingsStore)
        let binding = view.setting(\.compatibility.otherLanguageSupport)

        XCTAssertFalse(binding.wrappedValue)
        binding.wrappedValue = true

        XCTAssertTrue(coordinator.settingsStore.settings.compatibility.otherLanguageSupport)
    }

    func testBehaviorSettingsView_AppendUniquePreservesOrder() {
        let view = BehaviorSettingsView(settingsStore: coordinator.settingsStore)
        var values = ["first", "second"]

        view.appendUnique(["second", "third", "first", "fourth"], to: &values)

        XCTAssertEqual(values, ["first", "second", "third", "fourth"])
    }

    func testBehaviorSettingsView_RejectsDropWithoutFileProvider() {
        let provider = NSItemProvider(object: "not a file" as NSString)
        let view = BehaviorSettingsView(settingsStore: coordinator.settingsStore)

        XCTAssertFalse(view.acceptDrop([provider], into: .ignored))
    }

    func testBehaviorSettingsView_AcceptsFileURLDrop() throws {
        let appURL = try makeApplicationBundle(name: "Dropped", bundleIdentifier: "dev.example.Dropped")
        let dataAppURL = try makeApplicationBundle(name: "DataDropped", bundleIdentifier: "dev.example.DataDropped")
        let urlProvider = NSItemProvider(
            item: appURL as NSURL,
            typeIdentifier: UTType.fileURL.identifier
        )
        let dataProvider = NSItemProvider(
            item: dataAppURL.dataRepresentation as NSData,
            typeIdentifier: UTType.fileURL.identifier
        )
        let view = BehaviorSettingsView(settingsStore: coordinator.settingsStore)
        let added = expectation(description: "Dropped applications added")

        XCTAssertTrue(view.acceptDrop([urlProvider, dataProvider], into: .ignored))
        waitUntil(timeout: 2) {
            let identifiers = coordinator.settingsStore.settings.compatibility.ignoredApplicationBundleIdentifiers
            if identifiers.contains("dev.example.Dropped"), identifiers.contains("dev.example.DataDropped") {
                added.fulfill()
                return true
            }
            return false
        }
        wait(for: [added], timeout: 0.1)
    }

    func testMacroSettingsView_Renders() {
        render { MacroSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testMacroEditorSheet_NewMacro_Renders() {
        render { MacroEditorSheet(macro: nil, coordinator: coordinator) }
    }

    func testMacroEditorSheet_ExistingMacro_Renders() {
        let macro = Macro(trigger: "abc", expansion: "xyz")
        render { MacroEditorSheet(macro: macro, coordinator: coordinator) }
    }

    func testSmartSwitchSettingsView_Renders() {
        render { SmartSwitchSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testSystemSettingsView_Renders() {
        render { SystemSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testSystemHealthCard_Renders() {
        render { SystemHealthCard(coordinator: coordinator) }
    }

    func testAboutSettingsView_Renders() {
        render { AboutSettingsView(settingsStore: coordinator.settingsStore) }
    }

    func testThirdPartyNoticesSheet_Renders() {
        render { ThirdPartyNoticesSheet() }
    }

    func testOnboardingView_Renders() {
        render { OnboardingView(settingsStore: coordinator.settingsStore, coordinator: coordinator, finish: {}) }
    }

    func testOnboardingView_AtStep1_ShowsBackButton() {
        render {
            OnboardingView(
                settingsStore: coordinator.settingsStore,
                coordinator: coordinator,
                finish: {},
                initialStep: 1
            )
        }
    }

    func testOnboardingView_AtStep3_ShowsFinishLabel() {
        render {
            OnboardingView(
                settingsStore: coordinator.settingsStore,
                coordinator: coordinator,
                finish: {},
                initialStep: 3
            )
        }
    }

    func testOnboardingStep_Accessibility_Renders() {
        coordinator.keyboardHealth = .requestingPermission
        render {
            OnboardingStepContent(step: 1, coordinator: coordinator, settingsStore: coordinator.settingsStore)
        }
    }

    func testOnboardingStep_Accessibility_AlreadyActive_Renders() {
        coordinator.keyboardHealth = .active
        render {
            OnboardingStepContent(step: 1, coordinator: coordinator, settingsStore: coordinator.settingsStore)
        }
    }

    func testOnboardingStep_TypingMethod_Renders() {
        render {
            OnboardingStepContent(step: 2, coordinator: coordinator, settingsStore: coordinator.settingsStore)
        }
    }

    func testOnboardingStep_Ready_Renders() {
        render {
            OnboardingStepContent(step: 3, coordinator: coordinator, settingsStore: coordinator.settingsStore)
        }
    }

    func testMenuPopoverView_Renders() {
        render { MenuPopoverView(coordinator: coordinator) }
    }

    func testMenuPopoverView_TranslationRendersEnglishVietnameseAndAccessibilityText() throws {
        let suite = "one.ifelse.easykey.menu-popover-render.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let localization = LocalizationStore(defaults: defaults, bundle: .main)
        let model = TranslationModel(
            inputLanguage: .english,
            providerID: .deepL,
            providerLookup: { _ in nil }
        )
        model.setSourceText(String(repeating: "Long source text ", count: 80))
        let translation = MenuPopoverTranslationConfiguration(
            model: model,
            availableProviders: [.deepL],
            platformCapability: .init(supportsAppleTranslation: false),
            actions: .init(openSettings: {}, announceResult: { _ in })
        )

        for language in [AppLanguage.english, .vietnamese] {
            localization.setPreference(language)
            render {
                MenuPopoverView(
                    coordinator: coordinator,
                    translation: translation,
                    localization: localization
                )
                .environment(\.dynamicTypeSize, .accessibility2)
            }
        }
    }

    func testMenuPopoverInputBindingsAndFooterActionsRemainFunctional() {
        var footerEvents: [String] = []
        let view = MenuPopoverView(
            coordinator: coordinator,
            actions: MenuPopoverActions(
                openClipboard: { footerEvents.append("clipboard") },
                openSettings: { footerEvents.append("settings") },
                quit: { footerEvents.append("quit") }
            )
        )

        view.languageBinding.wrappedValue = .english
        view.inputMethodBinding.wrappedValue = .vni
        view.encodingBinding.wrappedValue = .tcvn3
        view.actions.openClipboard()
        view.actions.openSettings()
        view.actions.quit()

        XCTAssertEqual(coordinator.settingsStore.settings.input.language, .english)
        XCTAssertEqual(coordinator.settingsStore.settings.input.inputMethod, .vni)
        XCTAssertEqual(coordinator.settingsStore.settings.input.encoding, .tcvn3)
        XCTAssertEqual(footerEvents, ["clipboard", "settings", "quit"])
    }

    func testMenuPopoverUsesConfiguredWidth() {
        for width in SystemOptions.MenuPopoverWidth.allCases {
            coordinator.settingsStore.update { $0.system.menuPopoverWidth = width }

            let host = NSHostingView(rootView: MenuPopoverView(coordinator: coordinator))

            XCTAssertEqual(host.fittingSize.width, CGFloat(width.rawValue), accuracy: 0.5)
        }
    }

    func testMenuPopoverWidthDoesNotDependOnTranslationVisibility() {
        coordinator.settingsStore.update { $0.system.menuPopoverWidth = .small }
        let model = TranslationModel(
            inputLanguage: .english,
            providerID: .deepL,
            providerLookup: { _ in nil }
        )
        let translation = MenuPopoverTranslationConfiguration(
            model: model,
            availableProviders: [.deepL],
            platformCapability: .init(supportsAppleTranslation: false),
            actions: .init(openSettings: {}, announceResult: { _ in })
        )

        let host = NSHostingView(rootView: MenuPopoverView(coordinator: coordinator, translation: translation))

        XCTAssertEqual(host.fittingSize.width, 360, accuracy: 0.5)
    }

    func testTranslationEditorsStackAtSmallAndMediumWidths() {
        XCTAssertFalse(MenuPopoverTranslationLayout.usesSideBySideEditors(width: 280, accessibilityText: false))
        XCTAssertFalse(MenuPopoverTranslationLayout.usesSideBySideEditors(width: 360, accessibilityText: false))
        XCTAssertFalse(MenuPopoverTranslationLayout.usesSideBySideEditors(width: 440, accessibilityText: false))
        XCTAssertFalse(MenuPopoverTranslationLayout.usesSideBySideEditors(width: 520, accessibilityText: false))
    }

    func testTranslationEditorsUseSideBySideLayoutAtExtraLargeWidth() {
        XCTAssertTrue(MenuPopoverTranslationLayout.usesSideBySideEditors(width: 640, accessibilityText: false))
    }

    func testTranslationEditorsStackAtAccessibilityTextSizes() {
        XCTAssertFalse(MenuPopoverTranslationLayout.usesSideBySideEditors(width: 640, accessibilityText: true))
    }

    func testInterfaceLanguagePicker_Renders() {
        render { InterfaceLanguagePicker() }
    }

    func testShortcutRecorder_Renders() {
        render {
            ShortcutRecorder(label: "Test", shortcut: .constant(.none))
        }
    }

    func testHealthPill_ActiveNotPaused_Renders() {
        render { HealthPill(health: .active, paused: false) }
    }

    func testHealthPill_PermissionPaused_Renders() {
        render { HealthPill(health: .requestingPermission, paused: true) }
    }

    func testApplicationBundleSelection_ValidatesApplicationBundle() throws {
        let appURL = try makeApplicationBundle(name: "Example", bundleIdentifier: "dev.example.Application")
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)

        XCTAssertEqual(
            ApplicationBundleSelection.bundleIdentifier(at: appURL),
            "dev.example.Application"
        )
        XCTAssertNil(ApplicationBundleSelection.bundleIdentifier(at: contentsURL.appendingPathComponent("Info.plist")))
    }

    func testSystemHealthCard_RequestingPermission_Renders() {
        coordinator.keyboardHealth = .requestingPermission
        render { SystemHealthCard(coordinator: coordinator) }
    }

    func testSystemHealthCard_Degraded_Renders() {
        coordinator.keyboardHealth = .degraded
        render { SystemHealthCard(coordinator: coordinator) }
    }

    func testSystemHealthCard_Failed_Renders() {
        coordinator.keyboardHealth = .failed
        render { SystemHealthCard(coordinator: coordinator) }
    }

    func testSystemHealthCard_Active_Renders() {
        coordinator.keyboardHealth = .active
        render { SystemHealthCard(coordinator: coordinator) }
    }

    func testSystemHealthCard_Paused_Renders() {
        coordinator.keyboardPaused = true
        render { SystemHealthCard(coordinator: coordinator) }
    }

    func testMacroSettingsView_WithMacros_Renders() throws {
        _ = try coordinator.macroStore.add(trigger: "btw", expansion: "by the way", isEnabled: true)
        coordinator.refreshMacros()
        render { MacroSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testMacroSettingsView_EnabledBindingUpdatesMacro() throws {
        let macro = try coordinator.macroStore.add(trigger: "btw", expansion: "by the way", isEnabled: true)
        let view = MacroSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)

        view.enabledBinding(for: macro).wrappedValue = false

        XCTAssertFalse(try XCTUnwrap(coordinator.macroStore.macros.first { $0.id == macro.id }).isEnabled)
    }

    func testMacroEditorSheet_SaveEmptyTrigger_SetsError() {
        let view = MacroEditorSheet(macro: nil, coordinator: coordinator)
        view.save()
    }

    func testSmartSwitchSettingsView_WithPreferences_Renders() throws {
        let choice = SmartSwitchChoice(language: .vietnamese, encoding: .unicode)
        let identity = ApplicationIdentity(
            bundleIdentifier: "com.example.FakeApp-\(UUID().uuidString)",
            path: nil,
            name: "FakeApp"
        )
        _ = try coordinator.smartSwitchController.store.handleAppFocus(identity, currentChoice: choice)
        render { SmartSwitchSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testSettingsShell_SelectionDrivesAllSections() {
        let host = NSHostingView(
            rootView: AnyView(
                SettingsShell(settingsStore: coordinator.settingsStore, coordinator: coordinator)
            )
        )
        host.frame = NSRect(x: 0, y: 0, width: 900, height: 620)
        host.layoutSubtreeIfNeeded()

        for section in SettingsSection.allCases {
            coordinator.selectedSettingsSection = section
            host.layoutSubtreeIfNeeded()
            XCTAssertEqual(coordinator.selectedSettingsSection, section)
        }
    }

    private func makeApplicationBundle(name: String, bundleIdentifier: String) throws -> URL {
        let appURL = tempDirectory.appendingPathComponent("\(name).app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundlePackageType": "APPL",
            "CFBundleExecutable": name,
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contentsURL.appendingPathComponent("Info.plist"))
        let executableURL = contentsURL.appendingPathComponent("MacOS/\(name)")
        try FileManager.default.createDirectory(
            at: executableURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: executableURL)
        return appURL
    }

    func testTranslationProviderIcon_RendersAllProviders() {
        let providers: [TranslationProviderID] = [
            .automatic, .apple, .deepL, .google, .openAI, .anthropic, .gemini,
            .openRouter, .groq, .openAICompatible, .anthropicCompatible,
        ]
        for provider in providers {
            render { TranslationProviderIcon(provider: provider, size: 20) }
        }
    }

    func testClipboardSettingsView_BindingsAndActionsUpdateSettings() {
        coordinator.settingsStore.update {
            $0.clipboard.capturedKinds = [.text]
            $0.clipboard.ignoredApplicationBundleIdentifiers = ["dev.example.Ignore"]
        }
        let view = ClipboardSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)

        view.persistBinding.wrappedValue = false
        XCTAssertFalse(coordinator.settingsStore.settings.clipboard.persistsHistory)

        view.persistBinding.wrappedValue = true
        XCTAssertTrue(coordinator.settingsStore.settings.clipboard.persistsHistory)

        view.confirmDisablePersistence()
        XCTAssertFalse(coordinator.settingsStore.settings.clipboard.persistsHistory)

        XCTAssertTrue(coordinator.settingsStore.settings.clipboard.capturedKinds.contains(.text))
    }

    func testTranslationSettingsView_RendersWithAllCloudProvidersVisible() {
        let model = TranslationSettingsModel(
            settingsStore: coordinator.settingsStore,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
            credentialStore: InMemoryTranslationCredentialStore()
        )
        render { TranslationSettingsView(model: model) }
    }

    func testTranslationSettingsView_RendersWithAppleProviderVisible() {
        let model = TranslationSettingsModel(
            settingsStore: coordinator.settingsStore,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: true),
            credentialStore: InMemoryTranslationCredentialStore()
        )
        render { TranslationSettingsView(model: model) }
    }

    func testMacroSettingsView_WithNoMacros_Renders() {
        render { MacroSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testSystemSettingsView_RendersWithHealthStates() {
        coordinator.keyboardHealth = .degraded
        render { SystemSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
        coordinator.keyboardHealth = .failed
        render { SystemSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testBehaviorSettingsView_RendersWithApplications() {
        coordinator.settingsStore.update {
            $0.compatibility.compatibilityModeApplicationBundleIdentifiers = ["dev.example.App"]
            $0.compatibility.ignoredApplicationBundleIdentifiers = ["dev.example.Ignore"]
        }
        render { BehaviorSettingsView(settingsStore: coordinator.settingsStore) }
    }

    func testMenuPopoverView_RendersWithPausedKeyboard() {
        coordinator.keyboardPaused = true
        coordinator.keyboardHealth = .active
        render { MenuPopoverView(coordinator: coordinator) }
    }

    func testMenuPopoverView_RendersWithDegradedHealth() {
        coordinator.keyboardHealth = .degraded
        render { MenuPopoverView(coordinator: coordinator) }
    }

    func testMenuPopoverView_RendersWithFailedHealth() {
        coordinator.keyboardHealth = .failed
        render { MenuPopoverView(coordinator: coordinator) }
    }

    func testTranslationPanelView_RendersWithIdleModel() {
        let model = TranslationModel(
            inputLanguage: .english,
            providerID: .deepL,
            providerLookup: { _ in nil }
        )
        let view = TranslationPanelView(
            model: model,
            speech: TranslationSpeechController(),
            localization: LocalizationStore.shared,
            availableProviders: [.deepL],
            shortcut: .none,
            actions: TranslationPanelActions(openSettings: {})
        )
        render { view }
    }

    func testTranslationPanelView_RendersWithTranslatingModel() {
        let model = TranslationModel(
            inputLanguage: .english,
            providerID: .deepL,
            providerLookup: { _ in nil }
        )
        model.setSourceText("hello")
        let view = TranslationPanelView(
            model: model,
            speech: TranslationSpeechController(),
            localization: LocalizationStore.shared,
            availableProviders: [.deepL],
            shortcut: .none,
            actions: TranslationPanelActions(openSettings: {})
        )
        render { view }
    }

    func testMenuPopoverTranslationView_RendersWithModel() {
        let model = TranslationModel(
            inputLanguage: .english,
            providerID: .deepL,
            providerLookup: { _ in nil }
        )
        let configuration = MenuPopoverTranslationConfiguration(
            model: model,
            availableProviders: [.deepL],
            platformCapability: .init(supportsAppleTranslation: false),
            actions: .init(openSettings: {}, announceResult: { _ in })
        )
        render {
            MenuPopoverTranslationView(
                model: configuration.model,
                availableProviders: configuration.availableProviders,
                localization: LocalizationStore.shared,
                actions: configuration.actions,
                width: 360
            )
        }
    }

    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01)), Date() < deadline {}
    }
}
