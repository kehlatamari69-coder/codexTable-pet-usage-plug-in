#!/bin/zsh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$DIR/overlay.pid"

if [[ -f "$PID_FILE" ]]; then
  PID="$(cat "$PID_FILE")"
  if kill -0 "$PID" 2>/dev/null; then
    kill "$PID"
    echo "Stopped Codex pet limit overlay: $PID"
  fi
  rm -f "$PID_FILE"
else
  pkill -f "CodexPetLimitOverlay" 2>/dev/null || true
  echo "Stopped any CodexPetLimitOverlay process."
fi
