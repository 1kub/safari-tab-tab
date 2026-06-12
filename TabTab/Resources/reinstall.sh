#!/bin/bash
set -euo pipefail

PROJECT_DIR="${TABTAB_PROJECT_DIR:-$HOME/Documents/tabtabextension}"
SCRIPT="$PROJECT_DIR/Scripts/reinstall.sh"

if [[ ! -f "$SCRIPT" ]]; then
  osascript -e "display alert \"Safari Tab Tab\" message \"Could not find the project at $PROJECT_DIR. Set TABTAB_PROJECT_DIR or run Scripts/reinstall.sh from Terminal.\""
  exit 1
fi

exec "$SCRIPT" "$@"
