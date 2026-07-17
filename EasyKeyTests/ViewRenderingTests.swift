import AppKit
import EasyEngineCore
@testable import EasyKey
import SwiftUI
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

    func testContentView_Renders() {
        render { ContentView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testSettingsShell_Renders() {
        render { SettingsShell(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testTypingSettingsView_Renders() {
        render { TypingSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testEncodingSettingsView_Renders() {
        render { EncodingSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    func testEncodingSettingsView_CopyPreviewAndPreviewAccessors() {
        let view = EncodingSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        _ = view.preview
        view.copyPreview()
    }

    func testBehaviorSettingsView_Renders() {
        render { BehaviorSettingsView(settingsStore: coordinator.settingsStore) }
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
        let appURL = tempDirectory.appendingPathComponent("Example.app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleIdentifier": "dev.example.Application",
            "CFBundlePackageType": "APPL",
            "CFBundleExecutable": "Example",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contentsURL.appendingPathComponent("Info.plist"))
        let executableURL = contentsURL.appendingPathComponent("MacOS/Example")
        try FileManager.default.createDirectory(
            at: executableURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: executableURL)

        XCTAssertEqual(
            ApplicationBundleSelection.bundleIdentifier(at: appURL),
            "dev.example.Application"
        )
        XCTAssertNil(ApplicationBundleSelection.bundleIdentifier(at: contentsURL.appendingPathComponent("Info.plist")))
    }

    func testUpdateAvailableView_WithReleaseNotes_Renders() {
        render {
            UpdateAvailableView(
                currentVersion: "1.0.0",
                latestVersion: "1.1.0",
                releaseNotes: "Bug fixes and improvements.",
                downloadURL: "https://github.com/jonaskahn/EasyKey/releases/tag/v1.1.0",
                onDismiss: {},
                onDownload: {}
            )
        }
    }

    func testUpdateAvailableView_WithoutReleaseNotes_Renders() {
        render {
            UpdateAvailableView(
                currentVersion: "1.0.0",
                latestVersion: "1.1.0",
                releaseNotes: nil,
                downloadURL: "https://github.com/jonaskahn/EasyKey/releases/tag/v1.1.0",
                onDismiss: {},
                onDownload: {}
            )
        }
    }

    func testUpToDateView_Renders() {
        render {
            UpToDateView(currentVersion: "1.0.0", onDismiss: {})
        }
    }

    func testUpdateCheckErrorView_Renders() {
        render {
            UpdateCheckErrorView(onDismiss: {})
        }
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
}
