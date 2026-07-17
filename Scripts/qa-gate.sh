#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"

xcodebuild test \
    -project "$project_root/EasyKey.xcodeproj" \
    -scheme EasyKeyApp \
    -destination "platform=macOS" \
    -derivedDataPath "$project_root/build" \
    -enableCodeCoverage YES

exit_status=0
"$project_root/Scripts/verify-qa-artifacts.sh" || exit_status=1

(( exit_status == 0 )) || exit 1

print "Phase 8 automated QA gate passed."
