import AppKit
import AVFoundation
import CanliDuvarCore
import Combine

/// Plays the current wallpaper on every display.
@MainActor
final class DesktopController: ObservableObject {
    @Published private(set) var current: Wallpaper?
    @Published var userPaused = false { didSet { refreshPlayback() } }
    /// Whether anything is actually playing right now (false while paused for any reason).
    @Published private(set) var isPlaying = false
    @Published private(set) var pauseReason: PauseReason?

    enum PauseReason: Equatable {
        case user, sleep, battery, lowPower, covered

        var label: String {
            switch self {
            case .user: return String(localized: "Paused")
            case .sleep: return String(localized: "Paused (display asleep)")
            case .battery: return String(localized: "Paused (on battery)")
            case .lowPower: return String(localized: "Paused (Low Power Mode)")
            case .covered: return String(localized: "Paused (desktop covered)")
            }
        }
    }

    private let settings: AppSettings
    private let conditions = PlaybackConditions()
    private var windows: [CGDirectDisplayID: DesktopWindow] = [:]
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var cancellables: Set<AnyCancellable> = []

    init(settings: AppSettings) {
        self.settings = settings
        conditions.onChange = { [weak self] in self?.refreshPlayback() }

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.syncWindows(reload: true) }
            .store(in: &cancellables)

        settings.$muted.dropFirst().sink { [weak self] muted in
            self?.player?.isMuted = muted
            self?.views.forEach { $0.setMuted(muted) }
        }.store(in: &cancellables)

        Publishers.MergeMany(settings.$pauseOnBattery, settings.$pauseInLowPowerMode, settings.$pauseWhenCovered)
            .dropFirst(3)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshPlayback() }
            .store(in: &cancellables)

        if let path = UserDefaults.standard.string(forKey: AppSettings.Keys.currentWallpaper),
           let wallpaper = Wallpaper.load(folder: URL(fileURLWithPath: path)), wallpaper.isPlayable {
            apply(wallpaper)
        }
    }

    private var views: [WallpaperView] { windows.values.compactMap { $0.contentView as? WallpaperView } }

    // MARK: Public

    func apply(_ wallpaper: Wallpaper) {
        guard wallpaper.isPlayable, wallpaper != current else { return }
        current = wallpaper
        UserDefaults.standard.set(wallpaper.folder.path, forKey: AppSettings.Keys.currentWallpaper)
        makePlayer(for: wallpaper)
        syncWindows(reload: true)
        if settings.setStaticDesktopPicture { setStaticDesktopPicture(from: wallpaper) }
    }

    func stop() {
        current = nil
        UserDefaults.standard.removeObject(forKey: AppSettings.Keys.currentWallpaper)
        tearDownPlayer()
        for window in windows.values {
            (window.contentView as? WallpaperView)?.clear()
            window.close()
        }
        windows.removeAll()
        refreshPlayback()
    }

    // MARK: Windows

    /// Keeps exactly one window per display, reusing windows across wallpaper changes.
    private func syncWindows(reload: Bool) {
        guard let wallpaper = current else { return }
        let screens = Dictionary(NSScreen.screens.map { ($0.displayID, $0) }, uniquingKeysWith: { a, _ in a })

        for (id, window) in windows where screens[id] == nil {
            (window.contentView as? WallpaperView)?.clear()
            window.close()
            windows[id] = nil
        }
        for (id, screen) in screens {
            if let window = windows[id] {
                if window.frame != screen.frame { window.setFrame(screen.frame, display: true) }
                if reload { (window.contentView as? WallpaperView)?.show(wallpaper, sharedPlayer: player, muted: settings.muted) }
            } else {
                let window = DesktopWindow(screen: screen)
                let view = WallpaperView(frame: NSRect(origin: .zero, size: screen.frame.size))
                window.contentView = view
                view.show(wallpaper, sharedPlayer: player, muted: settings.muted)
                window.orderFront(nil)
                windows[id] = window
            }
        }
        refreshPlayback()
    }

    // MARK: Video

    private func makePlayer(for wallpaper: Wallpaper) {
        tearDownPlayer()
        guard wallpaper.kind == .video, let file = wallpaper.file else { return }
        let item = AVPlayerItem(asset: AVURLAsset(url: file))
        // Decode no larger than the biggest display needs.
        if let maxSize = NSScreen.screens.map({ CGSize(width: $0.frame.width * $0.backingScaleFactor,
                                                         height: $0.frame.height * $0.backingScaleFactor) })
            .max(by: { $0.width * $0.height < $1.width * $1.height }) {
            item.preferredMaximumResolution = maxSize
        }
        let queue = AVQueuePlayer()
        queue.isMuted = settings.muted
        queue.preventsDisplaySleepDuringVideoPlayback = false
        queue.allowsExternalPlayback = false
        looper = AVPlayerLooper(player: queue, templateItem: item)
        player = queue
    }

    private func tearDownPlayer() {
        player?.pause()
        looper?.disableLooping()
        looper = nil
        player = nil
    }

    // MARK: Pausing

    private func refreshPlayback() {
        let reasonFor: (CGDirectDisplayID) -> PauseReason? = { [settings, conditions, userPaused] id in
            if userPaused { return .user }
            if conditions.systemAsleep { return .sleep }
            if settings.pauseOnBattery && conditions.onBattery { return .battery }
            if settings.pauseInLowPowerMode && conditions.lowPowerMode { return .lowPower }
            if settings.pauseWhenCovered && conditions.coveredDisplays.contains(id) { return .covered }
            return nil
        }

        var anyPlaying = false
        var firstReason: PauseReason?
        for (id, window) in windows {
            let reason = reasonFor(id)
            (window.contentView as? WallpaperView)?.setPaused(reason != nil)
            if reason == nil { anyPlaying = true } else if firstReason == nil { firstReason = reason }
        }
        if let player { anyPlaying ? player.play() : player.pause() }

        isPlaying = current != nil && anyPlaying
        pauseReason = current == nil || anyPlaying ? nil : (firstReason ?? reasonFor(0))
        conditions.setCoverageMonitoring(current != nil && settings.pauseWhenCovered && !userPaused)
    }

    // MARK: Static desktop picture

    private func setStaticDesktopPicture(from wallpaper: Wallpaper) {
        guard let preview = wallpaper.preview,
              ["jpg", "jpeg", "png", "heic"].contains(preview.pathExtension.lowercased()) else { return }
        for screen in NSScreen.screens {
            try? NSWorkspace.shared.setDesktopImageURL(preview, for: screen, options: [:])
        }
    }
}
