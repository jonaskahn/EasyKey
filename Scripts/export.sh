#!/bin/zsh
set -euo pipefail

scripts_directory="${0:A:h}"
project_root="${scripts_directory:h}"
archive_path="${ARCHIVE_PATH:-$project_root/build/archives/EasyKey.xcarchive}"
export_path="${EXPORT_PATH:-$project_root/build/export}"
release_local="${RELEASE_LOCAL:-0}"

[[ -d "$archive_path" ]] || { print -u2 "Archive not found: $archive_path"; exit 1; }

mkdir -p "$export_path"
rm -rf "$export_path/EasyKey.app"

if [[ "$release_local" == "1" ]]; then
    archived_app="$archive_path/Products/Applications/EasyKey.app"
    [[ -d "$archived_app" ]] || { print -u2 "Archived app not found: $archived_app"; exit 1; }
    cp -R "$archived_app" "$export_path/EasyKey.app"
    print "Local export copied: $export_path/EasyKey.app"
    exit 0
fi

xcodebuild -exportArchive \
    -archivePath "$archive_path" \
    -exportPath "$export_path" \
    -exportOptionsPlist "$scripts_directory/ExportOptions.plist"

print "Exported: $export_path/EasyKey.app"
