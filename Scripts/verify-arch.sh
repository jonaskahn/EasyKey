#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
app_path="${1:-${APP_PATH:-$project_root/build/export/EasyKey.app}}"
required_archs=(${=REQUIRED_ARCHS:-arm64 x86_64})

[[ -d "$app_path" ]] || { print -u2 "App not found: $app_path"; exit 1; }

binaries=(
    "$app_path/Contents/MacOS/EasyKey"
    "$app_path/Contents/Library/LoginItems/EasyKeyLoginHelper.app/Contents/MacOS/EasyKeyLoginHelper"
    "$app_path/Contents/Frameworks/EasyEngineCore.framework/Versions/A/EasyEngineCore"
    "$app_path/Contents/Frameworks/EasyKeyKit.framework/Versions/A/EasyKeyKit"
)

if [[ -f "$app_path/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle" ]]; then
    binaries+=("$app_path/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle")
fi

exit_status=0
for binary in "${binaries[@]}"; do
    if [[ ! -f "$binary" ]]; then
        print -u2 "Missing binary: $binary"
        exit_status=1
        continue
    fi

    archs="$(lipo -archs "$binary")"
    print "archs $(basename "$binary"): $archs"
    file "$binary"

    for required in "${required_archs[@]}"; do
        if ! print "$archs" | grep -qw -- "$required"; then
            print -u2 "Missing required architecture '$required' in $binary (have: $archs)"
            exit_status=1
        fi
    done
done

(( exit_status == 0 )) || exit 1
print "Architecture verification passed for: $app_path"
