#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
swift build --package-path "$root" -c release
app="$root/dist/Moonlight Location Guard.app"
rm -rf "$app"; mkdir -p "$app/Contents/MacOS"
cp "$root/.build/release/MoonlightLocationGuard" "$app/Contents/MacOS/"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Moonlight Location Guard</string>
  <key>CFBundleIdentifier</key><string>fi.sulopuisto.moonlight-location-guard</string>
  <key>CFBundleExecutable</key><string>MoonlightLocationGuard</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - --deep "$app"
echo "Built: $app"
