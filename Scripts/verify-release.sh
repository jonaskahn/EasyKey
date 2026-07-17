#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
app_path="${1:-${APP_PATH:-$project_root/build/export/EasyKey.app}}"
release_local="${RELEASE_LOCAL:-0}"

[[ -d "$app_path" ]] || { print -u2 "App not found: $app_path"; exit 1; }

"$project_root/Scripts/verify-arch.sh" "$app_path"

if [[ "$release_local" == "1" ]]; then
    print "Local release: skipping Developer ID codesign/spctl assessment."
else
    codesign --verify --deep --strict --verbose=2 "$app_path"
    spctl --assess --type execute --verbose=4 "$app_path"
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
