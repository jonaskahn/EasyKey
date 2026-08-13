import EasyEngineCore
import Foundation

/// All mutable state is guarded by `lock`, making cross-actor access safe.
final class TranslationProviderRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var providers: [TranslationProviderID: TranslationProviding] = [:]

    func replace(with providers: [TranslationProviderID: TranslationProviding]) {
        lock.lock()
        self.providers = providers
        lock.unlock()
    }

    func provider(for identifier: TranslationProviderID) -> TranslationProviding? {
        lock.lock()
        defer { lock.unlock() }
        return providers[identifier]
    }
}
