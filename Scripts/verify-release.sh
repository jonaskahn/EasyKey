#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
app_path="${1:-${APP_PATH:-$project_root/build/export/EasyKey.app}}"
dmg_path="${2:-${DMG_PATH:-}}"
release_local="${RELEASE_LOCAL:-0}"

[[ -d "$app_path" ]] || { print -u2 "App not found: $app_path"; exit 1; }

"$project_root/Scripts/verify-arch.sh" "$app_path"
"$project_root/Scripts/verify-macos-compatibility.sh" "$app_path"

# Ad-hoc signed code cannot use the hardened runtime: it enables dyld library
# validation, which requires the process and its frameworks to share a Team ID,
# and an ad-hoc signature has none. The app then dies at launch failing to load
# its own EasyEngineCore.framework. Catch it here rather than on double-click.
main_binary="$app_path/Contents/MacOS/EasyKey"
if [[ -f "$main_binary" ]]; then
    main_sig="$(codesign -d --verbose=4 "$main_binary" 2>&1)"
    # Match the hardened runtime in the CodeDirectory flags. The flag group is
    # "(runtime)" under a real signing identity but "(adhoc,runtime)" when
    # ad-hoc, so match the token rather than the whole parenthesised group.
    if grep -qE 'flags=0x[[:xdigit:]]+\(([^,()]+,)*runtime([,)])' <<< "$main_sig" \
        && grep -q 'TeamIdentifier=not set' <<< "$main_sig"; then
        print -u2 "App is ad-hoc signed but enables the hardened runtime; it will not launch."
        print -u2 "Ad-hoc signatures carry no Team ID, so dyld library validation rejects the"
        print -u2 "app's own embedded frameworks. Disable the hardened runtime for local"
        print -u2 "builds (see Scripts/archive.sh)."
        exit 1
    fi
fi

if [[ "$release_local" == "1" ]]; then
    print "Local release: skipping Developer ID codesign/spctl assessment."
else
    codesign --verify --deep --strict --verbose=2 "$app_path"
    # Notarization requires the hardened runtime; a build that loses it would
    # still pass codesign --verify but be rejected by Apple and by Gatekeeper.
    # Capture the complete output before matching: grep -q can close a pipe
    # early, making codesign fail with SIGPIPE under pipefail. Verbosity 4
    # includes the CodeDirectory flags used by this check.
    app_signature="$(codesign -d --verbose=4 "$app_path" 2>&1)"
    if ! grep -qE 'flags=0x[[:xdigit:]]+\(([^,()]+,)*runtime([,)])' <<< "$app_signature"; then
        print -u2 -- "$app_signature"
        print -u2 "App is not signed with the hardened runtime; notarization would fail."
        exit 1
    fi
    spctl --assess --type execute --verbose=4 "$app_path"
    if [[ -n "$dmg_path" ]]; then
        [[ -f "$dmg_path" ]] || { print -u2 "DMG not found: $dmg_path"; exit 1; }
        xcrun stapler validate "$dmg_path"
        spctl --assess --type open --context context:primary-signature --verbose=4 "$dmg_path"
    fi
fi

[[ -f "$app_path/Contents/Resources/LICENSE" ]] || { print -u2 "Missing bundled MIT license."; exit 1; }
[[ -f "$app_path/Contents/Resources/NOTICE" ]] || { print -u2 "Missing bundled provenance notice."; exit 1; }
[[ -f "$app_path/Contents/Resources/THIRD_PARTY_NOTICES.md" ]] || { print -u2 "Missing bundled third-party notices."; exit 1; }

if find "$app_path" -type f | grep -iE '/(fixtures|sources|diagnostics|capture)(/|$)' > /dev/null; then
    print -u2 "Release contains prohibited development material."
    exit 1
fi

# Relative path probe against accidental tracked build output (repo-local check).
if git -C "$project_root" ls-files -- 'build/' 2>/dev/null | grep -q .; then
    print -u2 "Tracked EasyKey build output violates release provenance policy."
    exit 1
fi

print "Release verification passed: $app_path"
