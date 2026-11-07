import AppKit
import WorkshopWallCore

/// The folder of wallpapers the user has added (can live on an external drive).
@MainActor
final class WallpaperLibrary: ObservableObject {
    @Published private(set) var wallpapers: [Wallpaper] = []
    @Published private(set) var root: URL
    @Published private(set) var isImporting = false
    @Published var lastMessage: String?

    static var defaultRoot: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WorkshopWall/Wallpapers", isDirectory: true)
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: AppSettings.Keys.libraryRoot) {
            root = URL(fileURLWithPath: saved, isDirectory: true)
        } else {
            root = Self.defaultRoot
        }
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        reload()
    }

    /// `false` when the library is on an external drive that is not connected.
    var isAvailable: Bool { FileManager.default.fileExists(atPath: root.path) }

    func setRoot(_ url: URL) {
        root = url
        UserDefaults.standard.set(url.path, forKey: AppSettings.Keys.libraryRoot)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        reload()
    }

    func reload() {
        let root = self.root
        Task.detached(priority: .userInitiated) {
            let found = Self.scan(root)
            await MainActor.run { self.wallpapers = found }
        }
    }

    nonisolated private static func scan(_ root: URL) -> [Wallpaper] {
        let fm = FileManager.default
        let folders = (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey],
                                                   options: [.skipsHiddenFiles])) ?? []
        return folders
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .compactMap { Wallpaper.load(folder: $0) }
            .sorted { a, b in
                if a.isPlayable != b.isPlayable { return a.isPlayable }
                return a.title.localizedStandardCompare(b.title) == .orderedAscending
            }
    }

    /// Copies (or moves) files and folders into the library on a background thread.
    /// Picking Wallpaper Engine's `workshop/content/431960` folder imports every project in it.
    func importItems(_ urls: [URL], move: Bool = false) async {
        isImporting = true
        defer { isImporting = false }
        let root = self.root
        let (imported, skipped) = await Task.detached(priority: .userInitiated) {
            Self.copy(urls, into: root, move: move)
        }.value
        reload()
        lastMessage = skipped > 0
            ? String(localized: "Wallpapers added: \(imported). Skipped: \(skipped).")
            : String(localized: "Wallpapers added: \(imported).")
    }

    nonisolated private static func copy(_ urls: [URL], into root: URL, move: Bool) -> (Int, Int) {
        let fm = FileManager.default
        var imported = 0, skipped = 0
        for url in urls {
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory) else { skipped += 1; continue }
            if !isDirectory.boolValue {
                guard Wallpaper.kind(forExtension: url.pathExtension) != .unsupported else { skipped += 1; continue }
                let dest = uniqueFolder(named: url.deletingPathExtension().lastPathComponent, in: root)
                do {
                    try fm.createDirectory(at: dest, withIntermediateDirectories: true)
                    try fm.copyItem(at: url, to: dest.appendingPathComponent(url.lastPathComponent))
                    imported += 1
                } catch { skipped += 1 }
                continue
            }
            for folder in Wallpaper.discoverProjects(in: url) {
                guard let wallpaper = Wallpaper.load(folder: folder) else { skipped += 1; continue }
                let dest = uniqueFolder(named: wallpaper.title, in: root)
                do {
                    if move { try fm.moveItem(at: folder, to: dest) } else { try fm.copyItem(at: folder, to: dest) }
                    imported += 1
                } catch { skipped += 1 }
            }
        }
        return (imported, skipped)
    }

    func remove(_ wallpaper: Wallpaper) {
        try? FileManager.default.trashItem(at: wallpaper.folder, resultingItemURL: nil)
        reload()
    }

    nonisolated private static func uniqueFolder(named name: String, in root: URL) -> URL {
        let clean = Wallpaper.safeFolderName(name)
        let base = clean.isEmpty ? "Wallpaper" : clean
        var candidate = root.appendingPathComponent(base)
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = root.appendingPathComponent("\(base) \(n)")
            n += 1
        }
        return candidate
    }
}
