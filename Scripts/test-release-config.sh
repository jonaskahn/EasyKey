#!/bin/zsh
set -euo pipefail

# Verify SPARKLE_PUBLIC_ED_KEY in project.pbxproj is parameterized
if grep -q 'SPARKLE_PUBLIC_ED_KEY = "TnOFIWrYd6LbTsYMPCSJq6IKZZhGWgJJ0fsRgTNXFy4="' EasyKey.xcodeproj/project.pbxproj; then
    echo "Error: Hardcoded SPARKLE_PUBLIC_ED_KEY found in project.pbxproj" >&2
    exit 1
fi

if ! grep -q 'SPARKLE_PUBLIC_ED_KEY = "\$(SPARKLE_PUBLIC_ED_KEY)";' EasyKey.xcodeproj/project.pbxproj; then
    echo "Error: SPARKLE_PUBLIC_ED_KEY in project.pbxproj is not set to \$(SPARKLE_PUBLIC_ED_KEY)" >&2
    exit 1
fi

echo "Release configuration check passed."
