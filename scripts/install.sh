#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-build}"
EXTENSION_ID="com.zhangzheng.DevPreview.Extension"

CONFIGURATION="$CONFIGURATION" DERIVED_DATA="$DERIVED_DATA" ./scripts/build.sh

APP_SOURCE="${DERIVED_DATA}/Build/Products/${CONFIGURATION}/DevPreview.app"
if [[ ! -d "$APP_SOURCE" ]]; then
  echo "Build product not found: $APP_SOURCE" >&2
  exit 1
fi

DEST_DIR="${DEST_DIR:-/Applications}"
if [[ ! -d "$DEST_DIR" || ! -w "$DEST_DIR" ]]; then
  DEST_DIR="${HOME}/Applications"
  mkdir -p "$DEST_DIR"
fi

APP_DEST="${DEST_DIR}/DevPreview.app"
APPEX_DEST="${APP_DEST}/Contents/PlugIns/DevPreviewExtension.appex"

rm -rf "$APP_DEST"
ditto "$APP_SOURCE" "$APP_DEST"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
  "$LSREGISTER" -f -R -trusted "$APP_DEST" >/dev/null 2>&1 || true
fi

pluginkit -a "$APPEX_DEST" >/dev/null 2>&1 || true
pluginkit -e use -i "$EXTENSION_ID" >/dev/null 2>&1 || true

qlmanage -r >/dev/null 2>&1 || true
qlmanage -r cache >/dev/null 2>&1 || true

if [[ "${RELOAD_FINDER:-0}" == "1" ]]; then
  killall Finder >/dev/null 2>&1 || true
fi

echo "Installed: $APP_DEST"
echo
echo "Extension status:"
pluginkit -m -i "$EXTENSION_ID" || true
echo
echo "If previews do not update immediately:"
echo "  1. Open System Settings > General > Login Items & Extensions > Quick Look"
echo "  2. Enable DevPreview"
echo "  3. Run: killall Finder"
echo
echo "Test from Terminal:"
echo "  qlmanage -p $(pwd)/Examples/sample.swift"

if [[ "${NO_OPEN:-0}" != "1" ]]; then
  open "$APP_DEST"
fi
