import AppKit
import Combine
import EasyEngineCore
import EasyKeyKit

/// Lifecycle seam for the clipboard feature so `AppCoordinator` can serialize
/// rapid start/stop sequences in tests with a controllable fake.
@MainActor
protocol ClipboardLifecycleManaging: AnyObject {
    func start(loadPersisted: Bool) async
    func stop() async
}

extension ClipboardServices: ClipboardLifecycleManaging {}

@MainActor
final class AppCoordinator: ObservableObject {
    typealias LoginItemStatus = LoginItemController.Status

    static func makeDefault() -> AppCoordinator {
        guard ProcessInfo.processInfo.arguments.contains("--uitesting") else {
            return AppCoordinator()
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EasyKeyUITests-\(ProcessInfo.processInfo.processIdentifier)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let settingsStore = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
        let localization = LocalizationStore.shared
        var translationDependencies = AppTranslationRuntime.Dependencies.production
        translationDependencies.credentialStore = InMemoryTranslationCredentialStore()
        let clipboard = ClipboardServices(
            options: settingsStore.settings.clipboard,
            applicationSupportDirectory: directory,
            localization: localization,
            keyProvider: InMemoryClipboardKeyStore()
        )
        return AppCoordinator(
            settingsStore: settingsStore,
            localization: localization,
            macroStore: MacroStore(
                fileURL: directory.appendingPathComponent("macros.json"),
                activeEncoding: settingsStore.settings.input.encoding
            ),
            smartSwitchStore: SmartSwitchStore(fileURL: directory.appendingPathComponent("smart-switch.json")),
            clipboardServices: clipboard,
            translationDependencies: translationDependencies
        )
    }

    let settingsStore: SettingsStore
    let keyboardService: KeyboardService
    let macroStore: MacroStore
    let localization: LocalizationStore
    let statusItemController: StatusItemController
    let settingsWindowPresenter: SettingsWindowPresenter
    let loginItemController: LoginItemController
    let workspaceObserver: WorkspaceObserver
    let smartSwitchController: SmartSwitchController
    let updateService: UpdateService
    let clipboard: ClipboardServices
    let translation: AppTranslationRuntime

    @Published var keyboardHealth: KeyboardService.Health = .stopped
    @Published var keyboardPaused = false
    @Published var currentApplicationName = ""
    @Published var currentAppSmartSwitchStatus = ""
    @Published var loginItemStatus: LoginItemStatus = .disabled
    @Published var selectedSettingsSection: SettingsSection = .typing
    @Published var macroRevision = 0
    @Published var smartSwitchRevision = 0
    @Published private(set) var systemHealthNavigationRevision = 0

    var settingsObserver: AnyCancellable?
    var localizationObserver: AnyCancellable?
    var launchAtLoginSetting: Bool?
    var ignoredApplicationsSetting: [String]?
    var clipboardOptionsSetting: ClipboardOptions?
    private let clipboardLifecycle: ClipboardLifecycleManaging
    private var clipboardStartTask: Task<Void, Never>?
    private var stopTask: Task<Void, Never>?

    /// Composition-root initializer. Production uses `AppCoordinator.makeDefault()`;
    /// tests may inject stores and collaborators.
    init(
        settingsStore: SettingsStore? = nil,
        localization: LocalizationStore? = nil,
        keyboardService: KeyboardService? = nil,
        macroStore: MacroStore? = nil,
        smartSwitchStore: SmartSwitchStore? = nil,
        statusItemController: StatusItemController? = nil,
        settingsWindowPresenter: SettingsWindowPresenter? = nil,
        loginItemController: LoginItemController? = nil,
        workspaceObserver: WorkspaceObserver? = nil,
        updateService: UpdateService? = nil,
        clipboardServices: ClipboardServices? = nil,
        translationDependencies: AppTranslationRuntime.Dependencies? = nil,
        clipboardLifecycle: ClipboardLifecycleManaging? = nil
    ) {
        let settingsStore = settingsStore ?? SettingsStore()
        let localization = localization ?? .shared
        self.settingsStore = settingsStore
        self.localization = localization
        self.keyboardService = keyboardService ?? KeyboardService(settings: settingsStore.settings)
        self.macroStore = macroStore ?? MacroStore(
            fileURL: SettingsStore.defaultFileURL
                .deletingLastPathComponent()
                .appendingPathComponent("macros.json"),
            activeEncoding: settingsStore.settings.input.encoding
        )
        let resolvedSmartSwitchStore = smartSwitchStore ?? SmartSwitchStore(
            fileURL: SettingsStore.defaultFileURL
                .deletingLastPathComponent()
                .appendingPathComponent("smart-switch.json")
        )
        smartSwitchController = SmartSwitchController(
            smartSwitchStore: resolvedSmartSwitchStore,
            settingsStore: settingsStore,
            localization: localization
        )
        self.statusItemController = statusItemController ?? StatusItemController(localization: localization)
        self.settingsWindowPresenter = settingsWindowPresenter ?? SettingsWindowPresenter(localization: localization)
        self.loginItemController = loginItemController ?? LoginItemController()
        self.workspaceObserver = workspaceObserver ?? WorkspaceObserver()
        self.updateService = updateService ?? UpdateService()
        translation = AppTranslationRuntime(
            settingsStore: settingsStore,
            localization: localization,
            dependencies: translationDependencies ?? .production
        )
        clipboard = clipboardServices ?? ClipboardServices(
            options: settingsStore.settings.clipboard,
            applicationSupportDirectory: SettingsStore.defaultFileURL.deletingLastPathComponent(),
            localization: localization
        )
        self.clipboardLifecycle = clipboardLifecycle ?? clipboard
        currentApplicationName = localization.string(.smartSwitchNoActiveApp)
        currentAppSmartSwitchStatus = localization.string(.smartSwitchOff)
        configureKeyboardService()
        configureStatusItemController()
        configureWorkspaceObserver()
        self.keyboardService.update(macros: self.macroStore.macros)
        wireCollaboratorCallbacks()
    }

    private func wireCollaboratorCallbacks() {
        smartSwitchController.onPublishedStateChange = { [weak self] in
            self?.syncSmartSwitchPublishedState()
        }
        clipboard.openSettings = { [weak self] in self?.showSettings(section: .clipboard) }
        clipboard.onWillActivate = { [weak self] in self?.statusItemController.closePopover() }
        translation.onOpenSettings = { [weak self] in self?.showSettings(section: .translation) }
        translation.onWillActivate = { [weak self] in self?.statusItemController.closePopover() }
        translation.onConfigurationChange = { [weak self] in
            guard let self else { return }
            self.statusItemController.refreshPopoverContent(coordinator: self)
        }
        translation.onDoubleCmdCChange = { [weak self] windowMs, enabled in
            guard let self else { return }
            if enabled {
                self.keyboardService.setCmdCDoublePressHandler(windowMs: windowMs) { [weak self] in
                    self?.translation.activateFromDoubleCmdC()
                }
            } else {
                self.keyboardService.clearCmdCDoublePressHandler()
            }
        }
        translation.settingsModel.onCmdCDoublePressChanged = { [weak self] in
            guard let self else { return }
            let options = self.settingsStore.settings.translation
            let enabled = options.isEnabled && options.cmdCDoublePressEnabled
            if enabled {
                self.keyboardService.setCmdCDoublePressHandler(windowMs: options.cmdCDoublePressWindowMs) { [weak self] in
                    self?.translation.activateFromDoubleCmdC()
                }
            } else {
                self.keyboardService.clearCmdCDoublePressHandler()
            }
        }
    }

    func showClipboardPanel() {
        clipboard.showPanel()
    }

    func clipboardClearUnpinned() {
        clipboard.model.clearUnpinned()
    }

    func clipboardClearAll() async {
        await clipboard.model.clearAll()
    }

    /// Test seam: `otherProcessIdentifiers` is injected so tests can stub the
    /// running-applications query without spawning a second process.
    static func isOnlyInstanceForCurrentUser(
        otherProcessIdentifiers: (String) -> [pid_t] = { bundleIdentifier in
            NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).map(\.processIdentifier)
        }
    ) -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return true }
        let processIdentifier = ProcessInfo.processInfo.processIdentifier
        return !otherProcessIdentifiers(bundleIdentifier).contains { $0 != processIdentifier }
    }

    func start() {
        let previousStop = stopTask
        previousStop?.cancel()
        stopTask = nil
        guard settingsObserver == nil else { return }
        AppLog.info(.app, "AppCoordinator start")
        statusItemController.bindMenuActions(to: self)
        statusItemController.install(coordinator: self)
        updateStatusItem()
        observeSettings()
        observeLocalizationChanges()
        workspaceObserver.start()
        if !ProcessInfo.processInfo.arguments.contains("--uitesting") {
            updateService.start()
        }
        handleApplicationActivation(NSWorkspace.shared.frontmostApplication)
        keyboardService.start()
        translation.start()
        clipboardOptionsSetting = settingsStore.settings.clipboard
        let previousStartTask = clipboardStartTask
        let lifecycle = clipboardLifecycle
        clipboardStartTask = Task { [settingsStore, lifecycle] in
            _ = await previousStartTask?.value
            _ = await previousStop?.value
            guard !Task.isCancelled else { return }
            await lifecycle.start(loadPersisted: settingsStore.settings.clipboard.persistsHistory)
        }
        if settingsStore.settings.system.showSettingsAtLaunch {
            showSettings()
        }
    }

    func stop() {
        AppLog.info(.app, "AppCoordinator stop")
        settingsObserver?.cancel()
        settingsObserver = nil
        localizationObserver?.cancel()
        localizationObserver = nil
        workspaceObserver.stop()
        statusItemController.teardown()
        keyboardService.stop()
        translation.stop()
        settingsWindowPresenter.close()
        let previousStartTask = clipboardStartTask
        clipboardStartTask = nil
        previousStartTask?.cancel()
        let previousStop = stopTask
        let lifecycle = clipboardLifecycle
        stopTask = Task { [settingsStore, lifecycle] in
            _ = await previousStartTask?.value
            _ = await previousStop?.value
            guard !Task.isCancelled else { return }
            await lifecycle.stop()
            await settingsStore.saveNow()
        }
        previousStop?.cancel()
    }

    func awaitShutdown() async {
        await stopTask?.value
    }

    func showLogs() {
        LogExporter.exportAndReveal()
    }

    func showSettings(section: SettingsSection? = nil) {
        if let section {
            selectedSettingsSection = section
        }
        // Closing a transient popover and ordering a window in the same
        // event turn races AppKit (`_NSPopoverCloseAllPopoversRootedAtWindow`).
        // Tear the popover down first, then present on the next run-loop pass.
        if statusItemController.isPopoverShown {
            statusItemController.closePopover()
            DispatchQueue.main.async { [weak self] in
                self?.presentSettingsWindow()
            }
            return
        }
        presentSettingsWindow()
    }

    func showSettingsFromPopover(section preferredSection: SettingsSection? = nil) {
        if keyboardHealth == .requestingPermission {
            systemHealthNavigationRevision &+= 1
            showSettings(section: .system)
        } else {
            showSettings(section: preferredSection)
        }
    }

    func requestAccessibilityPermission() {
        keyboardService.requestAccessibilityPermission()
    }

    func setLanguage(_ language: InputLanguage) {
        settingsStore.update { $0.input.language = language }
    }

    func setInputMethod(_ inputMethod: InputMethod) {
        settingsStore.update { $0.input.inputMethod = inputMethod }
    }

    func setEncoding(_ encoding: EncodingTable) {
        settingsStore.update { $0.input.encoding = encoding }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        settingsStore.update { $0.system.launchAtLogin = enabled }
    }

    func checkForUpdates() {
        updateService.checkForUpdates()
    }

    var canCheckForUpdates: Bool {
        updateService.isConfigured
    }

    func restartKeyboardService() {
        AppLog.info(.app, "Restarting keyboard service paused=\(keyboardPaused)")
        let wasPaused = keyboardPaused
        keyboardService.stop()
        if wasPaused {
            keyboardService.setPaused(false)
        } else {
            keyboardService.start()
        }
    }

    func convertClipboard() {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string) else {
            AppLog.debug(.app, "Clipboard convert skipped: no string content")
            return
        }
        let settings = settingsStore.settings.converter
        let converted = Converter.preview(
            input: text,
            configuration: ConverterConfiguration(
                sourceEncoding: settings.sourceEncoding,
                destinationEncoding: settings.destinationEncoding
            )
        )
        let html = pasteboard.data(forType: .html)
        _ = clipboard.writer.copyConvertedText(converted, preservingHTML: html)
    }

    func refreshMacros() {
        macroStore.changeActiveEncoding(to: settingsStore.settings.input.encoding)
        keyboardService.update(macros: macroStore.macros)
        macroRevision &+= 1
    }

    var smartSwitchPreferences: [SmartSwitchPreference] {
        smartSwitchController.preferences
    }

    func resetSmartSwitchPreference(_ preference: SmartSwitchPreference) {
        smartSwitchController.resetPreference(preference)
    }

    func clearSmartSwitchPreferences() {
        smartSwitchController.clearPreferences()
    }

    var menuBarStateTitle: String {
        statusItemController.menuBarStateTitle(
            for: settingsStore.settings.input.language,
            keyboardHealth: keyboardHealth,
            keyboardPaused: keyboardPaused
        )
    }
}
