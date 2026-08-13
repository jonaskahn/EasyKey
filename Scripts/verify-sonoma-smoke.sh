#!/bin/zsh
# Launch smoke test for macOS 14 (Sonoma) CI runners. Asserts the host is
# actually macOS 14 of the expected architecture, launches the universal
# EasyKey.app with the readiness signal enabled, waits for `ready=1`, and
# confirms the macOS 15-only Apple Translation surface is disabled.
set -euo pipefail

app_path="${1:?usage: verify-sonoma-smoke.sh <EasyKey.app> <arm64|x86_64>}"
expected_arch="${2:?usage: verify-sonoma-smoke.sh <EasyKey.app> <arm64|x86_64>}"

[[ -d "$app_path" ]] || { print -u2 "App not found: $app_path"; exit 1; }

os_version="$(sw_vers -productVersion)"
host_arch="$(uname -m)"
print "Host: macOS $os_version ($host_arch)"
[[ "$os_version" == 14.* ]] || { print -u2 "Expected macOS 14 Sonoma, got $os_version"; exit 1; }
[[ "$host_arch" == "$expected_arch" ]] || {
    print -u2 "Expected architecture $expected_arch, got $host_arch"
    exit 1
}

exe="$app_path/Contents/MacOS/EasyKey"
[[ -x "$exe" ]] || { print -u2 "Missing executable: $exe"; exit 1; }
print "$(lipo -archs "$exe")" | grep -qw -- "$expected_arch" || {
    print -u2 "App lacks $expected_arch slice: $(lipo -archs "$exe")"
    exit 1
}

ready_file="$(mktemp -t easykey-sonoma-smoke)"
rm -f "$ready_file"
print "Readiness file: $ready_file"

EASYKEY_UITEST_READY_FILE="$ready_file" "$exe" --uitesting --ui-skip-onboarding &
pid=$!
trap 'kill -TERM "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; rm -f "$ready_file"' EXIT

deadline=$((SECONDS + 60))
while [[ ! -s "$ready_file" ]]; do
    if ! kill -0 "$pid" 2>/dev/null; then
        print -u2 "EasyKey exited before signaling readiness (pid $pid)."
        exit 1
    fi
    (( SECONDS < deadline )) || { print -u2 "Timed out waiting for readiness file."; exit 1; }
    sleep 0.5
done

content="$(cat "$ready_file")"
print "Readiness: $(print "$content" | tr '\n' '; ')"
print "$content" | grep -q '^ready=1$' || { print -u2 "App did not report ready."; exit 1; }
print "$content" | grep -q '^appleTranslationSupported=false$' || {
    print -u2 "Apple Translation unexpectedly available on macOS 14."
    exit 1
}

print "Sonoma smoke test passed (macOS $os_version, $host_arch)."
