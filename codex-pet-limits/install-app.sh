#!/bin/zsh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_APP="$DIR/CodexPetLimits.app"
TARGET_DIR="$HOME/Applications"
TARGET_APP="$TARGET_DIR/CodexPetLimits.app"
PLIST="$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist"

for label in com.yy.codex-pet-limits com.yy.codex-pet-limits-watcher com.yy.codex-pet-limits-cleanup; do
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
done
rm -f \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist.disabled" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-watcher.plist" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-watcher.plist.disabled" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-cleanup.plist" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-cleanup.plist.disabled"
pkill -f "CodexPetLimitOverlay" 2>/dev/null || true
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
    <string>/usr/bin/open</string>
    <string>-gja</string>
    <string>$TARGET_APP</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
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
