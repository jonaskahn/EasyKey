import AppKit

/// Lazily decodes and caches bounded thumbnails from image payloads. Cache entries
/// are invalidated together with their source payload lifecycle.
@MainActor
final class ClipboardThumbnailLoader: ObservableObject {
    private var cache: [String: NSImage] = [:]
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
        guard let data = dataProvider(reference), let image = downscaled(from: data) else { return nil }
        cache[reference] = image
        return image
    }

    func remove(references: Set<String>) {
        for reference in references {
            cache.removeValue(forKey: reference)
        }
    }

    func clear() {
        cache.removeAll()
    }

    private func downscaled(from data: Data) -> NSImage? {
        guard let source = NSBitmapImageRep(data: data) else { return nil }
        let width = CGFloat(source.pixelsWide)
        let height = CGFloat(source.pixelsHigh)
        guard width > 0, height > 0 else { return nil }
        let scale = min(1, maxPixelSize / max(width, height))
        let target = NSSize(width: width * scale, height: height * scale)
        let image = NSImage(size: target)
        image.addRepresentation(source)
        return image
    }
}
