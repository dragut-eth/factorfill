#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/FactorFill.app"
BIN="$APP/Contents/MacOS/FactorFill"

echo "Building FactorFill.app…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O "$DIR"/Sources/FactorFill/*.swift \
    -o "$BIN" \
    -framework AppKit \
    -framework ApplicationServices \
    -framework ServiceManagement

cp "$DIR/Resources/Info.plist" "$APP/Contents/Info.plist"

# Sign with a stable identity so macOS keeps the Accessibility grant across
# rebuilds. Falls back to ad-hoc if the cert isn't present.
xattr -cr "$APP"
IDENTITY="Apple Development: Xavier Cany (VY6KZKP7W7)"
if security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
    codesign --force --sign "$IDENTITY" "$APP"
    echo "Signed with: $IDENTITY"
else
    codesign --force --sign - "$APP"
    echo "Signed ad-hoc (stable cert not found — Accessibility grant won't persist across rebuilds)"
fi

echo "Built: $APP"
