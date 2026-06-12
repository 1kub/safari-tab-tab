#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="SafariTabTab"
PROJECT="$PROJECT_DIR/SafariTabTab.xcodeproj"
CONFIGURATION="${CONFIGURATION:-Debug}"
APP_NAME="Safari Tab Tab"
INSTALL_PATH="/Applications/$APP_NAME.app"
TEAM_FILE="$PROJECT_DIR/.xcode-team"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
step() { printf '\n→ %s\n' "$*"; }

require_xcode() {
  if ! xcode-select -p &>/dev/null; then
  bold "Xcode is required."
  echo "Install Xcode from the App Store, then run: xcode-select --install"
  exit 1
  fi
}

open_xcode_setup() {
  step "Opening Xcode for one-time signing setup"
  open "$PROJECT"
  cat <<'EOF'

One-time setup in Xcode (about 1 minute):
  1. Wait for Xcode to load the project
  2. Click the blue "SafariTabTab" project icon (left sidebar)
  3. Select target "Safari Tab Tab" → Signing & Capabilities → Team → your Apple ID
  4. Select target "Safari Tab Tab Extension" → same Team
  5. Press ⌘B to build once

Then run again:
  ./Scripts/install.sh

Tip: save your Team ID to skip Xcode next time:
  echo YOUR_TEAM_ID > .xcode-team
EOF
}

resolve_team_id() {
  if [[ -n "${SAFARI_TAB_TAB_TEAM_ID:-}" ]]; then
    printf '%s' "$SAFARI_TAB_TAB_TEAM_ID"
    return 0
  fi

  if [[ -f "$TEAM_FILE" ]]; then
    tr -d '[:space:]' < "$TEAM_FILE"
    return 0
  fi

  local from_settings
  from_settings="$(
    xcodebuild \
      -project "$PROJECT" \
      -target "Safari Tab Tab" \
      -configuration "$CONFIGURATION" \
      -showBuildSettings 2>/dev/null \
      | sed -n 's/^ *DEVELOPMENT_TEAM = //p' \
      | head -1 \
      | tr -d '[:space:]'
  )"

  if [[ -n "$from_settings" ]]; then
    printf '%s' "$from_settings"
    return 0
  fi

  return 1
}

run_setup_mode() {
  require_xcode
  open_xcode_setup
}

dedupe_before_install() {
  step "Ensuring a single Safari Tab Tab installation"

  osascript -e 'tell application "Safari" to quit' 2>/dev/null || true
  osascript -e 'tell application "Safari Tab Tab" to quit' 2>/dev/null || true
  pkill -f "Safari Tab Tab Extension" 2>/dev/null || true
  pkill -x "$APP_NAME" 2>/dev/null || true
  sleep 1

  rm -rf "/Applications/TabTab.app"
  rm -rf "$INSTALL_PATH"
  rm -rf "$PROJECT_DIR/.derivedData/Build/Products" 2>/dev/null || true
  rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/SafariTabTab-* 2>/dev/null || true

  pluginkit -r -i com.1kub.safaritabtab.extension 2>/dev/null || true
  pluginkit -r -i local.tabtab.extension 2>/dev/null || true
}

run_install() {
  require_xcode
  cd "$PROJECT_DIR"

  dedupe_before_install

  step "Generating icons"
  python3 "$PROJECT_DIR/Scripts/generate_icons.py"

  local team_id=""
  if team_id="$(resolve_team_id)"; then
    step "Using development team: $team_id"
  else
    bold "Signing is not configured yet."
    open_xcode_setup
    exit 1
  fi

  step "Building $APP_NAME"
  set +e
  local build_output
  build_output="$(
    xcodebuild \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -configuration "$CONFIGURATION" \
      -derivedDataPath "$PROJECT_DIR/.derivedData" \
      DEVELOPMENT_TEAM="$team_id" \
      -allowProvisioningUpdates \
      build 2>&1
  )"
  local build_status=$?
  set -e

  if [[ $build_status -ne 0 ]]; then
    echo "$build_output" >&2
    echo >&2
    bold "Build failed."
    if echo "$build_output" | grep -qi "signing\|provision\|certificate\|team"; then
      open_xcode_setup
    fi
    exit "$build_status"
  fi

  local app_path="$PROJECT_DIR/.derivedData/Build/Products/$CONFIGURATION/$APP_NAME.app"
  if [[ ! -d "$app_path" ]]; then
    echo "Error: could not find $app_path" >&2
    exit 1
  fi

  step "Installing to $INSTALL_PATH"
  rm -rf "$INSTALL_PATH"
  ditto "$app_path" "$INSTALL_PATH"
  xattr -dr com.apple.quarantine "$INSTALL_PATH" 2>/dev/null || true

  step "Launching $APP_NAME"
  pkill -x "$APP_NAME" 2>/dev/null || true
  sleep 1
  open -a "$INSTALL_PATH"
  sleep 2
  if ! pgrep -x "$APP_NAME" >/dev/null; then
    bold "Warning: app did not start — try: open \"$INSTALL_PATH\""
  fi

  step "Opening Safari"
  open -a Safari

  cat <<EOF

$(bold "Important: NOT System Settings → Extensions")
Safari extensions are configured inside the Safari app.

$(bold "Enable the extension (in Safari):")
  1. In the menu bar click Safari (next to the Apple logo)
  2. Choose "Settings…" (or press ⌘,)
  3. Open the "Extensions" tab
  4. Turn ON "Safari Tab Tab Extension"
  5. Click it → "Always Allow on Every Website"
  6. Keep the "Switch Tab" button in the Safari toolbar

$(bold "How to switch tabs:")
  • Click "Switch Tab" in the Safari toolbar (blue ⇄ icon)
  • Or press Control+Tab in Safari

$(bold "Background app:")
  Runs invisibly (no Dock icon). To stop: pkill -x "Safari Tab Tab"

If Safari shows multiple "Safari Tab Tab Extension" entries:
  Uninstall ALL of them in Safari → Extensions, then run ./Scripts/install.sh once.

Re-install (free Apple ID expires ~every 7 days):
  ./Scripts/install.sh

Diagnostika:
  ./Scripts/verify.sh
EOF

  step "Running diagnostics"
  "$(cd "$(dirname "$0")" && pwd)/verify.sh" || true
}

case "${1:-}" in
  --setup|-s|setup)
    run_setup_mode
    ;;
  --clean|-c|clean)
    exec "$(cd "$(dirname "$0")" && pwd)/cleanup.sh"
    ;;
  --help|-h)
    cat <<EOF
Usage:
  ./Scripts/install.sh          Build, install, open Safari settings
  ./Scripts/install.sh --setup  One-time Xcode signing help
  ./Scripts/install.sh --clean  Remove duplicates, then install again

Optional:
  SAFARI_TAB_TAB_TEAM_ID=ABCDE12345 ./Scripts/install.sh
  echo ABCDE12345 > .xcode-team
EOF
    ;;
  *)
    run_install
    ;;
esac
