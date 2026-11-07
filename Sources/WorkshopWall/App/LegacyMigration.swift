import Foundation

/// Version 1.0 shipped as "Canlı Duvar" with the bundle ID `com.catkayastudio.canliduvar`.
/// On first launch, carry its settings over once so updating keeps the user's library and choices.
@MainActor
enum LegacyMigration {
    static let legacyDomain = "com.catkayastudio.canliduvar"
    static let doneKey = "migratedFromCanliDuvar"

    static let keys = [
        AppSettings.Keys.muted, AppSettings.Keys.pauseOnBattery, AppSettings.Keys.pauseInLowPowerMode,
        AppSettings.Keys.pauseWhenCovered, AppSettings.Keys.setStaticDesktopPicture, AppSettings.Keys.showMenuBarIcon,
        AppSettings.Keys.currentWallpaper, AppSettings.Keys.libraryRoot, AppSettings.Keys.steamUser,
        AppSettings.Keys.steamcmdRoot, "NSWindow Frame library",
    ]

    static func run(defaults: UserDefaults = .standard, fileManager fm: FileManager = .default) {
        guard !defaults.bool(forKey: doneKey) else { return }
        defaults.set(true, forKey: doneKey)

        if let old = defaults.persistentDomain(forName: legacyDomain) {
            for key in keys where defaults.object(forKey: key) == nil {
                if let value = old[key] { defaults.set(value, forKey: key) }
            }
        }

        // 1.0's default library folder, used when no custom folder was chosen.
        if defaults.string(forKey: AppSettings.Keys.libraryRoot) == nil {
            let legacyRoot = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("CanliDuvar/Wallpapers", isDirectory: true)
            if fm.fileExists(atPath: legacyRoot.path), !fm.fileExists(atPath: WallpaperLibrary.defaultRoot.path) {
                defaults.set(legacyRoot.path, forKey: AppSettings.Keys.libraryRoot)
            }
        }
    }
}
