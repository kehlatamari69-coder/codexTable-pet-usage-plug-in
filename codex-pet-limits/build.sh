#!/bin/zsh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

swiftc "$DIR/CodexPetLimitOverlay.swift" -o "$DIR/CodexPetLimitOverlay"
codesign --force --deep --sign - "$DIR/CodexPetLimitOverlay"

echo "Built $DIR/CodexPetLimitOverlay"
