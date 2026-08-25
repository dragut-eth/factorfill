#!/bin/bash
# Build → sign (Developer ID + hardened runtime) → notarize → staple → zip.
# Usage: bash notarize.sh v0.1.0
#
# Requires in .env:
#   RELEASE_IDENTITY="Developer ID Application: ReVeNG System (HST4KH9P2X)"
#   NOTARY_PROFILE="factorfill-notary"   # a stored notarytool credential (see README)
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$DIR/.env" ]; then set -a; . "$DIR/.env"; set +a; fi

APP="$DIR/FactorFill.app"
IDENTITY="${RELEASE_IDENTITY:?set RELEASE_IDENTITY in .env}"
PROFILE="${NOTARY_PROFILE:-factorfill-notary}"
VERSION="${1:?usage: bash notarize.sh <version, e.g. v0.1.0>}"
DIST="$DIR/dist"
ZIP="$DIST/FactorFill-$VERSION.zip"

echo "1/5  Building…"
bash "$DIR/build.sh" >/dev/null

echo "2/5  Signing with Developer ID + hardened runtime…"
xattr -cr "$APP"
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
codesign --verify --strict --verbose=2 "$APP"

echo "3/5  Zipping…"
mkdir -p "$DIST"
rm -f "$ZIP"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"

echo "4/5  Notarizing (waits for Apple — usually 1–5 min)…"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

echo "5/5  Stapling ticket…"
xcrun stapler staple "$APP"
rm -f "$ZIP"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"   # re-zip the stapled app

echo
echo "Done: $ZIP"
echo "Verify: spctl -a -vvv \"$APP\"   (should say: accepted, source=Notarized Developer ID)"
echo "Release: gh release create $VERSION \"$ZIP\" --notes \"…\""
