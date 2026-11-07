import AppKit
import CanliDuvarCore

/// Shared app state. The window, menu bar menu, Dock menu and global shortcuts all use this instance.
@MainActor
final class AppModel {
    static let shared = AppModel()

    let settings: AppSettings
    let library: WallpaperLibrary
    let desktop: DesktopController
    let workshop: WorkshopDownloader

    private init() {
        settings = AppSettings()
        library = WallpaperLibrary()
        desktop = DesktopController(settings: settings)
        workshop = WorkshopDownloader(library: library)
    }

    var playable: [Wallpaper] { library.wallpapers.filter(\.isPlayable) }

    /// Switches to the next (`delta = 1`) or previous (`-1`) playable wallpaper, wrapping around.
    func step(_ delta: Int) {
        let list = playable
        guard !list.isEmpty else { return }
        let index = list.firstIndex { $0 == desktop.current } ?? (delta > 0 ? -1 : 0)
        desktop.apply(list[(index + delta + list.count) % list.count])
    }

    func applyRandom() {
        let others = playable.filter { $0 != desktop.current }
        if let pick = others.randomElement() ?? playable.first { desktop.apply(pick) }
    }
}
