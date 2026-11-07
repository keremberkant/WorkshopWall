<p align="center">
  <img src="docs/icon.png" width="160" alt="Canlı Duvar icon">
</p>

<h1 align="center">Canlı Duvar</h1>

<p align="center">
  <b>Live wallpapers for macOS.</b> Plays Wallpaper Engine <i>video</i> and <i>web</i> wallpapers on your Mac desktop — natively, on Apple silicon and Intel.
  <br><br>
  <a href="README.tr.md">Türkçe</a> ·
  <a href="#install">Install</a> ·
  <a href="#usage">Usage</a> ·
  <a href="#building-from-source">Build</a>
</p>

---

*Canlı Duvar* (Turkish for "live wall") is a small, open-source macOS app that puts animated wallpapers behind your desktop icons. It reads Wallpaper Engine projects directly, so the wallpapers you already own on Windows can play on your Mac, and it can download new ones from the Steam Workshop.

> Canlı Duvar is an independent project. It is **not affiliated with** Wallpaper Engine, Kristjan Skutta or Valve. It does not include or redistribute any wallpapers.

## Features

- 🎬 **Video wallpapers** (MP4 / MOV / M4V) with hardware decoding — typically 0–3 % CPU
- 🌐 **Web wallpapers** (HTML / WebGL), including Wallpaper Engine's `wallpaperPropertyListener` API and default user properties
- 🖼 **Images & GIFs**
- 🖥 **Every display and every Space**, behind the desktop icons; clicks go through
- ⏭ **Switch instantly** — global shortcuts, previous / next / random, Dock menu, menu bar, single-click in the library
- 📥 **Steam Workshop downloads** with Valve's official SteamCMD — your password never touches the app
- 🔋 **Battery friendly** — pauses automatically when the display sleeps, on battery, in Low Power Mode or when a full-screen / maximized window covers the desktop (each one optional)
- 💾 **Library anywhere** — keep gigabytes of wallpapers on an external drive
- 🌍 English and Turkish, universal binary, ~4 MB, no dependencies

### What plays and what doesn't

| Wallpaper Engine type | macOS | Notes |
|---|---|---|
| Video | ✅ | MP4 / MOV / M4V. WebM is not supported by macOS. |
| Web | ✅ | Audio visualizers open but don't react to system audio. |
| Image / GIF | ✅ | |
| Scene | ❌ | A proprietary, DirectX-based format. Simple scenes can be recreated as web wallpapers by hand (see [docs/converting-scenes.md](docs/converting-scenes.md)). |
| Application | ❌ | Windows executables. |

## Install

1. Download `CanliDuvar-x.y.z.zip` from the [latest release](../../releases/latest) and unzip it.
2. Move **Canlı Duvar.app** to **Applications**.
3. The app is not notarized (no paid Apple Developer ID), so the first time **right-click → Open → Open**.
   If macOS says the app is damaged, run:
   ```bash
   xattr -dr com.apple.quarantine "/Applications/Canlı Duvar.app"
   ```

Requires **macOS 14 Sonoma** or later.

## Usage

- **Add wallpapers:** drag files or folders onto the window, or click **Add Files…**.
  You can pick a single Wallpaper Engine project, or the whole Workshop folder
  (`…/steamapps/workshop/content/431960`) to import everything at once.
- **Apply:** click a card.
- **Switch:**

  | Shortcut | Action |
  |---|---|
  | <kbd>⌃⌥⌘→</kbd> | Next wallpaper (works in any app) |
  | <kbd>⌃⌥⌘←</kbd> | Previous wallpaper (works in any app) |
  | <kbd>⌃⌥⌘↓</kbd> | Pause / resume (works in any app) |
  | <kbd>⌘→</kbd> / <kbd>⌘←</kbd> | Next / previous (in the app) |
  | <kbd>⌥⌘R</kbd> | Random wallpaper |

  Right-click the Dock icon for a list of all wallpapers.
- Closing the window keeps the wallpaper running. Quit from the menu bar icon or the app menu.
- **Settings** (<kbd>⌘,</kbd>): sound, pause rules, launch at login, menu bar icon, library folder,
  and optionally setting the preview as your static desktop picture (lock screen / Mission Control).

### Downloading from the Steam Workshop

You need a Steam account that owns Wallpaper Engine.

1. **Download from Workshop…** → **Install** SteamCMD (≈80 MB, stored next to your library).
2. Enter your Steam user name → **Sign In to Steam…**. A Terminal window opens where you type your password and Steam Guard code **directly into SteamCMD**. This is needed only once; SteamCMD remembers the session.
3. Paste one or more Workshop links → **Download and Add**.

Tip: filter the Workshop by *Type: Video* or *Web*. Scene items are removed after download because they can't play.

## Privacy & security

- No analytics, no network requests of its own. Network access happens only when you install SteamCMD (from Valve's CDN) or download Workshop items (through SteamCMD).
- Your Steam password is entered only in Terminal, into Valve's SteamCMD. Canlı Duvar never sees or stores it.
- Web wallpapers run in WebKit's sandboxed web content process and can read only files inside their own folder (verified: files elsewhere in your home folder can't be read). Like in Wallpaper Engine, a web wallpaper can still use the network — only add wallpapers you trust.
- Global shortcuts use the Carbon hot-key API, which needs no Accessibility permission.

## Building from source

Requirements: Xcode 15+ (Swift 5.9+) on macOS 14+.

```bash
git clone https://github.com/keremberkant/CanliDuvar.git
cd CanliDuvar
swift test                         # unit tests
scripts/build-app.sh               # → dist/Canlı Duvar.app (universal)
scripts/build-app.sh --install     # build and copy to /Applications
VERSION=1.2.0 scripts/build-app.sh --zip   # release zip + SHA-256
```

You can also open `Package.swift` in Xcode and run the `CanliDuvar` scheme.

### Project layout

```
Sources/
  CanliDuvarCore/      UI-free logic (unit tested)
    Wallpaper.swift      Wallpaper Engine project.json parsing, folder discovery
    Workshop.swift       Workshop link parsing, SteamCMD output parsing
    Coverage.swift       "Is this display covered by windows?" geometry
  CanliDuvar/          the app
    App/                 entry point, settings, shared model, Dock menu, global hot keys
    Desktop/             desktop-level windows, video/web/image views, pause conditions
    Library/             wallpaper library, async thumbnail cache
    Workshop/            SteamCMD install / sign-in / download
    UI/                  SwiftUI views
Resources/             localizations (en, tr), app icon
Tests/                 XCTest suite for CanliDuvarCore
scripts/               build-app.sh, make-icon.swift
```

### How it works

- One borderless `NSWindow` per display at `kCGDesktopWindowLevel` (below the icons, above the system wallpaper), on all Spaces, ignoring mouse events. Windows are reused across wallpaper changes.
- **Video:** a single `AVQueuePlayer` + `AVPlayerLooper` is shared by every display, so a clip is decoded once no matter how many monitors you have; `preferredMaximumResolution` caps decoding at the largest display's size.
- **Web:** `WKWebView` loading the project's file with read access limited to its folder; a small shim provides the Wallpaper Engine web API (`applyUserProperties`, `setPaused`, no-op audio/media listeners).
- **Pausing:** sleep / session notifications, IOKit power-source notifications, `NSProcessInfoPowerStateDidChange` for Low Power Mode, and a 2-second `CGWindowList` bounds check (no screen-recording permission needed) for covered displays.

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Translations especially: add `Resources/<lang>.lproj/Localizable.strings` using the English strings as keys.

## License

[MIT](LICENSE). Wallpaper Engine is a trademark of its respective owners; Steam and SteamCMD are trademarks of Valve Corporation.
