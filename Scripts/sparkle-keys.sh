#!/usr/bin/env bash
# Sparkle EdDSA key helpers, sourced by update-secrets.sh.
#
# The keypair lives in the login keychain: generate_keys reuses the existing
# key, so calling it is idempotent and never rotates a published key — but it
# DOES create a keypair when none exists, so callers must check
# sparkle_private_key first unless they mean to mint a new one. Helpers print
# only the requested value on stdout so callers can capture it.
set -euo pipefail

sparkle_version="2.9.4"
sparkle_sha256="ce89daf967db1e1893ed3ebd67575ed82d3902563e3191ca92aaec9164fbdef9"

# ensure_sparkle fetches the pinned Sparkle release into a cache outside build/
# and prints the cache directory. The tarball checksum is verified before it is
# unpacked, and the pin matches publish-appcast.yml / check-sparkle-pin.sh.
ensure_sparkle() {
  local cache scratch archive
  cache="${EASYKEY_CACHE:-$HOME/Library/Caches/EasyKey}/sparkle-$sparkle_version"
  if [ -d "$cache/Sparkle.framework" ]; then
    printf '%s' "$cache"
    return 0
  fi
  scratch="$(mktemp -d)"
  trap 'rm -rf "$scratch"' RETURN
  archive="$scratch/sparkle-$sparkle_version.tar.xz"
  curl -fSL --retry 3 --progress-bar -o "$archive" \
    "https://github.com/sparkle-project/Sparkle/releases/download/${sparkle_version}/Sparkle-${sparkle_version}.tar.xz"
  echo "${sparkle_sha256}  $archive" | shasum -a 256 -c - >&2
  mkdir -p "$cache"
  tar -xf "$archive" -C "$cache"
  [ -d "$cache/Sparkle.framework" ] || {
    echo "Sparkle framework missing from $archive" >&2
    return 1
  }
  printf '%s' "$cache"
}

# sparkle_public_key prints the SUPublicEDKey string. Runs generate_keys, which
# reuses the keypair already in the login keychain and creates one if absent.
sparkle_public_key() {
  local key
  key="$("$(ensure_sparkle)/bin/generate_keys" 2>/dev/null | grep -o '<string>[^<]*</string>' | sed 's/<[^>]*>//g')"
  if [ -z "$key" ]; then
    echo "could not read the Sparkle public key from generate_keys" >&2
    return 1
  fi
  printf '%s' "$key"
}

# sparkle_private_key prints the Ed25519 private key held in the login keychain
# (Sparkle's generate_keys stores it under this service/account). Fails when no
# key is present, which callers use to avoid minting one by accident.
sparkle_private_key() {
  security find-generic-password -s "https://sparkle-project.org" -a "ed25519" -w
}
