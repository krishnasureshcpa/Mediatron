#!/bin/bash
# Mediatron — Code Sign & Notarize
# Usage: ./sign_and_notarize.sh [dev-id-identity]

set -e

APP="Mediatron"
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$ROOT/$APP.app"
DMG_PATH="$ROOT/$APP.dmg"
ENTITLEMENTS="$ROOT/Mediatron.entitlements"
TEAM_ID="${TEAM_ID:-""}"
IDENTITY="${1:-}"

if [ -z "$IDENTITY" ]; then
    # Check for available Developer ID
    IDENTITY=$(security find-identity -v -p macappstore 2>/dev/null | grep -oE '"Developer ID Application: [^"]+"' | head -1 | tr -d '"')
    if [ -z "$IDENTITY" ]; then
        IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep -oE '"Apple Development: [^"]+"' | head -1 | tr -d '"')
    fi
fi

echo "============ Mediatron Signing Pipeline ============="

if [ -z "$IDENTITY" ]; then
    echo "No Developer ID found. Using ad-hoc signing."
    echo ""
    
    # Ad-hoc sign (Gatekeeper bypass for dev)
    echo "Ad-hoc signing binaries..."
    codesign --force --deep --sign - \
        --entitlements "$ENTITLEMENTS" \
        --options runtime \
        "$APP_PATH" 2>&1
    
    echo ""
    echo "Ad-hoc signed. This build will NOT pass Gatekeeper."
    echo "To distribute: enroll at developer.apple.com, create a Developer ID certificate."
else
    echo "Identity: $IDENTITY"
    echo ""
    
    # Sign with Developer ID
    echo "Signing with Developer ID..."
    codesign --force --deep --sign "$IDENTITY" \
        --entitlements "$ENTITLEMENTS" \
        --options runtime \
        --timestamp \
        "$APP_PATH" 2>&1
    
    echo "Verifying signature..."
    codesign -dvv "$APP_PATH" 2>&1
    
    # Package DMG if available
    if [ -f "$DMG_PATH" ]; then
        echo ""
        echo "Signing DMG..."
        codesign --force --sign "$IDENTITY" \
            --options runtime \
            --timestamp \
            "$DMG_PATH" 2>&1
    fi
    
    # Notarize (requires Apple ID credentials in keychain)
    if [ -n "$APPLE_ID" ] && [ -n "$APP_PASSWORD" ]; then
        echo ""
        echo "Submitting for notarization..."
        
        if [ -f "$DMG_PATH" ]; then
            NOTARIZE_TARGET="$DMG_PATH"
        else
            # Create zip for notarization
            ditto -c -k --keepParent "$APP_PATH" "$ROOT/${APP}_notarize.zip"
            NOTARIZE_TARGET="$ROOT/${APP}_notarize.zip"
        fi
        
        xcrun notarytool submit "$NOTARIZE_TARGET" \
            --apple-id "$APPLE_ID" \
            --password "$APP_PASSWORD" \
            --team-id "$TEAM_ID" \
            --wait 2>&1
        
        echo ""
        echo "Stapling notarization ticket..."
        xcrun stapler staple "$APP_PATH" 2>&1
        
        if [ -f "$DMG_PATH" ]; then
            xcrun stapler staple "$DMG_PATH" 2>&1
        fi
        
        # Cleanup
        rm -f "$ROOT/${APP}_notarize.zip"
        
        echo ""
        echo "Notarization complete. Checking..."
        spctl -a -vvv -t install "$APP_PATH" 2>&1
        echo ""
        echo "Gatekeeper check: $(spctl -a -t install "$APP_PATH" 2>&1 && echo 'PASS' || echo 'FAIL')"
    else
        echo ""
        echo "Skipping notarization (set APPLE_ID + APP_PASSWORD env vars to enable)."
    fi
fi

echo ""
echo "============ Signing Complete ============="
