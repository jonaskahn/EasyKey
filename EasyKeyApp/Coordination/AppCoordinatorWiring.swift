import AppKit
import Combine
import EasyEngineCore
import EasyKeyKit

@MainActor
extension AppCoordinator {
    func presentSettingsWindow() {
        settingsWindowPresenter.present(settingsStore: settingsStore, coordinator: self)
    }

    func configureStatusItemController() {
        statusItemController.onLeftClick = { [weak self] in
            self?.togglePopover()
        }
        statusItemController.onAppearanceChange = { [weak self] in
            self?.updateStatusItem()
        }
        statusItemController.menuSnapshotProvider = { [weak self] in
            guard let self else {
                return .init(
                    language: .vietnamese,
                    inputMethod: .telex,
                    encoding: .unicode,
                    currentApplicationName: "",
                    currentAppSmartSwitchStatus: "",
                    keyboardPaused: false
                )
            }
            let settings = settingsStore.settings
            return .init(
                language: settings.input.language,
                inputMethod: settings.input.inputMethod,
                encoding: settings.input.encoding,
                currentApplicationName: currentApplicationName,
                currentAppSmartSwitchStatus: currentAppSmartSwitchStatus,
                keyboardPaused: keyboardPaused
            )
        }
    }

    func configureWorkspaceObserver() {
        workspaceObserver.onApplicationActivated = { [weak self] application in
            self?.handleApplicationActivation(application)
            self?.keyboardService.refreshPermission()
        }
        workspaceObserver.onResetSession = { [weak self] in
            self?.keyboardService.resetSession()
        }
        workspaceObserver.onWake = { [weak self] in
            self?.keyboardService.resetSession()
            self?.keyboardService.refreshPermission()
        }
    }

    func observeLocalizationChanges() {
        localizationObserver = localization.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.refreshLocalizedChrome()
                }
            }
    }

    func refreshLocalizedChrome() {
        settingsWindowPresenter.refreshTitle()
        handleApplicationActivation(NSWorkspace.shared.frontmostApplication)
        updateStatusItem()
        statusItemController.refreshPopoverContent(coordinator: self)
    }

    func togglePopover() {
        statusItemController.togglePopover {
            self.keyboardService.refreshPermission()
        }
    }

    func configureKeyboardService() {
        keyboardService.healthHandler = { [weak self] health in
            self?.keyboardHealth = health
            self?.updateStatusItem()
        }
        keyboardService.pauseHandler = { [weak self] paused in
            self?.keyboardPaused = paused
            self?.updateStatusItem()
        }
        keyboardService.languageToggleHandler = { [weak self] language in
            self?.setLanguage(language)
        }
    }

    func observeSettings() {
        settingsObserver = settingsStore.$settings.sink { [weak self] settings in
            guard let self else { return }
            keyboardService.update(settings: settings)
            macroStore.changeActiveEncoding(to: settings.input.encoding)
            updateDockVisibility(showDockIcon: settings.system.showDockIcon)
            updateStatusItem(settings: settings)
            if launchAtLoginSetting != settings.system.launchAtLogin {
                launchAtLoginSetting = settings.system.launchAtLogin
                configureLaunchAtLogin(enabled: settings.system.launchAtLogin)
            }
            smartSwitchController.rememberChoiceIfNeeded(from: settings)
            if ignoredApplicationsSetting != settings.compatibility.ignoredApplicationBundleIdentifiers {
                ignoredApplicationsSetting = settings.compatibility.ignoredApplicationBundleIdentifiers
                smartSwitchController.handleApplicationActivation(NSWorkspace.shared.frontmostApplication)
            }
        }
    }

    func handleApplicationActivation(_ application: NSRunningApplication?) {
        keyboardService.setActiveApplication(application?.bundleIdentifier)
        smartSwitchController.handleApplicationActivation(application)
    }

    func syncSmartSwitchPublishedState() {
        currentApplicationName = smartSwitchController.currentApplicationName
        currentAppSmartSwitchStatus = smartSwitchController.currentAppSmartSwitchStatus
        smartSwitchRevision = smartSwitchController.smartSwitchRevision
    }

    func updateDockVisibility(showDockIcon: Bool) {
        let desiredPolicy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        guard NSApp.activationPolicy() != desiredPolicy else { return }
        NSApp.setActivationPolicy(desiredPolicy)
    }

    func configureLaunchAtLogin(enabled: Bool) {
        loginItemController.configure(enabled: enabled)
        loginItemStatus = loginItemController.status
    }

    func updateStatusItem(settings: EasyKeySettings? = nil) {
        let settings = settings ?? settingsStore.settings
        statusItemController.update(
            settings: settings,
            keyboardHealth: keyboardHealth,
            keyboardPaused: keyboardPaused
        )
    }
}
