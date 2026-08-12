#!/bin/zsh
# register_test.sh <filename> — register a NEW test file in EasyKeyTests in the pbxproj.
set -euo pipefail
name="$1"
base="${name%.swift}"
# Stable unique IDs derived from the name hash + CB prefix.
hash_id="$(printf '%s' "$name" | shasum | cut -c1-18 | tr 'a-f' 'A-F')"
file_id="CB${hash_id}01"
build_id="CB${hash_id}02"
pbx="EasyKey.xcodeproj/project.pbxproj"

if grep -q "$name in Sources" "$pbx"; then
  echo "already registered: $name"
  exit 0
fi

# Insert PBXBuildFile after the EngineCoreCoverageTests build file line.
python3 - "$pbx" "$name" "$file_id" "$build_id" << 'EOF'
import sys
pbx, name, file_id, build_id = sys.argv[1:5]
s = open(pbx).read()
anchor = '\t\tCB00000000000000000000A2 /* EngineCoreCoverageTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = CB00000000000000000000A1 /* EngineCoreCoverageTests.swift */; };'
build = f'\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};'
assert anchor in s, "anchor build-file line not found"
s = s.replace(anchor, anchor + '\n' + build, 1)

anchor = '\t\tCB00000000000000000000A1 /* EngineCoreCoverageTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EngineCoreCoverageTests.swift; sourceTree = "<group>"; };'
fref = f'\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};'
assert anchor in s, "anchor file-ref line not found"
s = s.replace(anchor, anchor + '\n' + fref, 1)

anchor = '\t\t\t\tCB00000000000000000000A1 /* EngineCoreCoverageTests.swift */,'
assert anchor in s, "anchor group line not found"
s = s.replace(anchor, anchor + '\n\t\t\t\t' + file_id + ' /* ' + name + ' */,', 1)

anchor = '\t\t\t\tCB00000000000000000000A2 /* EngineCoreCoverageTests.swift in Sources */,'
assert anchor in s, "anchor sources line not found"
s = s.replace(anchor, anchor + '\n\t\t\t\t' + build_id + ' /* ' + name + ' in Sources */,', 1)
open(pbx, 'w').write(s)
print("registered", name)
EOF
