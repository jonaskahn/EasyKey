#!/bin/zsh
set -euo pipefail

workflow_file=".github/workflows/publish-appcast.yml"

if ! grep -q 'expected_sha256=' "$workflow_file"; then
    echo "Error: expected_sha256 pin not found in $workflow_file" >&2
    exit 1
fi

if ! grep -q 'shasum -a 256 -c -' "$workflow_file"; then
    echo "Error: shasum verification step missing in $workflow_file" >&2
    exit 1
fi

echo "Sparkle pin check passed."
