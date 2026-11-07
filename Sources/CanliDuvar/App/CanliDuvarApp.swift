import AppKit
import SwiftUI

@main
struct CanliDuvarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = AppModel.shared.settings
    @StateObject private var library = AppModel.shared.library
    @StateObject private var desktop = AppModel.shared.desktop
    @StateObject private var workshop = AppModel.shared.workshop

    var body: some Scene {
        Window("Canlı Duvar", id: "library") {
            LibraryView()
                .environmentObjects(settings, library, desktop, workshop)
                .frame(minWidth: 780, minHeight: 520)
        }
        .defaultSize(width: 980, height: 660)
        .commands {
            CommandMenu("Wallpaper") {
                Button("Next Wallpaper") { AppModel.shared.step(1) }
                    .keyboardShortcut(.rightArrow, modifiers: .command)
                Button("Previous Wallpaper") { AppModel.shared.step(-1) }
                    .keyboardShortcut(.leftArrow, modifiers: .command)
                Button("Random Wallpaper") { AppModel.shared.applyRandom() }
                    .keyboardShortcut("r", modifiers: [.command, .option])
                Divider()
                Button(desktop.userPaused ? "Resume" : "Pause") { desktop.userPaused.toggle() }
                    .keyboardShortcut("p", modifiers: [.command, .option])
            }
        }

        Settings {
            SettingsView()
                .environmentObjects(settings, library, desktop, workshop)
        }

        // The status item reports its visibility back through this binding (KVO). Writing an unchanged
        // value would republish the settings, re-render every scene and loop forever — so only write changes.
        MenuBarExtra("Canlı Duvar", systemImage: "play.rectangle.on.rectangle", isInserted: Binding(
            get: { settings.showMenuBarIcon },
            set: { if $0 != settings.showMenuBarIcon { settings.showMenuBarIcon = $0 } })) {
            MenuBarMenu()
                .environmentObjects(settings, library, desktop, workshop)
        }
    }
}

extension View {
    func environmentObjects(_ settings: AppSettings, _ library: WallpaperLibrary,
                            _ desktop: DesktopController, _ workshop: WorkshopDownloader) -> some View {
        environmentObject(settings)
            .environmentObject(library)
            .environmentObject(desktop)
            .environmentObject(workshop)
    }
}
