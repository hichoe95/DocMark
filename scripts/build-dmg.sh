#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DocMark"
BUILD_DIR=".build/release"
DMG_NAME="DocMark.dmg"
APP_BUNDLE="/tmp/DocMark.app"


echo "Cleaning old bundle and dmg"
rm -rf "$APP_BUNDLE"
rm -f "$DMG_NAME"


echo "Building $APP_NAME in release configuration"
swift build -c release


echo "Creating app bundle structure"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

echo "Copying binary to bundle"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"


echo "Writing Info.plist"
cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>DocMark</string>
    <key>CFBundleIdentifier</key>
    <string>com.docmark.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>DocMark</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Markdown Document</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>md</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Folder</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.folder</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
        </dict>
    </array>
</dict>
</plist>
PLIST


echo "Creating dmg at $DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_NAME"

echo "Created DMG: $(pwd)/$DMG_NAME"

echo "Next: sign and notarize the package for distribution"
# codesign --options runtime --timestamp --entitlements "DocMark.entitlements" --sign "Developer ID Application: Your Name" "$DMG_NAME"
# xcrun notarytool submit "$DMG_NAME" --keychain-profile "DeveloperID" --wait
# xcrun stapler staple "$DMG_NAME"
