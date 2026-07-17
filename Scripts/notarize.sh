#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
artifact_path="${1:-${ARTIFACT_PATH:-$project_root/build/export/EasyKey.app}}"

: "${NOTARY_KEYCHAIN_PROFILE:?Set notarytool keychain profile name.}"
[[ -e "$artifact_path" ]] || { print -u2 "Artifact not found: $artifact_path"; exit 1; }

xcrun notarytool submit "$artifact_path" \
    --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" \
    --wait
