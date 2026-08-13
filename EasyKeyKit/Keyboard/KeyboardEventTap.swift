import AppKit
import ApplicationServices
import CoreGraphics
import EasyEngineCore
import Foundation

/// Owns CGEvent tap installation, teardown, and workspace sleep/wake observers.
final class KeyboardEventTap {
    private let eventMask: CGEventMask
    private var eventTap: CFMachPort?
    private var eventTapRunLoopSource: CFRunLoopSource?
    private let sleepWakeObserver = KeyboardSleepWakeObserver()
    private weak var service: KeyboardService?

    var isInstalled: Bool {
        eventTap != nil
    }

    init(eventMask: CGEventMask) {
        self.eventMask = eventMask
    }

    deinit {
        tearDown()
        sleepWakeObserver.remove()
    }

    func bind(to service: KeyboardService) {
        self.service = service
    }

    func install() -> Bool {
        guard let service else {
            AppLog.error(.keyboard, "Event tap install skipped: service unbound")
            return false
        }
        let context = Unmanaged.passUnretained(service).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: keyboardEventTapCallback,
            userInfo: context
        ), let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        else {
            AppLog.error(.keyboard, "CGEvent.tapCreate or run-loop source creation failed")
            return false
        }

        eventTap = tap
        eventTapRunLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        AppLog.info(.keyboard, "Event tap installed")
        return true
    }

    func tearDown() {
        let wasInstalled = eventTap != nil
        if let runLoopSource = eventTapRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        eventTapRunLoopSource = nil
        eventTap = nil
        if wasInstalled {
            AppLog.debug(.keyboard, "Event tap torn down")
        }
    }

    func installWorkspaceObserversIfNeeded(
        onSleep: @escaping () -> Void,
        onWake: @escaping () -> Void
    ) {
        sleepWakeObserver.install(onSleep: onSleep, onWake: onWake)
    }
}

func keyboardEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    assert(Thread.isMainThread, "keyboardEventTapCallback must be invoked on the main thread")
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let service = Unmanaged<KeyboardService>.fromOpaque(userInfo).takeUnretainedValue()
    return MainActor.assumeIsolated {
        service.handleTapEvent(proxy: proxy, type: type, event: event)
    }
}
