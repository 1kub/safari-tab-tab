#!/bin/bash
set -euo pipefail

PROJECT_DIR="${TABTAB_PROJECT_DIR:-$HOME/Documents/tabtabextension}"
SCRIPT="$PROJECT_DIR/Scripts/reinstall.sh"

if [[ ! -f "$SCRIPT" ]]; then
  osascript -e "display alert \"TabTab\" message \"Nenašiel som projekt v $PROJECT_DIR. Nastav TABTAB_PROJECT_DIR alebo spusti Scripts/reinstall.sh z Terminálu.\""
  exit 1
fi

exec "$SCRIPT" "$@"
