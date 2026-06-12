#!/bin/bash
set -euo pipefail

APP="/Applications/Safari Tab Tab.app"
BUNDLE_ID="com.1kub.safaritabtab.extension"
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

bold "Safari Tab Tab — diagnostics"
echo

if [[ -d "$APP" ]]; then
  ok "App installed at $APP"
else
  fail "App not found in /Applications — run: ./Scripts/install.sh"
  exit 1
fi

if [[ -d "$APP/Contents/PlugIns/Safari Tab Tab Extension.appex" ]]; then
  ok "Extension embedded in app bundle"
else
  fail "Missing .appex inside app bundle"
fi

COUNT=$(pluginkit -m -i "$BUNDLE_ID" -v 2>/dev/null | grep -c "\.appex" || true)
if [[ "$COUNT" -eq 1 ]]; then
  ok "Single extension registration in system"
  pluginkit -m -i "$BUNDLE_ID" -v 2>/dev/null | sed 's/^/    /'
elif [[ "$COUNT" -eq 0 ]]; then
  fail "Extension not registered — run: ./Scripts/install.sh"
else
  warn "Found $COUNT extension copies — run: ./Scripts/cleanup.sh && ./Scripts/install.sh"
fi

if pgrep -x "Safari Tab Tab" >/dev/null; then
  ok "Menu bar app is running"
else
  warn "Menu bar app not running — launching..."
  open "$APP"
  sleep 2
  pgrep -x "Safari Tab Tab" >/dev/null && ok "Menu bar app launched" || fail "Failed to launch app"
fi

if pgrep -x "Safari" >/dev/null; then
  ok "Safari is running"
else
  warn "Safari not running — opening"
  open -a Safari
fi

if pgrep -lf "Safari Tab Tab Extension" >/dev/null; then
  ok "Extension process running in Safari"
  pgrep -lf "Safari Tab Tab Extension" | sed 's/^/    /'
else
  warn "Extension process not running — enable it in Safari → Settings → Extensions"
fi

if codesign -d --entitlements - "$APP" 2>/dev/null | grep -q "app-sandbox"; then
  fail "Main app is still sandboxed — reinstall"
else
  ok "Main app is not sandboxed (hotkey works without Accessibility)"
fi

echo
bold "Required in Safari:"
echo "  1. Safari → Settings → Extensions"
echo "  2. Turn ON \"Safari Tab Tab Extension\""
echo "  3. Click it → \"Always Allow on Every Website\""
echo
bold "Test:"
echo "  1. Open 2–3 tabs in Safari"
echo "  2. Click the \"Switch Tab\" button in the Safari toolbar (blue ⇄ icon)"
echo "     → should switch to the previous tab"
echo "  3. Then try Control+Tab"
echo
bold "The background app has no Dock icon and no menu bar icon."
echo "To stop it: pkill -x \"Safari Tab Tab\""
echo
bold "No Accessibility permission is required."
