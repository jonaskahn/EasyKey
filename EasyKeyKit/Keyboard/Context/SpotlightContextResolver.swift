import EasyEngineCore
import Foundation

/// Caches Spotlight-window visibility with a short TTL.
final class SpotlightContextResolver {
    static let ttl: CFAbsoluteTime = 0.3

    private let provider: () -> Bool
    private let now: () -> CFAbsoluteTime
    private var cached: Bool?
    private var cacheTime: CFAbsoluteTime = 0

    init(provider: @escaping () -> Bool, now: @escaping () -> CFAbsoluteTime) {
        self.provider = provider
        self.now = now
    }

    func resolve() -> Bool {
        let currentTime = now()
        if let cached,
           currentTime - cacheTime < Self.ttl {
            return cached
        }
        let visible = provider()
        if visible != cached {
            AppLog.debug(.keyboard, "Spotlight visibility changed visible=\(visible)")
        }
        cached = visible
        cacheTime = currentTime
        return visible
    }

    func invalidate() {
        cached = nil
        cacheTime = 0
    }
}
