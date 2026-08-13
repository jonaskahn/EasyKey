import AppKit

final class TranslationPanelMonitorRegistration {
    private var removeAction: (() -> Void)?

    init(removeAction: @escaping () -> Void) {
        self.removeAction = removeAction
    }

    deinit {
        invalidate()
    }

    func invalidate() {
        removeAction?()
        removeAction = nil
    }
}

@MainActor
protocol TranslationPanelEventMonitoring: AnyObject {
    func addLocalMonitor(
        isPanelOwnedWindow: @escaping (Int) -> Bool,
        handler: @escaping (TranslationPanelLocalEvent) -> Bool
    ) -> TranslationPanelMonitorRegistration?
    func addGlobalClickMonitor(handler: @escaping () -> Void) -> TranslationPanelMonitorRegistration?
}

@MainActor
final class SystemTranslationPanelEventMonitor: TranslationPanelEventMonitoring {
    func addLocalMonitor(
        isPanelOwnedWindow: @escaping (Int) -> Bool,
        handler: @escaping (TranslationPanelLocalEvent) -> Bool
    ) -> TranslationPanelMonitorRegistration? {
        guard let monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown],
            handler: { event in
                let localEvent: TranslationPanelLocalEvent
                switch event.type {
                case .keyDown:
                    localEvent = event.keyCode == 53 ? .escape : .keyDown
                case .leftMouseDown, .rightMouseDown:
                    localEvent = isPanelOwnedWindow(event.windowNumber)
                        ? .mouseDownInsidePanel
                        : .mouseDownOutsidePanel
                default:
                    return event
                }
                return handler(localEvent) ? nil : event
            }
        )
        else {
            return nil
        }
        return TranslationPanelMonitorRegistration { NSEvent.removeMonitor(monitor) }
    }

    func addGlobalClickMonitor(handler: @escaping () -> Void) -> TranslationPanelMonitorRegistration? {
        guard let monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown],
            handler: { _ in handler() }
        )
        else {
            return nil
        }
        return TranslationPanelMonitorRegistration { NSEvent.removeMonitor(monitor) }
    }
}
