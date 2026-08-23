#!/bin/bash
# Generates Resources/AppIcon.icns from the cube source PNG.
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$DIR/Resources/AppIcon-source-1024.png"
STYLED="$(mktemp -t factorfill-icon).png"
ICONSET="$(mktemp -d)/AppIcon.iconset"
OUT="$DIR/Resources/AppIcon.icns"

echo "Styling icon (rounded macOS grid)…"
swift "$DIR/scripts/style-icon.swift" "$SRC" "$STYLED"

mkdir -p "$ICONSET"
sips -z 16 16     "$STYLED" --out "$ICONSET/icon_16x16.png"      >/dev/null
sips -z 32 32     "$STYLED" --out "$ICONSET/icon_16x16@2x.png"   >/dev/null
sips -z 32 32     "$STYLED" --out "$ICONSET/icon_32x32.png"      >/dev/null
sips -z 64 64     "$STYLED" --out "$ICONSET/icon_32x32@2x.png"   >/dev/null
sips -z 128 128   "$STYLED" --out "$ICONSET/icon_128x128.png"    >/dev/null
sips -z 256 256   "$STYLED" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$STYLED" --out "$ICONSET/icon_256x256.png"    >/dev/null
sips -z 512 512   "$STYLED" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$STYLED" --out "$ICONSET/icon_512x512.png"    >/dev/null
cp "$STYLED"      "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$OUT"
rm -f "$STYLED"
echo "Built: $OUT"
