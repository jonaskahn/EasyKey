import AppKit
import Combine
import EasyEngineCore
import EasyKeyKit
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    typealias LoginItemStatus = LoginItemController.Status

    static let shared = AppCoordinator()

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

    @Published var keyboardHealth: KeyboardService.Health = .stopped
    @Published var keyboardPaused = false
    @Published var currentApplicationName = ""
    @Published var currentAppSmartSwitchStatus = ""
    @Published var loginItemStatus: LoginItemStatus = .disabled
    @Published var selectedSettingsSection: SettingsSection = .typing
    @Published var macroRevision = 0
    @Published var smartSwitchRevision = 0

    var settingsObserver: AnyCancellable?
    var localizationObserver: AnyCancellable?
    var launchAtLoginSetting: Bool?
    var ignoredApplicationsSetting: [String]?
    var clipboardOptionsSetting: ClipboardOptions?
    private(set) var updateWindow: NSWindow?
    private var clipboardStartTask: Task<Void, Never>?

    /// Composition-root initializer. Production uses `AppCoordinator.shared` defaults;
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
        updateService: UpdateService? = nil
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
        clipboard = ClipboardServices(
            options: settingsStore.settings.clipboard,
            applicationSupportDirectory: SettingsStore.defaultFileURL.deletingLastPathComponent(),
            localization: localization
        )
        currentApplicationName = localization.string(.smartSwitchNoActiveApp)
        currentAppSmartSwitchStatus = localization.string(.smartSwitchOff)
        smartSwitchController.onPublishedStateChange = { [weak self] in
            self?.syncSmartSwitchPublishedState()
        }
        configureKeyboardService()
        configureStatusItemController()
        configureWorkspaceObserver()
        clipboard.openSettings = { [weak self] in self?.showSettings(section: .clipboard) }
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
        AppLog.info(.app, "AppCoordinator start")
        statusItemController.bindMenuActions(to: self)
        statusItemController.install(coordinator: self)
        updateStatusItem()
        observeSettings()
        observeLocalizationChanges()
        workspaceObserver.start()
        if !ProcessInfo.processInfo.arguments.contains("--uitesting") {
            updateService.start()
            performStartupUpdateCheck()
        }
        handleApplicationActivation(NSWorkspace.shared.frontmostApplication)
        keyboardService.start()
        clipboardOptionsSetting = settingsStore.settings.clipboard
        clipboardStartTask?.cancel()
        clipboardStartTask = Task { [clipboard] in
            await clipboard.start(loadPersisted: settingsStore.settings.clipboard.persistsHistory)
        }
        if settingsStore.settings.system.showSettingsAtLaunch {
            showSettings()
        }
    }

    func stop() {
        AppLog.info(.app, "AppCoordinator stop")
        settingsObserver?.cancel()
        localizationObserver?.cancel()
        workspaceObserver.stop()
        statusItemController.teardown()
        keyboardService.stop()
        settingsWindowPresenter.close()
        let clipboardStartTask = clipboardStartTask
        self.clipboardStartTask = nil
        clipboardStartTask?.cancel()
        Task { [clipboard] in
            await clipboardStartTask?.value
            await clipboard.stop()
        }
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

    func clearSettingsWindowIfNeeded(_ window: NSWindow) {
        settingsWindowPresenter.clearIfNeeded(window)
    }

    func clearUpdateWindow() {
        updateWindow = nil
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
        Task {
            let result = await GitHubUpdateChecker.shared.checkForUpdates()
            presentUpdateResult(result)
        }
    }

    func performStartupUpdateCheck() {
        guard settingsStore.settings.system.checkForUpdates else { return }
        Task {
            let result = await GitHubUpdateChecker.shared.checkForUpdates()
            guard case .updateAvailable = result else { return }
            presentUpdateResult(result)
        }
    }

    func presentUpdateResult(_ result: UpdateCheckResult) {
        switch result {
        case let .updateAvailable(current, latest, notes, url):
            presentUpdateAvailableWindow(current: current, latest: latest, notes: notes, url: url)
        case let .upToDate(current):
            presentUpToDateWindow(current: current)
        case .failure:
            presentUpdateErrorWindow()
        }
    }

    private func presentUpdateAvailableWindow(current: String, latest: String, notes: String?, url: String) {
        updateWindow?.close()
        updateWindow = nil
        let window = makeUpdateWindow(width: 400, height: 250, title: .updateAvailableTitle)
        window.contentView = NSHostingView(rootView: UpdateAvailableView(
            currentVersion: current,
            latestVersion: latest,
            releaseNotes: notes,
            downloadURL: url,
            onDismiss: { [weak self] in
                self?.closeUpdateWindow()
            },
            onDownload: { [weak self] in
                self?.handleUpdateDownload(url: url)
            }
        ))
        updateWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func presentUpToDateWindow(current: String) {
        updateWindow?.close()
        updateWindow = nil
        let window = makeUpdateWindow(width: 350, height: 150, title: .updateUpToDateTitle)
        window.contentView = NSHostingView(rootView: UpToDateView(
            currentVersion: current,
            onDismiss: { [weak self] in
                self?.closeUpdateWindow()
            }
        ))
        updateWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func presentUpdateErrorWindow() {
        updateWindow?.close()
        updateWindow = nil
        let window = makeUpdateWindow(width: 350, height: 150, title: .updateErrorTitle)
        window.contentView = NSHostingView(rootView: UpdateCheckErrorView(
            onDismiss: { [weak self] in
                self?.closeUpdateWindow()
            }
        ))
        updateWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func closeUpdateWindow() {
        updateWindow?.close()
        updateWindow = nil
    }

    func handleUpdateDownload(url: String) {
        if GitHubUpdateChecker.isTrustedDownloadURL(url),
           let downloadURL = URL(string: url) {
            NSWorkspace.shared.open(downloadURL)
        } else {
            AppLog.error(.update, "Refused to open untrusted download URL")
        }
        closeUpdateWindow()
    }

    private func makeUpdateWindow(width: CGFloat, height: CGFloat, title: L10nKey) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = LocalizationStore.shared.string(title)
        window.isReleasedWhenClosed = false
        UpdateWindowDelegate.shared.coordinator = self
        window.delegate = UpdateWindowDelegate.shared
        return window
    }

    var canCheckForUpdates: Bool {
        true
    }

    func restartKeyboardService() {
        AppLog.info(.app, "Restarting keyboard service paused=\(keyboardPaused)")
        let wasPaused = keyboardPaused
        keyboardService.stop()
        if wasPaused {
            keyboardService.setPaused(false)
        } else {
            keyboardService.refreshPermission()
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
        clipboard.writer.copyConvertedText(converted, preservingHTML: html)
    }

    func refreshMacros() {
        macroStore.changeActiveEncoding(to: settingsStore.settings.input.encoding)
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

final class UpdateWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = UpdateWindowDelegate()

    weak var coordinator: AppCoordinator?

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if coordinator?.updateWindow === window {
            coordinator?.clearUpdateWindow()
        }
    }
}
