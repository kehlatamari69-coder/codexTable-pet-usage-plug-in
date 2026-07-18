#!/bin/zsh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/CodexPetLimits.app"
MACOS="$APP/Contents/MacOS"
RESOURCES="$APP/Contents/Resources"
ICON_SOURCE="$DIR/assets/CodexPetLimits.icns"
BUILD_CACHE="$(mktemp -d "${TMPDIR:-/tmp}/codex-pet-limits-build.XXXXXX")"
trap 'rm -rf "$BUILD_CACHE"' EXIT

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"

[[ -f "$ICON_SOURCE" ]] && cp "$ICON_SOURCE" "$RESOURCES/CodexPetLimits.icns"

SWIFT_ARGS=(-module-cache-path "$BUILD_CACHE/module-cache")
COMPATIBLE_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ -d "$COMPATIBLE_SDK" ]]; then
  SWIFT_ARGS+=(-sdk "$COMPATIBLE_SDK" -target "$(uname -m)-apple-macosx13.0")
fi

swiftc "${SWIFT_ARGS[@]}" "$DIR/CodexPetLimitOverlay.swift" -o "$MACOS/CodexPetLimits"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>CodexPetLimits</string>
  <key>CFBundleIdentifier</key>
  <string>com.yy.codex-pet-limits</string>
  <key>CFBundleName</key>
  <string>Codex Pet Limits</string>
  <key>CFBundleIconFile</key>
  <string>CodexPetLimits</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.3</string>
  <key>CFBundleVersion</key>
  <string>10</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
echo "Built $APP"
