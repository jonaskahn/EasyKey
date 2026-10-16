#!/bin/zsh
# Pre-flight for the DMG targets: fail early and say what to fix when release
# configuration is missing. Values come from the environment or .env.local.
set -euo pipefail

project_root="${0:A:h:h}"
release_env_root="$project_root"
# shellcheck source=release-env.sh
source "$project_root/Scripts/release-env.sh"

required=(
    SPARKLE_PUBLIC_ED_KEY
    SPARKLE_FEED_URL
    EASYKEY_SUPPORT_URL
    EASYKEY_PRIVACY_POLICY_URL
)

missing=()
for name in "${required[@]}"; do
    if [[ -z "${(P)name:-}" ]]; then
        missing+=("$name")
    fi
done

if (( ${#missing[@]} > 0 )); then
    print -u2 "Missing release configuration: ${missing[*]}"
    print -u2 ""
    print -u2 "  cp .env.example .env.local    # then fill in the blanks"
    print -u2 ""
    print -u2 "or export the names above before running make. See .env.example for"
    print -u2 "where each value comes from."
    exit 1
fi

for name in SPARKLE_FEED_URL EASYKEY_SUPPORT_URL EASYKEY_PRIVACY_POLICY_URL; do
    value="${(P)name}"
    if [[ "$value" != https://* ]]; then
        print -u2 "$name must be an https:// URL, got: $value"
        exit 1
    fi
done

print "Release configuration OK."
