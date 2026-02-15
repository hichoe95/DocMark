#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# DocMark DMG Builder
# Usage: ./scripts/build-dmg.sh [--sign "Developer ID Application: Name"] [--version X.Y.Z]
# ─────────────────────────────────────────────

APP_NAME="DocMark"
VERSION="1.0.0"
BUNDLE_ID="com.docmark.app"
BUILD_DIR=".build/release"
BUILD_OUTPUT="build"
APP_BUNDLE="$BUILD_OUTPUT/$APP_NAME.app"
DMG_STAGING="$BUILD_OUTPUT/dmg-staging"
DMG_NAME="$BUILD_OUTPUT/DocMark-${VERSION}.dmg"
SIGN_IDENTITY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign)
            SIGN_IDENTITY="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            DMG_NAME="$BUILD_OUTPUT/DocMark-${VERSION}.dmg"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--sign \"Developer ID Application: Name\"] [--version X.Y.Z]"
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Building $APP_NAME v$VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Step 1: Clean ──────────────────────────────
echo ""
echo "→ Cleaning previous build artifacts..."
rm -rf "$APP_BUNDLE" "$DMG_STAGING" "$DMG_NAME"
mkdir -p "$BUILD_OUTPUT"

# ── Step 2: Build release binary ───────────────
echo "→ Building release binary..."
swift build -c release 2>&1

echo "  ✓ Build succeeded"

# ── Step 3: Create .app bundle structure ───────
echo "→ Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
echo "  ✓ Binary copied"

# Copy SPM resource bundles (these contain processed resources from Package.swift)
for bundle in "$BUILD_DIR"/*.bundle; do
    if [ -d "$bundle" ]; then
        bundle_name=$(basename "$bundle")
        cp -R "$bundle" "$APP_BUNDLE/Contents/Resources/$bundle_name"
        echo "  ✓ Bundled: $bundle_name"
    fi
done

# Copy DocMarkGuide (bundled welcome project)
if [ -d "Resources/DocMarkGuide" ]; then
    cp -R "Resources/DocMarkGuide" "$APP_BUNDLE/Contents/Resources/DocMarkGuide"
    echo "  ✓ Bundled: DocMarkGuide"
fi

# Copy skills (for Tools → Install menu)
if [ -d "skills" ]; then
    cp -R "skills" "$APP_BUNDLE/Contents/Resources/skills"
    echo "  ✓ Bundled: skills"
fi

# ── Step 4: Write Info.plist ───────────────────
echo "→ Writing Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 DocMark. All rights reserved.</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Markdown Document</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>md</string>
                <string>markdown</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
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
            <string>Alternate</string>
        </dict>
    </array>
</dict>
</plist>
PLIST
echo "  ✓ Info.plist written"

# ── Step 5: Write PkgInfo ─────────────────────
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"
echo "  ✓ PkgInfo written"

# ── Step 6: Code sign (optional) ──────────────
if [ -n "$SIGN_IDENTITY" ]; then
    echo "→ Signing app bundle..."

    # Create entitlements
    cat > "$BUILD_OUTPUT/DocMark.entitlements" <<'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
ENTITLEMENTS

    codesign --force --options runtime --timestamp \
        --entitlements "$BUILD_OUTPUT/DocMark.entitlements" \
        --sign "$SIGN_IDENTITY" \
        "$APP_BUNDLE"
    echo "  ✓ Code signed with: $SIGN_IDENTITY"
else
    echo "→ Skipping code signing (use --sign to enable)"
    echo "  ⚠ Unsigned app will show Gatekeeper warning on other Macs"
fi

# ── Step 7: Create DMG ────────────────────────
echo "→ Creating DMG..."
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# Create a README for the DMG
cat > "$DMG_STAGING/README.txt" <<'README'
DocMark — Beautiful Markdown Documentation Reader

Installation:
  Drag DocMark.app to the Applications folder.

First Launch:
  If you see "unidentified developer" warning:
  Right-click the app → Open → Open

Uninstall:
  Drag DocMark.app from Applications to Trash.
  Optionally remove: ~/Library/Application Support/DocMark/

Website: https://github.com/hichoe95/DocMark
README

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_NAME"

rm -rf "$DMG_STAGING"
echo "  ✓ DMG created"

# ── Step 8: Notarize (optional) ───────────────
if [ -n "$SIGN_IDENTITY" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Notarization (manual step)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  To notarize, run:"
    echo ""
    echo "  # Store credentials (one-time):"
    echo "  xcrun notarytool store-credentials \"DocMark\" \\"
    echo "      --apple-id YOUR_APPLE_ID \\"
    echo "      --team-id YOUR_TEAM_ID \\"
    echo "      --password YOUR_APP_SPECIFIC_PASSWORD"
    echo ""
    echo "  # Submit for notarization:"
    echo "  xcrun notarytool submit \"$DMG_NAME\" --keychain-profile \"DocMark\" --wait"
    echo ""
    echo "  # Staple the ticket:"
    echo "  xcrun stapler staple \"$DMG_NAME\""
    echo ""
fi

# ── Summary ───────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Build Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  App:     $APP_BUNDLE"
echo "  DMG:     $DMG_NAME"
DMG_SIZE=$(du -sh "$DMG_NAME" | cut -f1)
echo "  Size:    $DMG_SIZE"
echo ""

if [ -z "$SIGN_IDENTITY" ]; then
    echo "  ⚠ This build is UNSIGNED."
    echo "    To sign: $0 --sign \"Developer ID Application: Your Name\""
    echo ""
fi

echo "  To test the app:"
echo "    open \"$APP_BUNDLE\""
echo ""
