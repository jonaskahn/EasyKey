#!/bin/zsh
set -euo pipefail

scripts_directory="${0:A:h}"
project_root="${scripts_directory:h}"
archive_path="${ARCHIVE_PATH:-$project_root/build/archives/EasyKey.xcarchive}"
export_path="${EXPORT_PATH:-$project_root/build/export}"

[[ -d "$archive_path" ]] || { print -u2 "Archive not found: $archive_path"; exit 1; }

mkdir -p "$export_path"
rm -rf "$export_path/EasyKey.app"

# Copy the signed app out of the archive rather than running
# `xcodebuild -exportArchive`. archive.sh already signs every target with the
# Developer ID identity and the hardened runtime (or ad-hoc, for RELEASE_LOCAL),
# and these entitlements need no provisioning profile, so -exportArchive would
# only copy this same bundle. It is also the part that breaks on current Xcode:
# with DEVELOPMENT_TEAM absent from EasyKey.xcodeproj, the archive carries no
# ApplicationTeamID, so IDEDistributionMethodManager reports "Unknown
# Distribution Error" and -exportArchive rejects every `method` value with
# `expected one {} but found developer-id`. Downstream verification
# (Scripts/verify-release.sh) still checks the signature and hardened runtime.
archived_app="$archive_path/Products/Applications/EasyKey.app"
[[ -d "$archived_app" ]] || { print -u2 "Archived app not found: $archived_app"; exit 1; }
cp -R "$archived_app" "$export_path/EasyKey.app"
print "Exported: $export_path/EasyKey.app"
