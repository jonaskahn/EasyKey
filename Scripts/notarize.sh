#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
artifact_path="${1:-${ARTIFACT_PATH:-$project_root/build/export/EasyKey.app}}"
submission_path="$artifact_path"
temporary_directory=""

[[ -e "$artifact_path" ]] || { print -u2 "Artifact not found: $artifact_path"; exit 1; }

if [[ -d "$artifact_path" && "$artifact_path" == *.app ]]; then
    temporary_directory="$(mktemp -d)"
    trap 'rm -rf "$temporary_directory"' EXIT
    submission_path="$temporary_directory/${artifact_path:t}.zip"
    ditto -c -k --keepParent "$artifact_path" "$submission_path"
fi

credentials=()
if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
    credentials=(--keychain-profile "$NOTARY_KEYCHAIN_PROFILE")
else
    : "${APPLE_ID:?Set APPLE_ID or NOTARY_KEYCHAIN_PROFILE.}"
    : "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID or NOTARY_KEYCHAIN_PROFILE.}"
    : "${APPLE_APP_SPECIFIC_PASSWORD:?Set APPLE_APP_SPECIFIC_PASSWORD or NOTARY_KEYCHAIN_PROFILE.}"
    credentials=(
        --apple-id "$APPLE_ID"
        --team-id "$APPLE_TEAM_ID"
        --password "$APPLE_APP_SPECIFIC_PASSWORD"
    )
fi

xcrun notarytool submit "$submission_path" "${credentials[@]}" --wait
