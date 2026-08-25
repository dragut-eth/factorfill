#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/FactorFill.app"
BIN="$APP/Contents/MacOS/FactorFill"

# Local, untracked config (e.g. CODESIGN_IDENTITY). See .env.example.
if [ -f "$DIR/.env" ]; then
    set -a; . "$DIR/.env"; set +a
fi

echo "Building FactorFill.app…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O "$DIR"/Sources/FactorFill/*.swift \
    -o "$BIN" \
    -framework AppKit \
    -framework ApplicationServices \
    -framework ServiceManagement

cp "$DIR/Resources/Info.plist" "$APP/Contents/Info.plist"

# App icon
mkdir -p "$APP/Contents/Resources"
cp "$DIR/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

# Signing. Set CODESIGN_IDENTITY to your "Apple Development: …" identity for a
# stable signature, which lets macOS keep the Accessibility grant across
# rebuilds. Unset → ad-hoc signing (works, but macOS re-prompts for
# Accessibility after each rebuild). List identities:
#   security find-identity -v -p codesigning
# SKIP_SIGN=1 leaves the app unsigned (notarize.sh signs a clean copy itself).
if [ "${SKIP_SIGN:-}" = "1" ]; then
    echo "Skipped signing (SKIP_SIGN=1)"
else
    xattr -cr "$APP"
    IDENTITY="${CODESIGN_IDENTITY:-}"
    if [ -n "$IDENTITY" ] && security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
        codesign --force --sign "$IDENTITY" "$APP"
        echo "Signed with: $IDENTITY"
    else
        codesign --force --sign - "$APP"
        echo "Signed ad-hoc (set CODESIGN_IDENTITY for a stable signature)"
    fi
fi

echo "Built: $APP"
