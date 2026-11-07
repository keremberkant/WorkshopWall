import SwiftUI

struct MenuBarMenu: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: WallpaperLibrary
    @EnvironmentObject private var desktop: DesktopController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(desktop.current?.title ?? String(localized: "No wallpaper selected"))
        Text(desktop.statusText)
        Divider()
        Button("Next Wallpaper  ⌃⌥⌘→") { AppModel.shared.step(1) }
        Button("Previous Wallpaper  ⌃⌥⌘←") { AppModel.shared.step(-1) }
        Button("Random Wallpaper") { AppModel.shared.applyRandom() }
        Menu("Choose Wallpaper") {
            ForEach(library.wallpapers.filter(\.isPlayable)) { wallpaper in
                Toggle(wallpaper.title, isOn: Binding(
                    get: { desktop.current == wallpaper },
                    set: { _ in desktop.apply(wallpaper) }))
            }
        }
        Divider()
        Button("Open Library…") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "library")
        }
        Button("Download from Workshop…") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "library")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .showWorkshop, object: nil)
            }
        }
        Toggle("Pause", isOn: $desktop.userPaused)
        Toggle("Mute", isOn: $settings.muted)
        SettingsLink { Text("Settings…") }
        Divider()
        Button("Stop Live Wallpaper") { desktop.stop() }
            .disabled(desktop.current == nil)
        Button("Quit Canlı Duvar") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

extension DesktopController {
    var statusText: String {
        if current == nil { return String(localized: "Not playing") }
        return pauseReason?.label ?? String(localized: "Playing")
    }
}
