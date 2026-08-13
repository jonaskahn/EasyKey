#!/bin/zsh
# Fails when a test-shard result bundle contains zero executed test cases.
# xcodebuild returns success for a shard whose -only-testing filter matched
# nothing (e.g. a suite that fell out of the target), which silently turns
# CI shards green. Run this after every shard whose filter is expected to
# execute tests.
set -euo pipefail

report_path="${1:?Usage: check-shard-tests.sh <xcresult-path>}"

[[ -e "$report_path" ]] || { print -u2 "Result bundle not found: $report_path"; exit 1; }

count="$(xcrun xcresulttool get test-results tests \
    --path "$report_path" --format json \
    | python3 -c '
import json
import sys

data = json.load(sys.stdin)
count = 0

def walk(nodes):
    global count
    for node in nodes:
        if node.get("nodeType") == "Test Case":
            count += 1
        walk(node.get("children", []))

walk(data.get("testNodes", []))
print(count)
')"

if [[ "$count" -eq 0 ]]; then
    print -u2 "Shard result bundle executed zero tests: $report_path"
    print -u2 "The shard filter matched nothing; fix the target registration or the filter."
    exit 1
fi

print "Shard executed $count test case(s): $report_path"
