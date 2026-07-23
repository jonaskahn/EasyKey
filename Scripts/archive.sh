#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
archive_path="${ARCHIVE_PATH:-$project_root/build/archives/EasyKey.xcarchive}"
# Universal binary for Apple Silicon and Intel distribution (choice A).
archs="${ARCHS:-arm64 x86_64}"
only_active_arch="${ONLY_ACTIVE_ARCH:-NO}"
release_local="${RELEASE_LOCAL:-0}"

mkdir -p "${archive_path:h}"

common_args=(
    -project "$project_root/EasyKey.xcodeproj"
    -scheme EasyKeyApp
    -configuration Release
    -derivedDataPath "$project_root/build"
    -archivePath "$archive_path"
    archive
    ARCHS="$archs"
    ONLY_ACTIVE_ARCH="$only_active_arch"
)

if [[ "$release_local" == "1" ]]; then
    : "${SPARKLE_FEED_URL:?Set HTTPS Sparkle appcast URL.}"
    : "${SPARKLE_PUBLIC_ED_KEY:?Set Sparkle EdDSA public key.}"
    : "${EASYKEY_SUPPORT_URL:?Set HTTPS support URL.}"
    : "${EASYKEY_PRIVACY_POLICY_URL:?Set HTTPS privacy-policy URL.}"

    for url in "$SPARKLE_FEED_URL" "$EASYKEY_SUPPORT_URL" "$EASYKEY_PRIVACY_POLICY_URL"; do
        [[ "$url" == https://* ]] || { print -u2 "Release URLs must use HTTPS: $url"; exit 1; }
    done

    print "Archiving local Release build for $archs (ad-hoc sign, no Developer ID)."
    xcodebuild "${common_args[@]}" \
        CODE_SIGN_STYLE=Automatic \
        CODE_SIGN_IDENTITY="-" \
        DEVELOPMENT_TEAM="" \
        "SPARKLE_FEED_URL=$SPARKLE_FEED_URL" \
        "SPARKLE_PUBLIC_ED_KEY=$SPARKLE_PUBLIC_ED_KEY" \
        "EASYKEY_SUPPORT_URL=$EASYKEY_SUPPORT_URL" \
        "EASYKEY_PRIVACY_POLICY_URL=$EASYKEY_PRIVACY_POLICY_URL"
    print "Local archive created: $archive_path"
    exit 0
fi

: "${DEVELOPER_ID_APPLICATION:?Set Developer ID Application certificate name.}"
: "${DEVELOPMENT_TEAM:?Set Apple Developer team identifier.}"
: "${SPARKLE_FEED_URL:?Set HTTPS Sparkle appcast URL.}"
: "${SPARKLE_PUBLIC_ED_KEY:?Set Sparkle EdDSA public key.}"
: "${EASYKEY_SUPPORT_URL:?Set HTTPS support URL.}"
: "${EASYKEY_PRIVACY_POLICY_URL:?Set HTTPS privacy-policy URL.}"

for url in "$SPARKLE_FEED_URL" "$EASYKEY_SUPPORT_URL" "$EASYKEY_PRIVACY_POLICY_URL"; do
    [[ "$url" == https://* ]] || { print -u2 "Release URLs must use HTTPS: $url"; exit 1; }
done

xcodebuild "${common_args[@]}" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    "SPARKLE_FEED_URL=$SPARKLE_FEED_URL" \
    "SPARKLE_PUBLIC_ED_KEY=$SPARKLE_PUBLIC_ED_KEY" \
    "EASYKEY_SUPPORT_URL=$EASYKEY_SUPPORT_URL" \
    "EASYKEY_PRIVACY_POLICY_URL=$EASYKEY_PRIVACY_POLICY_URL"

print "Signed archive created: $archive_path"
