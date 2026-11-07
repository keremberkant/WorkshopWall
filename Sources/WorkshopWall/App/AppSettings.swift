import Foundation
import ServiceManagement

/// User preferences, persisted in UserDefaults.
@MainActor
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults

    @Published var muted: Bool { didSet { defaults.set(muted, forKey: Keys.muted) } }
    @Published var pauseOnBattery: Bool { didSet { defaults.set(pauseOnBattery, forKey: Keys.pauseOnBattery) } }
    @Published var pauseInLowPowerMode: Bool { didSet { defaults.set(pauseInLowPowerMode, forKey: Keys.pauseInLowPowerMode) } }
    @Published var pauseWhenCovered: Bool { didSet { defaults.set(pauseWhenCovered, forKey: Keys.pauseWhenCovered) } }
    /// Also set the wallpaper's preview image as the static macOS desktop picture
    /// (shown on the lock screen and in Mission Control). Off by default: it changes a system setting.
    @Published var setStaticDesktopPicture: Bool { didSet { defaults.set(setStaticDesktopPicture, forKey: Keys.setStaticDesktopPicture) } }
    @Published var showMenuBarIcon: Bool { didSet { defaults.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon) } }

    enum Keys {
        static let muted = "muted"
        static let pauseOnBattery = "pauseOnBattery"
        static let pauseInLowPowerMode = "pauseInLowPowerMode"
        static let pauseWhenCovered = "pauseWhenCovered"
        static let setStaticDesktopPicture = "setStaticDesktopPicture"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let currentWallpaper = "currentWallpaper"
        static let libraryRoot = "libraryRoot"
        static let steamUser = "steamUser"
        static let steamcmdRoot = "steamcmdRoot"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        func bool(_ key: String, _ fallback: Bool) -> Bool { defaults.object(forKey: key) as? Bool ?? fallback }
        muted = bool(Keys.muted, true)
        pauseOnBattery = bool(Keys.pauseOnBattery, true)
        pauseInLowPowerMode = bool(Keys.pauseInLowPowerMode, true)
        pauseWhenCovered = bool(Keys.pauseWhenCovered, true)
        setStaticDesktopPicture = bool(Keys.setStaticDesktopPicture, false)
        showMenuBarIcon = bool(Keys.showMenuBarIcon, true)
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        }
    }
}
