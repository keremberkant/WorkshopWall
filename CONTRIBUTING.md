# Contributing

Thanks for helping! Bug reports, ideas, translations and pull requests are all welcome.

## Development

```bash
swift test                       # run the unit tests
scripts/build-app.sh --install   # build and install the app
```

Open `Package.swift` in Xcode if you prefer an IDE.

- Logic that doesn't need AppKit/SwiftUI goes into `Sources/CanliDuvarCore` and gets a test in `Tests/`.
- UI strings are written in English and wrapped so they're localizable (`Text("…")`, `String(localized: "…")`).
  Add the Turkish translation to `Resources/tr.lproj/Localizable.strings` (or note it in your PR).
- Keep the app dependency-free and battery-friendly: nothing should run while every display is paused.

## Pull requests

1. Fork and create a branch.
2. Make sure `swift test` passes and the app builds with `scripts/build-app.sh`.
3. Describe what changed and how you tested it (which wallpaper types, how many displays).

## Translations

Copy `Resources/tr.lproj` to `Resources/<language>.lproj`, translate the right-hand side of each line,
and add the language code to `CFBundleLocalizations` in `scripts/build-app.sh`.

## Please don't

- Commit wallpapers, Workshop content or SteamCMD binaries — they belong to their creators / Valve.
- Add analytics or network calls.
