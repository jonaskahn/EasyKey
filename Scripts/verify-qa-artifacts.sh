#!/bin/zsh
set -u

project_root="${0:A:h:h}"
exit_status=0

if ! find "$project_root/Fixtures" -type f -name '*.json' 2>/dev/null | grep -q .; then
    print -u2 "Missing black-box conformance fixture data under Fixtures/."
    exit_status=1
fi

if [[ ! -f "$project_root/EasyKeyTests/ConformanceFixtureTests.swift" ]]; then
    print -u2 "Missing fixture-driven engine conformance test."
    exit_status=1
fi

if [[ ! -f "$project_root/EasyKeyTests/KeyboardServiceIntegrationTests.swift" ]]; then
    print -u2 "Missing keyboard-service integration test host."
    exit_status=1
fi

if [[ ! -f "$project_root/EasyKeyTests/SettingsImporterTests.swift" ]]; then
    print -u2 "Missing settings importer tests."
    exit_status=1
fi

if [[ ! -f "$project_root/EasyKeyUITests/SettingsWorkflowTests.swift" ]]; then
    print -u2 "Missing onboarding and settings workflow UI tests."
    exit_status=1
fi

if [[ ! -f "$project_root/EasyEngineCore/SettingsImporter.swift" ]]; then
    print -u2 "Missing legacy settings importer."
    exit_status=1
fi

exit "$exit_status"
