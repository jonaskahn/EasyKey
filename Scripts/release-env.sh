#!/bin/zsh
# Loads .env.local into the environment for release builds. Sourced by
# release scripts — not a standalone entry point.
#
# A variable already set in the shell is never overwritten, so CI and one-off
# command lines keep working exactly as before.
set -euo pipefail

release_env_root="${release_env_root:-${0:A:h:h}}"

if [[ -f "$release_env_root/.env.local" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        [[ -z "$key" || "$key" == "$line" ]] && continue
        if [[ -z "${(P)key:-}" ]]; then
            export "$key=$value"
        fi
    done < "$release_env_root/.env.local"
fi
