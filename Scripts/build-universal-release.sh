#!/bin/zsh
# Builds the universal (arm64 + x86_64) Release EasyKey.app used by the
# macOS 14 compatibility CI job. Does not require Developer ID or Sparkle
# signing configuration; the Info.plist URL keys simply expand empty.
set -euo pipefail

project_root="${0:A:h:h}"
build_dir="${1:-$project_root/build}"

xcodebuild build \
    -project "$project_root/EasyKey.xcodeproj" \
    -scheme EasyKeyApp \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$build_dir" \
    -clonedSourcePackagesDirPath "$build_dir/SourcePackages" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO

app_path="$build_dir/Build/Products/Release/EasyKey.app"
[[ -d "$app_path" ]] || { print -u2 "Universal release build missing: $app_path"; exit 1; }
print "Universal release build: $app_path"
