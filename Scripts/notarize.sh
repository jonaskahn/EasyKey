#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
release_env_root="$project_root"
# shellcheck source=release-env.sh
source "$project_root/Scripts/release-env.sh"
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

log_directory="$project_root/build/notarization"
mkdir -p "$log_directory"
submission_result="$log_directory/${artifact_path:t}.submission.json"
notary_log="$log_directory/${artifact_path:t}.log.json"
rm -f "$notary_log"

submit_exit=0
xcrun notarytool submit "$submission_path" "${credentials[@]}" \
    --wait --output-format json > "$submission_result" || submit_exit=$?
cat "$submission_result"

# notarytool can exit successfully even when Apple's final status is Invalid.
# Only Accepted submissions have a ticket that stapler can attach.
submission_id="$(plutil -extract id raw -o - "$submission_result" 2>/dev/null || true)"
notary_status="$(plutil -extract status raw -o - "$submission_result" 2>/dev/null || true)"
if [[ "$submit_exit" != "0" || "$notary_status" != "Accepted" ]]; then
    print -u2 "Notarization failed for $artifact_path (status: ${notary_status:-unknown}, exit: $submit_exit)."
    if [[ -n "$submission_id" ]]; then
        if xcrun notarytool log "$submission_id" "$notary_log" "${credentials[@]}"; then
            cat "$notary_log"
        else
            print -u2 "Could not retrieve notarization log for submission $submission_id."
        fi
    fi
    exit 1
fi
