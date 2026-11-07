import AppKit
import Carbon.HIToolbox
import CanliDuvarCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeys: HotKeys?
    private var menuActions: [MenuAction] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = AppModel.shared
        hotKeys = HotKeys([
            .init(keyCode: kVK_RightArrow, modifiers: HotKeys.controlOptionCommand) { model.step(1) },
            .init(keyCode: kVK_LeftArrow, modifiers: HotKeys.controlOptionCommand) { model.step(-1) },
            .init(keyCode: kVK_DownArrow, modifiers: HotKeys.controlOptionCommand) { model.desktop.userPaused.toggle() },
        ])
        // Launched from login items: stay in the background. Launched by the user: show the library.
        if !Self.launchedAsLoginItem {
            DispatchQueue.main.async { self.showLibraryWindow() }
        }
    }

    /// Clicking the Dock icon brings the library back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { return !showLibraryWindow() }
        return true
    }

    /// Brings the existing library window to the front. Returns `false` if SwiftUI has not created it yet.
    @discardableResult
    func showLibraryWindow() -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        guard let window = NSApp.windows.first(where: {
            !($0 is DesktopWindow) && ($0.identifier?.rawValue.hasPrefix("library") ?? false)
        }) else { return false }
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
        return true
    }

    private static var launchedAsLoginItem: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent else { return false }
        return event.eventID == kAEOpenApplication
            && event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }

    /// Closing the window keeps the wallpaper running.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let model = AppModel.shared
        menuActions.removeAll()
        let menu = NSMenu()
        menu.addItem(item(String(localized: "Next Wallpaper")) { model.step(1) })
        menu.addItem(item(String(localized: "Previous Wallpaper")) { model.step(-1) })
        menu.addItem(item(String(localized: "Random Wallpaper")) { model.applyRandom() })
        menu.addItem(.separator())
        for wallpaper in model.playable {
            let entry = item(wallpaper.title) { model.desktop.apply(wallpaper) }
            entry.state = model.desktop.current == wallpaper ? .on : .off
            menu.addItem(entry)
        }
        menu.addItem(.separator())
        let pauseTitle = model.desktop.userPaused ? String(localized: "Resume") : String(localized: "Pause")
        menu.addItem(item(pauseTitle) { model.desktop.userPaused.toggle() })
        return menu
    }

    private final class MenuAction: NSObject {
        let run: @MainActor () -> Void
        init(_ run: @escaping @MainActor () -> Void) { self.run = run }
        @objc func fire() { MainActor.assumeIsolated { run() } }
    }

    private func item(_ title: String, _ run: @escaping @MainActor () -> Void) -> NSMenuItem {
        let action = MenuAction(run)
        menuActions.append(action)
        let item = NSMenuItem(title: title, action: #selector(MenuAction.fire), keyEquivalent: "")
        item.target = action
        return item
    }
}
