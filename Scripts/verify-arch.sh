#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
app_path="${1:-${APP_PATH:-$project_root/build/export/EasyKey.app}}"
required_archs=(${=REQUIRED_ARCHS:-arm64 x86_64})

[[ -d "$app_path" ]] || { print -u2 "App not found: $app_path"; exit 1; }

exit_status=0
binary_count=0
while IFS= read -r -d '' binary; do
    file_type="$(file -b "$binary")"
    [[ "$file_type" == *"Mach-O"* ]] || continue
    (( binary_count += 1 ))

    archs="$(lipo -archs "$binary")"
    print "archs ${binary#$app_path/}: $archs"

    for required in "${required_archs[@]}"; do
        if ! print "$archs" | grep -qw -- "$required"; then
            print -u2 "Missing required architecture '$required' in $binary (have: $archs)"
            exit_status=1
        fi
    done
done < <(find "$app_path" -type f -print0)

(( binary_count > 0 )) || { print -u2 "No Mach-O binaries found in: $app_path"; exit 1; }
(( exit_status == 0 )) || exit 1
print "Architecture verification passed for: $app_path"
