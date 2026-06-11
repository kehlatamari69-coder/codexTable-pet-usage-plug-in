#!/bin/zsh
set -euo pipefail

PLIST="$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist"
APP="$HOME/Applications/CodexPetLimits.app"

for label in com.yy.codex-pet-limits com.yy.codex-pet-limits-watcher com.yy.codex-pet-limits-cleanup; do
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
done
pkill -f "$APP/Contents/MacOS/CodexPetLimits" 2>/dev/null || true
pkill -f "CodexPetLimitOverlay" 2>/dev/null || true
rm -f \
  "$PLIST" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist.disabled" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-watcher.plist" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-watcher.plist.disabled" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-cleanup.plist" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-cleanup.plist.disabled"
rm -rf "$APP"
rm -rf "$HOME/.codex/pet-limits"
echo "Uninstalled CodexPetLimits.app"
