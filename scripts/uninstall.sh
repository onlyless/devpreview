#!/usr/bin/env bash
set -euo pipefail

EXTENSION_ID="com.zhangzheng.DevPreview.Extension"

pluginkit -e ignore -i "$EXTENSION_ID" >/dev/null 2>&1 || true

for APP_PATH in "/Applications/DevPreview.app" "${HOME}/Applications/DevPreview.app"; do
  if [[ -d "$APP_PATH" ]]; then
    rm -rf "$APP_PATH"
    echo "Removed: $APP_PATH"
  fi
done

qlmanage -r >/dev/null 2>&1 || true
qlmanage -r cache >/dev/null 2>&1 || true

if [[ "${RELOAD_FINDER:-0}" == "1" ]]; then
  killall Finder >/dev/null 2>&1 || true
fi

echo "DevPreview has been removed."
