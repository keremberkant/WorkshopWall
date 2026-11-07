import AppKit
import CanliDuvarCore
import IOKit.ps

/// Watches everything that should pause playback: sleep, locked session, battery, Low Power Mode
/// and displays hidden behind full-screen or maximized windows. Calls `onChange` when anything changes.
@MainActor
final class PlaybackConditions {
    var onChange: (() -> Void)?

    private(set) var systemAsleep = false
    private(set) var onBattery = PlaybackConditions.readOnBattery()
    private(set) var lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    private(set) var coveredDisplays: Set<CGDirectDisplayID> = []

    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var powerSource: CFRunLoopSource?
    private var coverageTimer: Timer?

    init() {
        let workspace = NSWorkspace.shared.notificationCenter
        let center = NotificationCenter.default

        for name in [NSWorkspace.screensDidSleepNotification, NSWorkspace.willSleepNotification,
                     NSWorkspace.sessionDidResignActiveNotification] {
            observe(workspace, name) { $0.systemAsleep = true }
        }
        for name in [NSWorkspace.screensDidWakeNotification, NSWorkspace.didWakeNotification,
                     NSWorkspace.sessionDidBecomeActiveNotification] {
            observe(workspace, name) { $0.systemAsleep = false }
        }
        for name in [NSWorkspace.didActivateApplicationNotification, NSWorkspace.activeSpaceDidChangeNotification,
                     NSWorkspace.didHideApplicationNotification, NSWorkspace.didUnhideApplicationNotification] {
            observe(workspace, name) { $0.updateCoverage() }
        }
        observe(center, .NSProcessInfoPowerStateDidChange) {
            $0.lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }

        // Power source changes (plugged in / on battery), delivered by IOKit without polling.
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let source = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            let me = Unmanaged<PlaybackConditions>.fromOpaque(ctx).takeUnretainedValue()
            MainActor.assumeIsolated {
                me.onBattery = PlaybackConditions.readOnBattery()
                me.onChange?()
            }
        }, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            powerSource = source
        }
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name,
                         _ update: @escaping @MainActor (PlaybackConditions) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                update(self)
                self.onChange?()
            }
        }
        observers.append((center, token))
    }

    /// Window coverage is polled (cheap: one CGWindowList call) only while something is playing.
    func setCoverageMonitoring(_ enabled: Bool) {
        guard enabled != (coverageTimer != nil) else { return }
        coverageTimer?.invalidate()
        coverageTimer = nil
        guard enabled else {
            if !coveredDisplays.isEmpty { coveredDisplays = []; onChange?() }
            return
        }
        updateCoverage()
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateCoverage() }
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        coverageTimer = timer
    }

    private func updateCoverage() {
        guard coverageTimer != nil else { return }
        let covered = Self.readCoveredDisplays()
        if covered != coveredDisplays {
            coveredDisplays = covered
            onChange?()
        }
    }

    // MARK: System queries

    private static func readOnBattery() -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let type = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() else { return false }
        return (type as String) == kIOPSBatteryPowerValue
    }

    /// Displays hidden behind normal app windows. Uses window bounds only (no screen recording permission needed).
    private static func readCoveredDisplays() -> Set<CGDirectDisplayID> {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]] else { return [] }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let windows: [CGRect] = list.compactMap { info in
            guard (info[kCGWindowLayer as String] as? Int) == 0,
                  (info[kCGWindowOwnerPID as String] as? pid_t) != ownPID,
                  (info[kCGWindowAlpha as String] as? Double ?? 1) > 0.9,
                  let dict = info[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: dict as CFDictionary) else { return nil }
            return rect
        }
        guard !windows.isEmpty, let primaryHeight = NSScreen.screens.first?.frame.height else { return [] }
        var result: Set<CGDirectDisplayID> = []
        for screen in NSScreen.screens {
            // AppKit uses bottom-left origin; CGWindowList uses top-left.
            let f = screen.frame
            let cgFrame = CGRect(x: f.minX, y: primaryHeight - f.maxY, width: f.width, height: f.height)
            if Coverage.isCovered(screen: cgFrame, by: windows) { result.insert(screen.displayID) }
        }
        return result
    }
}
