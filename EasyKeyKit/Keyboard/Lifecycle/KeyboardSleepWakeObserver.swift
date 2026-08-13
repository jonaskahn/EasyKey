import AppKit
import Foundation

/// Subscribes to NSWorkspace sleep/wake notifications on the main queue.
final class KeyboardSleepWakeObserver {
    private var observers: [NSObjectProtocol] = []

    var isInstalled: Bool {
        !observers.isEmpty
    }

    func install(
        onSleep: @escaping () -> Void,
        onWake: @escaping () -> Void
    ) {
        guard observers.isEmpty else { return }
        let notificationCenter = NSWorkspace.shared.notificationCenter
        observers = [
            notificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { _ in onSleep() },
            notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { _ in onWake() },
        ]
    }

    func remove() {
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
    }

    deinit {
        remove()
    }
}
