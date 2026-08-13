#!/bin/zsh
# Fails when a tracked test source file in EasyKeyTests/ or EasyKeyUITests/ is
# not registered in the matching Xcode target's Sources build phase, or when
# the project references a test file that is not tracked. Kept outside XCTest
# so the guard itself can never silently disappear from a test target.
set -euo pipefail

project_root="${0:A:h:h}"
pbxproj="$project_root/EasyKey.xcodeproj/project.pbxproj"

exit_status=0

check_target() {
    local dir="$1"
    local target_name="$2"

    local disk_files target_files
    disk_files="$(mktemp)"
    target_files="$(mktemp)"

    git -C "$project_root" ls-files "${dir}/*.swift" 2>/dev/null \
        | sed "s|^${dir}/||" | LC_ALL=C sort -u > "$disk_files"

    # Source-phase membership: collect PBXBuildFile -> fileRef -> path for the
    # target's Sources phase, filtering to the target's test directory.
    python3 - "$pbxproj" "$target_name" "$dir" > "$target_files" <<'PYEOF'
import re
import sys

pbxproj, target_name, test_dir = sys.argv[1], sys.argv[2], sys.argv[3]
with open(pbxproj) as f:
    content = f.read()

def section(body, name):
    match = re.search(r"/\* Begin %s section \*/(.*?)/\* End %s section \*/" % (name, name), body, re.S)
    return match.group(1) if match else ""

def entries(sec):
    result = {}
    for match in re.finditer(r"^\s*([0-9A-Z]+) /\* (.+?) \*/ = \{(.*?)\};", sec, re.S | re.M):
        result[match.group(1)] = match.group(3)
    return result

def parse_key_value(block):
    return dict(re.findall(r"(\w+) = ([^;]+);", block))

targets = entries(section(content, "PBXNativeTarget"))
build_files = entries(section(content, "PBXBuildFile"))
file_refs = entries(section(content, "PBXFileReference"))

target_id = None
sources_phase_id = None
for tid, block in targets.items():
    kv = parse_key_value(block)
    if kv.get("name") == target_name:
        target_id = tid
        phases = kv.get("buildPhases", "")
        for pid, pname in re.findall(r"([0-9A-Z]+) /\* (\w+) \*/", phases):
            if pname == "Sources":
                sources_phase_id = pid
        break

if target_id is None or sources_phase_id is None:
    print("error: could not locate target %s or its Sources phase" % target_name, file=sys.stderr)
    sys.exit(2)

phases = entries(section(content, "PBXSourcesBuildPhase"))
phase_block = phases.get(sources_phase_id, "")
source_ids = re.findall(r"([0-9A-Z]+) /\* .+? \*/", phase_block)

names = set()
for sid in source_ids:
    bf = parse_key_value(build_files.get(sid, ""))
    ref_id = re.search(r"([0-9A-Z]+)", bf.get("fileRef", ""))
    if not ref_id:
        continue
    fr = parse_key_value(file_refs.get(ref_id.group(1), ""))
    path = fr.get("path")
    if path and path.endswith(".swift"):
        names.add(path.strip('"'))

print("\n".join(sorted(names)))
PYEOF
    LC_ALL=C sort -u -o "$target_files" "$target_files"

    local missing extra
    missing="$(comm -23 "$disk_files" "$target_files")"
    extra="$(comm -13 "$disk_files" "$target_files")"

    if [[ -n "$missing" ]]; then
        print -u2 "Unregistered test files in ${dir}/ (add them to the ${target_name} target):"
        print -u2 "$missing" | sed 's/^/    /'
        exit_status=1
    fi
    if [[ -n "$extra" ]]; then
        print -u2 "Test files in the ${target_name} target that are not tracked in git:"
        print -u2 "$extra" | sed 's/^/    /'
        exit_status=1
    fi

    rm -f "$disk_files" "$target_files"
}

check_target "EasyKeyTests" "EasyKeyTests"
check_target "EasyKeyUITests" "EasyKeyUITests"

(( exit_status == 0 )) || exit 1
print "Test registration check passed: every tracked test file is registered in its target."
