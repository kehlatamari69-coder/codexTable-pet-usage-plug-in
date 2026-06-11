#!/bin/zsh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST="$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-watcher.plist"
OLD_PLIST="$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.yy.codex-pet-limits-watcher</string>
  <key>ProgramArguments</key>
  <array>
    <string>$DIR/watch-codex-pet-limits.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>30</integer>
  <key>StandardOutPath</key>
  <string>/dev/null</string>
  <key>StandardErrorPath</key>
  <string>/dev/null</string>
</dict>
</plist>
PLIST

chmod +x "$DIR/watch-codex-pet-limits.sh"
launchctl bootout "gui/$(id -u)" "$OLD_PLIST" 2>/dev/null || true
if [[ -f "$OLD_PLIST" ]]; then
  mv "$OLD_PLIST" "$OLD_PLIST.disabled"
fi
launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl kickstart -k "gui/$(id -u)/com.yy.codex-pet-limits-watcher"
echo "Installed watcher LaunchAgent: $PLIST"
