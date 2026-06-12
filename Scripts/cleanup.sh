#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Safari Tab Tab"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }

bold "Safari Tab Tab — cleanup"

cat <<'EOF'
First in Safari (if it is open):
  Safari → Settings → Extensions
  Select EACH "Safari Tab Tab Extension" → Uninstall
  (repeat for all duplicates)

EOF

read -r -p "Did you uninstall all Safari Tab Tab extensions in Safari? [y/N] " answer
if [[ "${answer,,}" != "y" ]]; then
  echo "Open Safari → Settings → Extensions, uninstall all copies, then run this again."
  exit 1
fi

bold "Quitting Safari and Safari Tab Tab"
osascript -e 'tell application "Safari" to quit' 2>/dev/null || true
osascript -e 'tell application "Safari Tab Tab" to quit' 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 1

bold "Removing app bundles"
rm -rf "/Applications/$APP_NAME.app"
rm -rf "/Applications/TabTab.app"

bold "Removing local build artifacts"
rm -rf "$PROJECT_DIR/.derivedData"
rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/SafariTabTab-*

bold "Unregistering extension plugin"
pluginkit -r -i com.1kub.safaritabtab.extension 2>/dev/null || true
pluginkit -r -i local.tabtab.extension 2>/dev/null || true

bold "Done."
echo "Now run a single clean install:"
echo "  $PROJECT_DIR/Scripts/install.sh"
