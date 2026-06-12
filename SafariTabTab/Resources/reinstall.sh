#!/bin/bash
set -euo pipefail

find_project_dir() {
  if [[ -n "${SAFARI_TAB_TAB_PROJECT_DIR:-}" && -f "${SAFARI_TAB_TAB_PROJECT_DIR}/Scripts/install.sh" ]]; then
    printf '%s' "$SAFARI_TAB_TAB_PROJECT_DIR"
    return 0
  fi

  for candidate in "$HOME/Documents/safari-tab-tab" "$HOME/Documents/tabtabextension"; do
    if [[ -f "$candidate/Scripts/install.sh" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done

  return 1
}

PROJECT_DIR="$(find_project_dir || true)"
SCRIPT="${PROJECT_DIR:+$PROJECT_DIR/Scripts/install.sh}"

if [[ -z "$SCRIPT" || ! -f "$SCRIPT" ]]; then
  osascript -e "display alert \"Safari Tab Tab\" message \"Could not find the project. Clone it to ~/Documents/safari-tab-tab or set SAFARI_TAB_TAB_PROJECT_DIR.\""
  exit 1
fi

exec "$SCRIPT" "$@"
