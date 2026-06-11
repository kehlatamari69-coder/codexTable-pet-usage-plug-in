#!/bin/zsh
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
MAX_LOG_MB="${MAX_LOG_MB:-200}"
KEEP_ARCHIVES="${KEEP_ARCHIVES:-0}"
ARCHIVE_DIR="$CODEX_HOME/log-archive"
LOG_PREFIX="$CODEX_HOME/logs_2.sqlite"
OVERLAY_DIR="$CODEX_HOME/pet-limits"

log() {
  if [[ "${VERBOSE:-0}" == "1" ]]; then
    print -r -- "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  fi
}

codex_is_running() {
  if [[ "${CODEX_LOG_CLEANUP_IGNORE_RUNNING:-0}" == "1" ]]; then
    return 1
  fi
  pgrep -f "/Applications/Codex.app" >/dev/null 2>&1
}

file_size_mb() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    print 0
    return
  fi
  local bytes
  bytes="$(stat -f%z "$file" 2>/dev/null || print 0)"
  print $(( (bytes + 1048575) / 1048576 ))
}

archive_current_logs() {
  local stamp target
  stamp="$(date '+%Y%m%d-%H%M%S')"
  target="$ARCHIVE_DIR/codex-logs-$stamp"
  mkdir -p "$target"

  local moved=0
  for file in "$LOG_PREFIX" "$LOG_PREFIX-shm" "$LOG_PREFIX-wal"; do
    if [[ -e "$file" ]]; then
      mv "$file" "$target/"
      moved=1
    fi
  done

  if [[ "$moved" -eq 1 ]]; then
    log "Archived Codex logs to $target"
  fi
}

prune_old_archives() {
  [[ -d "$ARCHIVE_DIR" ]] || return 0
  local archives
  archives=("${(@f)$(find "$ARCHIVE_DIR" -maxdepth 1 -type d -name 'codex-logs-*' | sort -r)}")
  local index=0
  for archive in "${archives[@]}"; do
    index=$((index + 1))
    if (( index > KEEP_ARCHIVES )); then
      rm -rf "$archive"
      log "Removed cached log archive $archive"
    fi
  done
}

trim_overlay_logs() {
  [[ -d "$OVERLAY_DIR" ]] || return 0
  for file in "$OVERLAY_DIR/launch-agent.out.log" "$OVERLAY_DIR/launch-agent.err.log" "$OVERLAY_DIR/cleanup-agent.log"; do
    rm -f "$file"
  done
}

main() {
  mkdir -p "$CODEX_HOME"
  trim_overlay_logs

  local size_mb
  size_mb="$(file_size_mb "$LOG_PREFIX")"
  if (( size_mb < MAX_LOG_MB )); then
    log "Codex log size ${size_mb}MB is below ${MAX_LOG_MB}MB; nothing to clean."
    prune_old_archives
    return 0
  fi

  if codex_is_running; then
    log "Codex is running; skip SQLite cleanup. Current log size: ${size_mb}MB."
    prune_old_archives
    return 0
  fi

  archive_current_logs
  prune_old_archives
  log "Cleanup complete. Codex will create a fresh log database on next launch."
}

main "$@"
