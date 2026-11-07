#!/bin/zsh
# Builds "Canlı Duvar.app" (universal: Apple silicon + Intel) into ./dist.
#
#   scripts/build-app.sh             build the app
#   scripts/build-app.sh --zip       also create dist/CanliDuvar-<version>.zip for a release
#   scripts/build-app.sh --install   also copy it to /Applications
#
# VERSION env var sets the version (default: latest git tag, or 0.0.0-dev).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)}"
VERSION="${VERSION:-0.0.0-dev}"
BUILD_NUMBER="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
APP_NAME="Canlı Duvar"
APP="dist/$APP_NAME.app"

echo "→ Building $APP_NAME $VERSION ($BUILD_NUMBER)…"
swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/CanliDuvar"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/CanliDuvar"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
cp -R Resources/*.lproj "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>com.catkayastudio.canliduvar</string>
    <key>CFBundleExecutable</key><string>CanliDuvar</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$BUILD_NUMBER</string>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key><array><string>en</string><string>tr</string></array>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>MIT License</string>
</dict>
</plist>
PLIST

# Ad-hoc signature (no Apple Developer ID). Downloaded copies need right-click → Open the first time.
codesign --force --deep --sign - "$APP"
echo "✓ $APP"

for arg in "$@"; do
    case "$arg" in
        --zip)
            ZIP="dist/CanliDuvar-$VERSION.zip"
            rm -f "$ZIP"
            ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
            shasum -a 256 "$ZIP" | tee "$ZIP.sha256"
            echo "✓ $ZIP"
            ;;
        --install)
            pkill -x CanliDuvar 2>/dev/null || true
            rm -rf "/Applications/$APP_NAME.app"
            cp -R "$APP" /Applications/
            echo "✓ Installed to /Applications/$APP_NAME.app"
            ;;
    esac
done
