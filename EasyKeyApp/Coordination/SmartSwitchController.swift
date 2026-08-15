import AppKit
import EasyEngineCore

@MainActor
final class SmartSwitchController {
    private let smartSwitchStore: SmartSwitchStore

    var store: SmartSwitchStore {
        smartSwitchStore
    }

    private let localization: LocalizationStore
    private let settingsStore: SettingsStore

    private var isApplyingSmartSwitch = false
    private var lastSmartSwitchSyncedChoice: SmartSwitchChoice?

    private(set) var currentApplicationName: String
    private(set) var currentAppSmartSwitchStatus: String
    private(set) var smartSwitchRevision = 0

    /// The most recent non-EasyKey application the user activated. Used to
    /// re-evaluate the display while EasyKey itself is frontmost (popover or
    /// Settings window open), since activating EasyKey must never overwrite
    /// the app the user is actually monitoring.
    private var lastKnownExternalApplication: NSRunningApplication?

    var onPublishedStateChange: (() -> Void)?

    /// Bundle identifier of the app the user is currently monitoring, if any.
    /// Used by the popover toggle to turn monitoring on/off per app.
    var currentExternalApplicationBundleIdentifier: String? {
        lastKnownExternalApplication?.bundleIdentifier
    }

    init(
        smartSwitchStore: SmartSwitchStore,
        settingsStore: SettingsStore,
        localization: LocalizationStore
    ) {
        self.smartSwitchStore = smartSwitchStore
        self.settingsStore = settingsStore
        self.localization = localization
        currentApplicationName = localization.string(.smartSwitchNoActiveApp)
        currentAppSmartSwitchStatus = localization.string(.smartSwitchOff)
    }

    var preferences: [SmartSwitchPreference] {
        smartSwitchStore.preferences
    }

    func resetPreference(_ preference: SmartSwitchPreference) {
        do {
            try smartSwitchStore.reset(key: preference.key)
            smartSwitchRevision &+= 1
            onPublishedStateChange?()
        } catch {
            AppLog.error(.smartSwitch, "Failed to reset Smart Switch preference: \(error.localizedDescription)")
        }
    }

    func clearPreferences() {
        do {
            try smartSwitchStore.clearAll()
            smartSwitchRevision &+= 1
            onPublishedStateChange?()
        } catch {
            AppLog.error(.smartSwitch, "Failed to clear Smart Switch preferences: \(error.localizedDescription)")
        }
    }

    func handleApplicationActivation(_ application: NSRunningApplication?, settingsOverride: EasyKeySettings? = nil) {
        guard let application else {
            currentApplicationName = localization.string(.smartSwitchNoActiveApp)
            currentAppSmartSwitchStatus = localization.string(.smartSwitchUnavailable)
            onPublishedStateChange?()
            return
        }

        // EasyKey activating itself (popover, Settings window) must not
        // overwrite the displayed external app — keep the last known app
        // the user is monitoring.
        guard application.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        lastKnownExternalApplication = application

        // The override carries freshly-published settings: @Published emits
        // during willSet, so re-reading the store here would see stale values
        // when this runs from the settings-change sink.
        let settings = settingsOverride ?? settingsStore.settings

        currentApplicationName = application.localizedName
            ?? application.bundleIdentifier
            ?? localization.string(.smartSwitchUnknownApp)
        if let bundleIdentifier = application.bundleIdentifier,
           settings.compatibility.ignoredApplicationBundleIdentifiers.contains(bundleIdentifier) {
            currentAppSmartSwitchStatus = localization.string(.smartSwitchIgnored)
            onPublishedStateChange?()
            return
        }
        guard settings.smartSwitch.enabled else {
            currentAppSmartSwitchStatus = localization.string(.smartSwitchOff)
            onPublishedStateChange?()
            return
        }

        let identity = ApplicationIdentity(
            bundleIdentifier: application.bundleIdentifier,
            path: application.bundleURL?.path,
            name: application.localizedName
        )
        let currentChoice = SmartSwitchChoice(
            language: settings.input.language,
            encoding: settings.smartSwitch.rememberEncoding ? settings.input.encoding : nil
        )

        do {
            switch try smartSwitchStore.handleAppFocus(identity, currentChoice: currentChoice) {
            case let .applied(choice):
                if settings.smartSwitch.rememberEncoding {
                    applyLanguageAndEncoding(from: choice)
                } else {
                    applyLanguage(from: choice)
                }
                currentAppSmartSwitchStatus = localization.format(
                    .smartSwitchUseLanguage,
                    localization.displayName(for: choice.language)
                )
                AppLog.debug(.smartSwitch, "Applied preference language=\(choice.language.rawValue)")
            case let .recorded(choice):
                currentAppSmartSwitchStatus = localization.format(
                    .smartSwitchUseLanguage,
                    localization.displayName(for: choice.language)
                )
                AppLog.debug(.smartSwitch, "Recorded preference language=\(choice.language.rawValue)")
            case .ignored:
                currentAppSmartSwitchStatus = localization.string(.smartSwitchIgnored)
            }
        } catch {
            AppLog.error(.smartSwitch, "Smart Switch focus handling failed: \(error.localizedDescription)")
            currentAppSmartSwitchStatus = localization.string(.smartSwitchUnavailable)
        }
        onPublishedStateChange?()
    }

    /// Re-evaluates the display against the last known external application.
    /// Used when settings change (Smart Switch toggle, ignored apps, language)
    /// while EasyKey itself is frontmost, where reading the frontmost app
    /// would wrongly describe EasyKey. Pass freshly-published settings when
    /// called from the settings-change sink to avoid stale reads.
    func reevaluateCurrentApplication(settings: EasyKeySettings? = nil) {
        handleApplicationActivation(lastKnownExternalApplication, settingsOverride: settings)
    }

    func rememberChoiceIfNeeded(from settings: EasyKeySettings) {
        let choice = SmartSwitchChoice(
            language: settings.input.language,
            encoding: settings.smartSwitch.rememberEncoding ? settings.input.encoding : nil
        )
        defer { lastSmartSwitchSyncedChoice = choice }

        guard !isApplyingSmartSwitch else { return }
        guard settings.smartSwitch.enabled else { return }
        guard let previous = lastSmartSwitchSyncedChoice, previous != choice else { return }
        guard let application = NSWorkspace.shared.frontmostApplication,
              application.bundleIdentifier != Bundle.main.bundleIdentifier
        else { return }
        if let bundleIdentifier = application.bundleIdentifier,
           settings.compatibility.ignoredApplicationBundleIdentifiers.contains(bundleIdentifier) {
            return
        }

        let identity = ApplicationIdentity(
            bundleIdentifier: application.bundleIdentifier,
            path: application.bundleURL?.path,
            name: application.localizedName
        )
        do {
            guard try smartSwitchStore.updateChoice(for: identity, choice: choice) else { return }
            smartSwitchRevision &+= 1
            currentAppSmartSwitchStatus = localization.format(
                .smartSwitchUseLanguage,
                localization.displayName(for: choice.language)
            )
            onPublishedStateChange?()
        } catch {
            AppLog.error(.smartSwitch, "Failed to remember Smart Switch choice: \(error.localizedDescription)")
        }
    }

    func applyLanguage(from choice: SmartSwitchChoice) {
        isApplyingSmartSwitch = true
        defer { isApplyingSmartSwitch = false }
        settingsStore.update { settings in
            settings.input.language = choice.language
        }
    }

    func applyLanguageAndEncoding(from choice: SmartSwitchChoice) {
        isApplyingSmartSwitch = true
        defer { isApplyingSmartSwitch = false }
        settingsStore.update { settings in
            settings.input.language = choice.language
            if let encoding = choice.encoding {
                settings.input.encoding = encoding
            }
        }
    }
}
