#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-build}"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Install Xcode and run: sudo xcode-select -s /Applications/Xcode.app" >&2
  exit 1
fi

if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
  echo "warning: Xcode first-launch setup is incomplete. If the build fails, run:" >&2
  echo "         sudo xcodebuild -runFirstLaunch" >&2
fi

SIGN_ARGS=()
if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
  SIGN_ARGS+=(
    "DEVELOPMENT_TEAM=${DEVELOPMENT_TEAM}"
    "CODE_SIGN_STYLE=Automatic"
    "CODE_SIGN_IDENTITY=${CODE_SIGN_IDENTITY:-Apple Development}"
  )
else
  SIGN_ARGS+=(
    "DEVELOPMENT_TEAM="
    "CODE_SIGN_STYLE=Manual"
    "CODE_SIGN_IDENTITY=-"
  )
fi

xcodebuild \
  -project DevPreview.xcodeproj \
  -scheme DevPreview \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  -destination "platform=macOS" \
  build \
  "${SIGN_ARGS[@]}"

echo
echo "Built: ${DERIVED_DATA}/Build/Products/${CONFIGURATION}/DevPreview.app"
