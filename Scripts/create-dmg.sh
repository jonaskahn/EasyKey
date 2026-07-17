#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
app_path="${1:-${APP_PATH:-$project_root/build/export/EasyKey.app}}"
staging_directory="$(mktemp -d)"
trap 'rm -rf "$staging_directory"' EXIT

[[ -d "$app_path" ]] || { print -u2 "App not found: $app_path"; exit 1; }

info_plist="$app_path/Contents/Info.plist"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$info_plist" 2>/dev/null || true)"
[[ -n "$version" ]] || { print -u2 "Could not read CFBundleShortVersionString from $info_plist"; exit 1; }

dmg_path="${DMG_PATH:-$project_root/build/EasyKey-${version}-universal.dmg}"
mkdir -p "${dmg_path:h}"
cp -R "$app_path" "$staging_directory/EasyKey.app"
ln -s /Applications "$staging_directory/Applications"
hdiutil create \
    -volname "EasyKey $version" \
    -srcfolder "$staging_directory" \
    -ov \
    -format UDZO \
    "$dmg_path"

print "DMG created: $dmg_path"
