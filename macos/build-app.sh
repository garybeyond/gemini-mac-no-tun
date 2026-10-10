#!/bin/sh
# Build the Gemini via Clash.app wrapper and create a release ZIP.
# Run from the repository root: sh macos/build-app.sh
set -e

APP_NAME="Gemini via Clash.app"
SRC="/Applications/Gemini.app"
DST="/Applications/$APP_NAME"

if [ ! -d "$SRC" ]; then
  echo "Error: $SRC not found. Install official Gemini.app first."
  exit 1
fi

# Create the wrapper app bundle
mkdir -p "$DST/Contents/MacOS" "$DST/Contents/Resources"

# Copy launcher script
cp macos/launcher "$DST/Contents/MacOS/launcher"
chmod +x "$DST/Contents/MacOS/launcher"

# Copy Info.plist
cp macos/Info.plist "$DST/Contents/Info.plist"

# Copy icon from official app
if [ -f "$SRC/Contents/Resources/AppIcon.icns" ]; then
  cp "$SRC/Contents/Resources/AppIcon.icns" "$DST/Contents/Resources/AppIcon.icns"
fi

echo "Created: $DST"

# Create release ZIP
cd /Applications
zip -r "../gemini-mac-no-tun-macos-source.zip" "$APP_NAME" macos/ 2>/dev/null || \
  zip -r "../gemini-mac-no-tun-macos-source.zip" "$APP_NAME"

echo "Created: /Applications/../gemini-mac-no-tun-macos-source.zip"
echo "Done. Upload the ZIP to GitHub Releases."
