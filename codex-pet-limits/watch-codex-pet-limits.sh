#!/bin/zsh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
OVERLAY="$DIR/CodexPetLimitOverlay"

codex_is_running() {
  ps -axo args= | grep -F "/Applications/Codex.app/Contents/MacOS/Codex" | grep -v grep >/dev/null 2>&1
}

overlay_is_running() {
  pgrep -f "$OVERLAY" >/dev/null 2>&1
}

if codex_is_running; then
  if ! overlay_is_running; then
    "$OVERLAY" >/dev/null 2>&1 &
  fi
else
  pkill -f "$OVERLAY" 2>/dev/null || true
fi
