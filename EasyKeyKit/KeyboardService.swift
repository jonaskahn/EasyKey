import AppKit
import ApplicationServices
import CoreGraphics
import EasyEngineCore
import Foundation

/// Public facade for the keyboard event tap, Vietnamese engine pipeline, and diagnostics.
@MainActor
public final class KeyboardService {
    public enum Health: String, Equatable, Sendable {
        case stopped
        case requestingPermission
        case active
        case degraded
        case failed
    }

    public struct Diagnostic: Equatable, Sendable {
        public enum Disposition: String, Sendable {
            case passed
            case suppressed
            case bypassed
            case selfPosted
            case disabled
        }

        public let eventType: UInt32
        public let disposition: Disposition
        public let outputCount: Int
        public let bundleIdentifier: String?
        public let callbackDurationNanoseconds: UInt64
    }

    public static let defaultEmergencyPauseShortcut = Shortcut(
        keyCode: 35,
        modifiers: [.control, .option, .command]
    )

    public private(set) var health: Health = .stopped
    public var healthHandler: (@MainActor @Sendable (Health) -> Void)?
    public var pauseHandler: (@MainActor @Sendable (Bool) -> Void)?
    public var languageToggleHandler: (@MainActor @Sendable (InputLanguage) -> Void)?

    private let processingQueue = DispatchQueue(label: "com.easykey.keyboard-event-processing")
    private let eventTap: KeyboardEventTap
    private let pipeline: KeyboardInputPipeline
    private let diagnosticsRecorder = KeyboardDiagnosticsRecorder()

    private var didRequestAccessibilityPrompt = false
    private var isPaused = false

    public init(settings: EasyKeySettings = .defaults) {
        eventTap = KeyboardEventTap(eventMask: KeyboardInputPipeline.makeEventMask())
        pipeline = KeyboardInputPipeline(settings: settings)
        eventTap.bind(to: self)
        pipeline.onTogglePause = { [weak self] in self?.togglePause() }
        pipeline.onLanguageToggleRequested = { [weak self] language in
            self?.languageToggleHandler?(language)
        }
    }

    deinit {
        eventTap.tearDown()
    }

    public func start() {
        AppLog.info(.keyboard, "KeyboardService start requested")
        eventTap.installWorkspaceObserversIfNeeded(
            onSleep: { [weak self] in
                AppLog.notice(.keyboard, "System sleep — tearing down event tap")
                self?.eventTap.tearDown()
                self?.setHealth(.degraded)
            },
            onWake: { [weak self] in
                AppLog.notice(.keyboard, "System wake — refreshing permission")
                self?.refreshInputSource()
                self?.refreshPermission()
            }
        )
        refreshInputSource()
        setActiveApplication(NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
        startIfPermitted()
    }

    public func stop() {
        AppLog.info(.keyboard, "KeyboardService stop requested")
        eventTap.tearDown()
        setHealth(.stopped)
    }

    public func requestAccessibilityPermission() {
        guard !AXIsProcessTrusted() else {
            startIfPermitted()
            return
        }

        setHealth(.requestingPermission)
        AppLog.notice(.keyboard, "Requesting Accessibility permission")
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }

    public func refreshPermission() {
        guard AXIsProcessTrusted() else {
            AppLog.notice(.keyboard, "Accessibility not trusted — event tap torn down")
            eventTap.tearDown()
            setHealth(.requestingPermission)
            return
        }
        if !isPaused {
            startIfPermitted()
        }
    }

    public func update(settings: EasyKeySettings) {
        processingQueue.sync {
            pipeline.update(settings: settings)
        }
    }

    public func update(macros: [Macro]) {
        processingQueue.sync {
            pipeline.update(macros: macros)
        }
    }

    public var isComposing: Bool {
        processingQueue.sync {
            pipeline.isComposing
        }
    }

    public func setActiveApplication(_ bundleIdentifier: String?) {
        processingQueue.sync {
            pipeline.setActiveApplication(bundleIdentifier)
        }
    }

    public func refreshInputSource() {
        let foreignInputSource = KeyboardInputPipeline.isCurrentInputSourceForeign()
        processingQueue.sync {
            pipeline.setUsesForeignInputSource(foreignInputSource)
        }
    }

    public func resetSession() {
        processingQueue.sync {
            pipeline.resetSession()
        }
    }

    public func setCmdCDoublePressHandler(windowMs: Int, handler: @escaping @MainActor () -> Void) {
        processingQueue.sync {
            pipeline.setCmdCDoublePressHandler(windowMs: windowMs, handler: handler)
        }
    }

    public func clearCmdCDoublePressHandler() {
        processingQueue.sync {
            pipeline.clearCmdCDoublePressHandler()
        }
    }

    public func medianCallbackLatencyNanoseconds() -> UInt64? {
        processingQueue.sync { diagnosticsRecorder.medianCallbackLatencyNanoseconds }
    }

    public func togglePause() {
        setPaused(!isPaused)
    }

    public func setPaused(_ paused: Bool) {
        guard paused != isPaused else { return }
        isPaused = paused
        AppLog.info(.keyboard, "Keyboard pause=\(paused)")
        if paused {
            eventTap.tearDown()
            setHealth(.stopped)
        } else {
            startIfPermitted()
        }
        pauseHandler?(paused)
    }

    private func startIfPermitted() {
        guard !isPaused else {
            setHealth(.stopped)
            return
        }
        guard AXIsProcessTrusted() else {
            setHealth(.requestingPermission)
            return
        }
        guard !eventTap.isInstalled else {
            setHealth(.active)
            return
        }
        if eventTap.install() {
            setHealth(.active)
        } else {
            AppLog.error(.keyboard, "CGEvent tap install failed")
            setHealth(.failed)
        }
    }

    func handleTapEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let startedAt = DispatchTime.now().uptimeNanoseconds
        let keyCode = KeyboardInputPipeline.keyCode(from: event)

        if KeySynthesizer.isSelfPosted(event) {
            record(type: type, disposition: .selfPosted, outputCount: 0, startedAt: startedAt)
            return Unmanaged.passUnretained(event)
        }

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            AppLog.notice(.keyboard, "Event tap disabled type=\(type.rawValue); recovering")
            record(type: type, disposition: .disabled, outputCount: 0, startedAt: startedAt)
            recoverTapAfterDisable()
            return Unmanaged.passUnretained(event)
        }

        let result = processingQueue.sync { () -> KeyboardProcessResult in
            let result = pipeline.process(proxy: proxy, type: type, event: event, keyCode: keyCode)
            record(
                type: type,
                disposition: result.disposition,
                outputCount: result.outputCount,
                startedAt: startedAt
            )
            return result
        }
        return result.suppressesOriginal ? nil : Unmanaged.passUnretained(event)
    }

    private func recoverTapAfterDisable() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            eventTap.tearDown()
            setHealth(.degraded)
            refreshPermission()
        }
    }

    private func record(
        type: CGEventType,
        disposition: Diagnostic.Disposition,
        outputCount: Int,
        startedAt: UInt64
    ) {
        diagnosticsRecorder.record(
            typeRawValue: type.rawValue,
            disposition: disposition,
            outputCount: outputCount,
            bundleIdentifier: pipeline.activeAppBundleIdentifier,
            startedAt: startedAt
        )
    }

    private func setHealth(_ newValue: Health) {
        if health != newValue {
            AppLog.info(.keyboard, "Health \(health.rawValue) → \(newValue.rawValue)")
        }
        health = newValue
        healthHandler?(newValue)
    }
}
