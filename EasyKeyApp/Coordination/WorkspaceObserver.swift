import AppKit

@MainActor
final class WorkspaceObserver {
    private var workspaceObservers: [NSObjectProtocol] = []

    var onApplicationActivated: ((NSRunningApplication?) -> Void)?
    var onResetSession: (() -> Void)?
    var onWake: (() -> Void)?

    func start() {
        stop()
        let notificationCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                MainActor.assumeIsolated {
                    self?.onApplicationActivated?(application)
                }
            },
            notificationCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.onResetSession?()
                }
            },
            notificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.onResetSession?()
                }
            },
            notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.onWake?()
                }
            },
        ]
    }

    func stop() {
        workspaceObservers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
        workspaceObservers.removeAll()
    }
}
