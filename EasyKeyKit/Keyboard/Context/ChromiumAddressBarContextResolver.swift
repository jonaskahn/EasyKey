import Foundation

/// Caches Chromium address-bar detection with a TTL, refreshing off the event
/// path and rejecting stale results by generation.
final class ChromiumAddressBarContextResolver {
    static let ttl: CFAbsoluteTime = 1.5

    private struct Cache {
        var value: Bool?
        var updatedAt: CFAbsoluteTime = 0
        var isRefreshing = false
        var generation: UInt = 0
    }

    private let detector: () -> Bool
    private let now: () -> CFAbsoluteTime
    private let queue = DispatchQueue(label: "com.easykey.chromium-address-cache")
    private var cache = Cache()

    init(detector: @escaping () -> Bool, now: @escaping () -> CFAbsoluteTime) {
        self.detector = detector
        self.now = now
    }

    func resolve() -> Bool {
        queue.sync {
            let currentTime = now()
            if let value = cache.value,
               currentTime - cache.updatedAt < Self.ttl {
                return value
            }
            if !cache.isRefreshing {
                cache.isRefreshing = true
                let generation = cache.generation
                let detector = detector
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    let detected = detector()
                    self?.queue.async { [weak self] in
                        guard let self, self.cache.generation == generation else { return }
                        self.cache.value = detected
                        self.cache.updatedAt = self.now()
                        self.cache.isRefreshing = false
                    }
                }
            }
            return cache.value ?? false
        }
    }

    func invalidate() {
        queue.sync {
            cache.value = nil
            cache.updatedAt = 0
            cache.isRefreshing = false
            cache.generation &+= 1
        }
    }
}
