#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
artifact_path="${1:-${ARTIFACT_PATH:-$project_root/build/export/EasyKey.app}}"

[[ -e "$artifact_path" ]] || { print -u2 "Artifact not found: $artifact_path"; exit 1; }
xcrun stapler staple "$artifact_path"
xcrun stapler validate "$artifact_path"
