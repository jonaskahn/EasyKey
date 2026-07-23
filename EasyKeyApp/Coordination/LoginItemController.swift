import EasyEngineCore
import Foundation
import ServiceManagement

@MainActor
final class LoginItemController {
    enum Status: String {
        case disabled
        case enabled
        case unsupported
        case failed

        @MainActor
        func localizedTitle(using localization: LocalizationStore) -> String {
            switch self {
            case .disabled: localization.string(.systemLoginDisabled)
            case .enabled: localization.string(.systemLoginEnabled)
            case .unsupported: localization.string(.systemLoginUnsupported)
            case .failed: localization.string(.systemLoginFailed)
            }
        }

        @MainActor
        var localizedTitle: String {
            localizedTitle(using: .shared)
        }
    }

    private let loginItemService = SMAppService.loginItem(identifier: AppIdentifiers.loginHelper)
    private(set) var status: Status = .disabled

    func configure(enabled: Bool) {
        do {
            if enabled {
                try loginItemService.register()
            } else {
                try loginItemService.unregister()
            }
            status = loginItemService.status == .enabled ? .enabled : .disabled
            AppLog.info(.loginItem, "Login item configured enabled=\(enabled) status=\(status.rawValue)")
        } catch {
            AppLog.error(.loginItem, "Login item configure failed: \(error.localizedDescription)")
            status = loginItemService.status == .notFound ? .unsupported : .failed
        }
    }
}
