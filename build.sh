#!/usr/bin/env bash
# build.sh — Compiles the Teleprompter app and wraps it in a macOS .app bundle.
# Usage: ./build.sh [--debug]
set -euo pipefail

PRODUCT="Teleprompter"
CONFIG="release"
[[ "${1:-}" == "--debug" ]] && CONFIG="debug"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$REPO_DIR/.build/$CONFIG"
APP_DIR="$REPO_DIR/$PRODUCT.app"
CONTENTS="$APP_DIR/Contents"

echo "▶ Building ($CONFIG)…"
cd "$REPO_DIR"
swift build -c "$CONFIG" 2>&1

echo "▶ Creating .app bundle…"
rm -rf "$APP_DIR"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

cp "$BUILD_DIR/$PRODUCT"                            "$CONTENTS/MacOS/$PRODUCT"
cp "$REPO_DIR/AppResources/Info.plist"              "$CONTENTS/Info.plist"

# ── Code signing ───────────────────────────────────────────────────────────────
# Ad-hoc signing (–) applies the entitlements without a developer identity.
# This makes the app run locally without Gatekeeper rejection and ensures the
# sandbox entitlement is actually enforced.
#
# For notarisation / Mac App Store distribution, replace "-" with your
# Developer ID Application identity and add --timestamp.
echo "▶ Signing (ad-hoc)…"
codesign \
  --force \
  --deep \
  --sign - \
  --entitlements "$REPO_DIR/AppResources/Teleprompter.entitlements" \
  --options runtime \
  "$APP_DIR"

echo "✓ Built $APP_DIR"
echo ""
echo "To run:         open \"$APP_DIR\""
echo "Keyboard:       Space = play/pause  |  R = reset  |  Esc = pause"
echo "To quit:        right-click the menu bar icon → Quit Teleprompter"
