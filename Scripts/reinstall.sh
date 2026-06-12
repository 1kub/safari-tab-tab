#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="SafariTabTab"
PROJECT="$PROJECT_DIR/SafariTabTab.xcodeproj"
CONFIGURATION="${1:-Debug}"
APP_NAME="Safari Tab Tab"

echo "→ Building $APP_NAME ($CONFIGURATION)"
cd "$PROJECT_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$PROJECT_DIR/.derivedData" \
  build

APP_PATH="$PROJECT_DIR/.derivedData/Build/Products/$CONFIGURATION/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: could not find $APP_PATH" >&2
  exit 1
fi

INSTALL_PATH="/Applications/$APP_NAME.app"
echo "→ Installing to $INSTALL_PATH"
rm -rf "$INSTALL_PATH"
ditto "$APP_PATH" "$INSTALL_PATH"

echo "→ Launching $APP_NAME"
open -a "$INSTALL_PATH"

cat <<EOF

Done.
1. Open Safari → Settings → Extensions
2. Enable "Safari Tab Tab Extension"
3. Allow on all websites

Free provisioning expires in about 7 days — run again:
  $PROJECT_DIR/Scripts/reinstall.sh
EOF
