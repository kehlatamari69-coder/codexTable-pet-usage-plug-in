#!/bin/zsh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_APP="$DIR/CodexPetLimits.app"
TARGET_DIR="$HOME/Applications"
TARGET_APP="$TARGET_DIR/CodexPetLimits.app"
PLIST="$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist"

launchctl bootout "gui/$(id -u)/com.yy.codex-pet-limits" 2>/dev/null || true
rm -f "$PLIST"
pkill -f "$TARGET_APP/Contents/MacOS/CodexPetLimits" 2>/dev/null || true

if [[ ! -d "$SOURCE_APP" ]]; then
  "$DIR/build-app.sh"
fi

mkdir -p "$TARGET_DIR"
rm -rf "$TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"
codesign --force --deep --sign - "$TARGET_APP"
cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.yy.codex-pet-limits</string>
  <key>ProgramArguments</key>
  <array>
    <string>$TARGET_APP/Contents/MacOS/CodexPetLimits</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>30</integer>
  <key>StandardOutPath</key>
  <string>/dev/null</string>
  <key>StandardErrorPath</key>
  <string>/dev/null</string>
</dict>
</plist>
PLIST

launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl kickstart -k "gui/$(id -u)/com.yy.codex-pet-limits"
echo "Installed $TARGET_APP"
