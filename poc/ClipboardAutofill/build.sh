#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/ClipFill.app"
BIN="$APP/Contents/MacOS/ClipFill"

echo "Building ClipFill.app…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O "$DIR/main.swift" -o "$BIN" \
    -framework AppKit \
    -framework ApplicationServices

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>ClipFill</string>
	<key>CFBundleDisplayName</key>
	<string>ClipFill</string>
	<key>CFBundleIdentifier</key>
	<string>com.xaviercany.clipfill</string>
	<key>CFBundleExecutable</key>
	<string>ClipFill</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSUIElement</key>
	<true/>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST

# Strip extended attributes that break codesign, then sign with a STABLE identity
# so macOS keeps the Accessibility grant across rebuilds (ad-hoc changes identity
# every build and forces re-granting). Falls back to ad-hoc if the cert is absent.
xattr -cr "$APP"
IDENTITY="Apple Development: Xavier Cany (VY6KZKP7W7)"
if security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
    codesign --force --sign "$IDENTITY" "$APP"
    echo "Signed with: $IDENTITY"
else
    codesign --force --sign - "$APP"
    echo "Signed ad-hoc (stable cert not found)"
fi

echo "Built: $APP"
