#!/usr/bin/env bash
# Assembles a runnable, ad-hoc-signed Buddy.app so CoreBluetooth gets a
# stable identity + the Info.plist usage string it needs for TCC permission.
#
#   ./Packaging/make-app.sh [debug|release]
#
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
swift build -c "$CONFIG"

BIN_DIR=".build/$CONFIG"
APP="$BIN_DIR/Buddy.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/Buddy" "$APP/Contents/MacOS/Buddy"
cp Packaging/Info.plist "$APP/Contents/Info.plist"

# Copy SwiftPM resource bundles (e.g. Buddy_BudsUI.bundle) so Bundle.module resolves.
for bundle in "$BIN_DIR"/*.bundle; do
  [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

# Ad-hoc sign so macOS gives the app a persistent identity for TCC.
codesign --force --deep --sign - "$APP"

echo "Built $APP"
echo "Run it with:  ./$APP/Contents/MacOS/Buddy"
