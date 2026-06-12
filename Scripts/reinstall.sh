#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="TabTab"
PROJECT="$PROJECT_DIR/TabTab.xcodeproj"
CONFIGURATION="${1:-Debug}"

echo "→ Building Safari Tab Tab ($CONFIGURATION)"
cd "$PROJECT_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$PROJECT_DIR/.derivedData" \
  build

APP_PATH="$PROJECT_DIR/.derivedData/Build/Products/$CONFIGURATION/TabTab.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: could not find $APP_PATH" >&2
  exit 1
fi

echo "→ Installing to /Applications/TabTab.app"
rm -rf "/Applications/TabTab.app"
ditto "$APP_PATH" "/Applications/TabTab.app"

echo "→ Launching Safari Tab Tab"
open -a "/Applications/TabTab.app"

cat <<EOF

Done.
1. Open Safari → Settings → Extensions
2. Enable "Safari Tab Tab Extension"
3. Allow on all websites

Free provisioning expires in about 7 days — run again:
  $PROJECT_DIR/Scripts/reinstall.sh
EOF
