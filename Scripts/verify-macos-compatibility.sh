#!/bin/zsh
# Verifies that a built EasyKey.app can run on macOS 14 (Sonoma):
#   1. Every Mach-O slice (app, frameworks, helpers, Sparkle) declares
#      `minos <= 14.0` in its LC_BUILD_VERSION load command.
#   2. The macOS 15+ Translation frameworks stay weak-linked wherever linked.
#   3. Every Info.plist records LSMinimumSystemVersion <= 14.0.
#
# Debug-only test-support artifacts (XCTest/Testing frameworks, test bundles)
# are skipped: they are embedded only when tests ran against the bundle and
# can legitimately require a newer macOS; they are never shipped.
set -euo pipefail

project_root="${0:A:h:h}"
app_path="${1:-${APP_PATH:-$project_root/build/export/EasyKey.app}}"
max_minos=14.0

[[ -d "$app_path" ]] || { print -u2 "App not found: $app_path"; exit 1; }

exit_status=0

# Numeric compare: returns 0 when $1 > $2.
version_gt() {
    local -a a b
    a=("${(@s[.])1}")
    b=("${(@s[.])2}")
    for ((i = 1; i <= ${#a}; i++)); do
        (( ${a[i]:-0} > ${b[i]:-0} )) && return 0
        (( ${a[i]:-0} < ${b[i]:-0} )) && return 1
    done
    return 1
}

# Test-support artifacts embedded by running tests against the bundle.
is_test_support() {
    local path="$1"
    [[ "$path" == *"/PlugIns/"* ]] && return 0
    local framework
    for framework in \
        Testing.framework \
        XCTest.framework \
        XCUnit.framework \
        XCTestCore.framework \
        XCTestSupport.framework \
        XCTAutomationSupport.framework \
        XCUIAutomation.framework
    do
        [[ "$path" == *"/$framework/"* ]] && return 0
    done
    [[ "$path" == *"/libXCTestBundleInject.dylib" ]] && return 0
    [[ "$path" == *"/libXCTestSwiftSupport.dylib" ]] && return 0
    return 1
}

main_exe="$app_path/Contents/MacOS/EasyKey"
[[ -x "$main_exe" ]] || { print -u2 "Main executable not found: $main_exe"; exit 1; }

# Debug builds (ENABLE_DEBUG_DYLIB) put the app code in EasyKey.debug.dylib;
# the stub executable only links that dylib. Check the real code binary for
# the expected weak link to Translation.framework.
presence_target="$main_exe"
[[ -f "$app_path/Contents/MacOS/EasyKey.debug.dylib" ]] && presence_target="$app_path/Contents/MacOS/EasyKey.debug.dylib"

binary_count=0
while IFS= read -r -d '' binary; do
    file_type="$(file -b "$binary")"
    [[ "$file_type" == *"Mach-O"* ]] || continue
    is_test_support "$binary" && continue
    (( binary_count += 1 ))

    archs=("${(@s[ ])$(lipo -archs "$binary")}")
    for arch in "${archs[@]}"; do
        thin_file="$binary"
        tmp_file=""
        if (( ${#archs} > 1 )); then
            tmp_file="$(mktemp "${TMPDIR:-/tmp}/easykey-minos.XXXXXX")"
            lipo -thin "$arch" -output "$tmp_file" "$binary"
            thin_file="$tmp_file"
        fi

        # LC_BUILD_VERSION (modern toolchains) and LC_VERSION_MIN_MACOSX
        # (older binaries, e.g. Sparkle's x86_64 slice) both encode minos.
        minos="$(xcrun vtool -show-build "$thin_file" 2>/dev/null | awk '
            /^ *cmd /{cmd=$2}
            /^ *platform /{platform=$2}
            /^ *minos /{if (platform == "MACOS") print $2}
            /^ *version /{if (cmd == "LC_VERSION_MIN_MACOSX") print $2}
        ')"
        if [[ -z "$minos" ]]; then
            print -u2 "No minos reported: ${binary#$app_path/} ($arch)"
            exit_status=1
        elif version_gt "$minos" "$max_minos"; then
            print -u2 "Requires macOS $minos (> $max_minos): ${binary#$app_path/} ($arch)"
            exit_status=1
        else
            print "minos $minos ok: ${binary#$app_path/} ($arch)"
        fi

        loads="$(otool -L "$thin_file")"
        for framework in "Translation.framework" "_Translation_SwiftUI.framework"; do
            if print "$loads" | grep -q -- "$framework"; then
                if print "$loads" | grep -- "$framework" | grep -q "weak"; then
                    print "weak link ok: ${binary#$app_path/} ($arch) -> $framework"
                else
                    print -u2 "Hard-linked macOS 15 framework: ${binary#$app_path/} ($arch) -> $framework"
                    exit_status=1
                fi
            elif [[ "$binary" == "$presence_target" ]] && [[ "$framework" == "Translation.framework" ]]; then
                print -u2 "Main executable does not link $framework (expected weak link)."
                exit_status=1
            fi
        done

        [[ -z "$tmp_file" ]] || rm -f "$tmp_file"
    done
done < <(find "$app_path" -type f -print0)

(( binary_count > 0 )) || { print -u2 "No Mach-O binaries found in: $app_path"; exit 1; }

# Info.plist minimum-system-version checks.
while IFS= read -r -d '' plist; do
    is_test_support "$plist" && continue
    if /usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$plist" >/dev/null 2>&1; then
        minimum="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$plist")"
        if version_gt "$minimum" "$max_minos"; then
            print -u2 "LSMinimumSystemVersion $minimum (> $max_minos): ${plist#$app_path/}"
            exit_status=1
        else
            print "LSMinimumSystemVersion $minimum ok: ${plist#$app_path/}"
        fi
    else
        print "no LSMinimumSystemVersion key: ${plist#$app_path/}"
    fi
done < <(find "$app_path" -name Info.plist -print0)

(( exit_status == 0 )) || exit 1
print "macOS compatibility verification passed: $app_path"
