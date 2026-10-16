#!/bin/zsh
set -euo pipefail

scripts_directory="${0:A:h}"
project_root="${scripts_directory:h}"
release_env_root="$project_root"
# shellcheck source=release-env.sh
source "$scripts_directory/release-env.sh"
release_local="${RELEASE_LOCAL:-0}"
archive_path="${ARCHIVE_PATH:-$project_root/build/archives/EasyKey.xcarchive}"
export_path="${EXPORT_PATH:-$project_root/build/export}"

[[ -d "$archive_path" ]] || { print -u2 "Archive not found: $archive_path"; exit 1; }
if [[ "$release_local" != "1" ]]; then
    : "${DEVELOPER_ID_APPLICATION:?Set Developer ID Application certificate name.}"
fi

mkdir -p "$export_path"
rm -rf "$export_path/EasyKey.app"

# Copy the signed app out of the archive rather than running
# `xcodebuild -exportArchive`. These entitlements need no provisioning profile,
# but Sparkle's prebuilt nested helpers still need distribution signatures below.
# Exporting through Xcode breaks on current Xcode:
# with DEVELOPMENT_TEAM absent from EasyKey.xcodeproj, the archive carries no
# ApplicationTeamID, so IDEDistributionMethodManager reports "Unknown
# Distribution Error" and -exportArchive rejects every `method` value with
# `expected one {} but found developer-id`. Downstream verification
# (Scripts/verify-release.sh) still checks the signature and hardened runtime.
archived_app="$archive_path/Products/Applications/EasyKey.app"
[[ -d "$archived_app" ]] || { print -u2 "Archived app not found: $archived_app"; exit 1; }
cp -R "$archived_app" "$export_path/EasyKey.app"

if [[ "$release_local" != "1" ]]; then
    # Xcode's CodeSignOnCopy signs Sparkle.framework, but not its prebuilt
    # helpers, which ship ad-hoc signed. Replace the distribution signing that
    # -exportArchive normally performs, from nested code to the enclosing app.
    exported_app="$export_path/EasyKey.app"
    sparkle_framework="$exported_app/Contents/Frameworks/Sparkle.framework"
    sparkle_version="$sparkle_framework/Versions/Current"
    for code_path in \
        "$sparkle_version/Autoupdate" \
        "$sparkle_version/Updater.app" \
        "$sparkle_version/XPCServices/Downloader.xpc" \
        "$sparkle_version/XPCServices/Installer.xpc" \
        "$sparkle_framework" \
        "$exported_app"; do
        [[ -e "$code_path" ]] || { print -u2 "Code to sign not found: $code_path"; exit 1; }
        codesign --force --sign "$DEVELOPER_ID_APPLICATION" \
            --options runtime --timestamp \
            --preserve-metadata=identifier,entitlements,flags \
            "$code_path"
    done
fi

print "Exported: $export_path/EasyKey.app"
