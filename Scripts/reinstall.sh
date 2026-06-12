#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="TabTab"
PROJECT="$PROJECT_DIR/TabTab.xcodeproj"
CONFIGURATION="${1:-Debug}"

echo "→ Build TabTab ($CONFIGURATION)"
cd "$PROJECT_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$PROJECT_DIR/.derivedData" \
  build

APP_PATH="$PROJECT_DIR/.derivedData/Build/Products/$CONFIGURATION/TabTab.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Chyba: nenašiel som $APP_PATH" >&2
  exit 1
fi

echo "→ Inštalujem do /Applications/TabTab.app"
rm -rf "/Applications/TabTab.app"
ditto "$APP_PATH" "/Applications/TabTab.app"

echo "→ Spúšťam TabTab"
open -a "/Applications/TabTab.app"

cat <<EOF

Hotovo.
1. Otvor Safari → Nastavenia → Rozšírenia
2. Zapni „TabTab Extension“
3. Povoľ na všetkých weboch

Bezplatný podpis vyprší o 7 dní — spusti znova:
  $PROJECT_DIR/Scripts/reinstall.sh
EOF
