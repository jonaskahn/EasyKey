#!/bin/zsh
set -euo pipefail

report_path="${1:?Usage: check-coverage.sh <xcresult-path> [threshold]}"
threshold="${2:-90}"

[[ -e "$report_path" ]] || { print -u2 "Result bundle not found: $report_path"; exit 1; }

coverage="$(xcrun xccov view --report --json "$report_path" | jq -er '
    [.targets[] | select(.name == "EasyKey.app" or .name == "EasyEngineCore.framework" or .name == "EasyKeyKit.framework")]
    | select(length == 3 and all(.executableLines > 0))
    | { covered: (map(.coveredLines) | add), executable: (map(.executableLines) | add) }
    | select(.executable > 0)
    | .covered / .executable * 100
')"

printf 'Product line coverage (excl. tests and LoginHelper): %.2f%%\n' "$coverage"
if awk -v coverage="$coverage" -v threshold="$threshold" \
    'BEGIN { exit !(coverage >= threshold) }'
then
    print "Coverage gate passed (>= ${threshold}%)."
else
    print -u2 "Coverage gate failed: ${coverage}% < ${threshold}%"
    exit 1
fi
