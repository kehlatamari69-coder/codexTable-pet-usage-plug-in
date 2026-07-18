#!/bin/zsh
set -euo pipefail

PLIST="$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist"
APP="$HOME/Applications/CodexPetLimits.app"

launchctl bootout "gui/$(id -u)/com.yy.codex-pet-limits" 2>/dev/null || true
pkill -f "$APP/Contents/MacOS/CodexPetLimits" 2>/dev/null || true
rm -f "$PLIST"
rm -rf "$APP"
echo "Uninstalled CodexPetLimits.app"
