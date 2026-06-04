#!/bin/zsh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/CodexPetLimitOverlay"
PID_FILE="$DIR/overlay.pid"

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Codex pet limit overlay is already running: $(cat "$PID_FILE")"
  exit 0
fi

"$APP" >/dev/null 2>&1 &
echo $! > "$PID_FILE"
echo "Started Codex pet limit overlay: $(cat "$PID_FILE")"
