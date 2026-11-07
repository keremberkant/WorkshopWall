import AppKit
import ImageIO
import SwiftUI

/// Small, cached preview images decoded off the main thread
/// (Workshop previews are often multi-megabyte GIFs; decoding them in the grid made scrolling stutter).
actor ThumbnailLoader {
    static let shared = ThumbnailLoader()
    private let cache = NSCache<NSURL, NSImage>()

    init() { cache.countLimit = 300 }

    func thumbnail(for url: URL, maxPixelSize: Int = 520) -> NSImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}

/// Async thumbnail view used by the library grid.
struct Thumbnail: View {
    let url: URL?
    let placeholderSymbol: String
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.12)
            if let image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: placeholderSymbol).font(.largeTitle).foregroundStyle(.secondary)
            }
        }
        .task(id: url) {
            guard let url else { image = nil; return }
            image = await ThumbnailLoader.shared.thumbnail(for: url)
        }
    }
}
