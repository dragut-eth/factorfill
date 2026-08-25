#!/bin/bash
# Build → sign (Developer ID + hardened runtime) → notarize → staple → zip.
# Usage: bash notarize.sh v0.1.0
#
# Signs in a temp dir OUTSIDE iCloud: this repo lives in ~/Documents, which is
# iCloud-synced, and iCloud re-stamps the bundle with com.apple.FinderInfo right
# after signing — which makes codesign fail with "detritus not allowed". Working
# in /private/tmp avoids that race.
#
# Requires in .env:
#   RELEASE_IDENTITY="Developer ID Application: ReVeNG System (HST4KH9P2X)"
#   NOTARY_PROFILE="factorfill-notary"   # a stored notarytool credential (see README)
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$DIR/.env" ]; then set -a; . "$DIR/.env"; set +a; fi

IDENTITY="${RELEASE_IDENTITY:?set RELEASE_IDENTITY in .env}"
PROFILE="${NOTARY_PROFILE:-factorfill-notary}"
VERSION="${1:?usage: bash notarize.sh <version, e.g. v0.1.0>}"

APP="$DIR/FactorFill.app"
DIST="$DIR/dist"
ZIP="$DIST/FactorFill-$VERSION.zip"

WORK="$(mktemp -d /private/tmp/factorfill-release.XXXXXX)"
RELEASE_APP="$WORK/FactorFill.app"
trap 'rm -rf "$WORK"' EXIT

echo "1/5  Building (unsigned)…"
SKIP_SIGN=1 bash "$DIR/build.sh" >/dev/null

echo "2/5  Copy to $WORK + Developer ID sign (hardened runtime)…"
/usr/bin/ditto --noextattr --norsrc "$APP" "$RELEASE_APP"
xattr -cr "$RELEASE_APP"
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$RELEASE_APP"
codesign --verify --strict --verbose=2 "$RELEASE_APP"

echo "3/5  Zipping…"
mkdir -p "$DIST"
rm -f "$ZIP"
/usr/bin/ditto -c -k --keepParent "$RELEASE_APP" "$ZIP"

echo "4/5  Notarizing (waits for Apple — usually 1–5 min)…"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

echo "5/5  Stapling ticket…"
xcrun stapler staple "$RELEASE_APP"
rm -f "$ZIP"
/usr/bin/ditto -c -k --keepParent "$RELEASE_APP" "$ZIP"   # re-zip the stapled app

echo
echo "Done: $ZIP"
echo "Verify: spctl -a -vvv \"$RELEASE_APP\" (temp copy) — expect: accepted, source=Notarized Developer ID"
echo "Release: gh release create $VERSION \"$ZIP\" --notes \"…\""
