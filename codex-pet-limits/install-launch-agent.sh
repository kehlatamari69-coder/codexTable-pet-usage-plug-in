#!/bin/zsh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/install-watcher-agent.sh"
