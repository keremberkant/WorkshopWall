import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: WallpaperLibrary

    var body: some View {
        Form {
            Section("Playback") {
                Toggle("Mute wallpaper sound", isOn: $settings.muted)
                Toggle("Pause on battery power", isOn: $settings.pauseOnBattery)
                Toggle("Pause in Low Power Mode", isOn: $settings.pauseInLowPowerMode)
                Toggle("Pause when the desktop is covered by a full-screen or maximized window", isOn: $settings.pauseWhenCovered)
            }
            Section("Desktop") {
                Toggle("Also set the preview as the static desktop picture", isOn: $settings.setStaticDesktopPicture)
                Text("Shown on the lock screen and in Mission Control. This changes your macOS desktop picture.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("General") {
                Toggle("Launch at login", isOn: Binding(get: { settings.launchAtLogin },
                                                         set: { settings.launchAtLogin = $0 }))
                Toggle("Show icon in the menu bar", isOn: $settings.showMenuBarIcon)
                LabeledContent("Library folder") {
                    HStack {
                        Text(library.root.path).lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                        Button("Change…") { chooseLibraryFolder() }
                    }
                }
            }
            Section("Shortcuts (work in any app)") {
                LabeledContent("Next wallpaper", value: "⌃⌥⌘→")
                LabeledContent("Previous wallpaper", value: "⌃⌥⌘←")
                LabeledContent("Pause / resume", value: "⌃⌥⌘↓")
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func chooseLibraryFolder() {
        let panel = NSOpenPanel()
        panel.title = String(localized: "Folder for your wallpapers")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url { library.setRoot(url) }
    }
}
