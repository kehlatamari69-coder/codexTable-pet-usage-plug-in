#!/bin/zsh
set -euo pipefail

for label in com.yy.codex-pet-limits com.yy.codex-pet-limits-watcher com.yy.codex-pet-limits-cleanup; do
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
done

for plist in \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits.plist" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-watcher.plist" \
  "$HOME/Library/LaunchAgents/com.yy.codex-pet-limits-cleanup.plist"
do
  if [[ -f "$plist" ]]; then
    mv "$plist" "$plist.disabled"
    echo "Disabled $plist"
  fi
done

pkill -f "CodexPetLimitOverlay" 2>/dev/null || true
echo "Stopped Codex pet usage agents."
