import AppKit
import ImageIO

/// Lazily decodes and caches bounded thumbnails from image payloads. Cache entries
/// are invalidated together with their source payload lifecycle.
@MainActor
final class ClipboardThumbnailLoader: ObservableObject {
    private var cache: [String: NSImage] = [:]
    private var loads: [String: UUID] = [:]
    private let dataProvider: (String) -> Data?
    private let maxPixelSize: CGFloat

    init(maxPixelSize: CGFloat = 96, dataProvider: @escaping (String) -> Data?) {
        self.maxPixelSize = maxPixelSize
        self.dataProvider = dataProvider
    }

    func thumbnail(for reference: String) -> NSImage? {
        if let cached = cache[reference] {
            return cached
        }
        guard loads[reference] == nil, let data = dataProvider(reference) else { return nil }
        let loadID = UUID()
        loads[reference] = loadID
        let maxPixelSize = self.maxPixelSize
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let image = Self.downscaledImage(from: data, maxPixelSize: maxPixelSize)
            DispatchQueue.main.async {
                guard let self, self.loads[reference] == loadID else { return }
                self.loads.removeValue(forKey: reference)
                if let image {
                    self.cache[reference] = NSImage(cgImage: image, size: .zero)
                }
                self.objectWillChange.send()
            }
        }
        return nil
    }

    func remove(references: Set<String>) {
        for reference in references {
            cache.removeValue(forKey: reference)
            loads.removeValue(forKey: reference)
        }
    }

    func clear() {
        cache.removeAll()
        loads.removeAll()
    }

    private nonisolated static func downscaledImage(from data: Data, maxPixelSize: CGFloat) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
