#!/usr/bin/env bash
# Stores release secrets with gh. Every value travels through stdin, never the
# argument list, so a secret never appears in ps output or shell history. Names
# are auto-detected from .github/workflows (secrets.X / vars.X, minus automatic
# tokens like GITHUB_TOKEN); every name is always prompted, empty input skips
# (so existing values are kept unless overwritten). Pass NAMEs to override
# detection ("FOO" = secret, "VAR:FOO" / "vars.FOO" = variable); --list prints
# the names without asking.
#
# Keys that exist locally (Sparkle keypair, Developer ID .p12, Team ID) are read
# at runtime; the script asks before touching them, and the files it writes stay
# under $EASYKEY_SECRET_DIR (default /Volumes/WS/Secret/easykey), never in the
# repo. The .p12 is always exported from your keychain with `security export` —
# nothing is pasted by hand.
#
# The Sparkle EdDSA keypair is the one value that must NOT be regenerated:
# installed apps verify updates against the public key already baked into them.
# Reading the existing key is the default; creating a new keypair requires
# --rotate-sparkle and an explicit confirmation.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=sparkle-keys.sh
. "$root/Scripts/sparkle-keys.sh"

# Public key currently baked into shipping builds (see Scripts/test-release-config.sh).
# Used only to warn when an upload would replace it.
published_sparkle_public_key="TnOFIWrYd6LbTsYMPCSJq6IKZZhGWgJJ0fsRgTNXFy4="

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is not installed: brew install gh" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated: run gh auth login first" >&2
  exit 1
fi

list_only=0
rotate_sparkle=0
only_names=""
for arg in "$@"; do
  case "$arg" in
    --all) ;; # accepted for compatibility; every name is always prompted now
    --list) list_only=1 ;;
    --rotate-sparkle) rotate_sparkle=1 ;;
    -h|--help)
      echo "usage: update-secrets.sh [--all] [--list] [--rotate-sparkle] [NAME...]" >&2
      echo "  no NAMEs: auto-detect secrets.X / vars.X from .github/workflows" >&2
      echo "  NAMEs: only prompt for those names (VAR:NAME forces a variable)" >&2
      echo "  --rotate-sparkle: allow creating a NEW Sparkle keypair" >&2
      echo "                    (breaks updates for every installed build)" >&2
      exit 0 ;;
    --*) echo "usage: update-secrets.sh [--all] [--list] [--rotate-sparkle] [NAME...]" >&2; exit 2 ;;
    *) only_names="$only_names $arg" ;;
  esac
done
# NAMEs override auto-detection: "FOO" = secret, "VAR:FOO" = variable.
only_names="$(printf '%s' "$only_names" | xargs 2>/dev/null || printf '%s' "$only_names")"

# Auto-detect every secrets.NAME / vars.NAME referenced by workflows, minus
# automatic tokens (e.g. GITHUB_TOKEN) that never need `gh secret set`.
detect_names() {
  grep -rhoE '(secrets|vars)\.[A-Za-z0-9_]+' "$root/.github/workflows" 2>/dev/null \
    | sort -u | grep -v 'GITHUB_TOKEN' || true
}

if [ -n "$only_names" ]; then
  detected="$only_names"
else
  detected="$(detect_names)"
fi

if [ "$list_only" -eq 1 ]; then
  printf '%s\n' $detected
  exit 0
fi

if [ -z "$detected" ]; then
  echo "no secrets.X / vars.X found under $root/.github/workflows" >&2
  exit 1
fi

existing="$(gh secret list 2>/dev/null | awk '{print $1}')"
existing_vars="$(gh variable list 2>/dev/null | awk '{print $1}')"

# already_set prints " (already set)" when the name exists, else "".
already_set() {
  printf '%s\n' "$existing" | grep -qxF "$1" && printf ' (already set)' || true
}

already_set_var() {
  printf '%s\n' "$existing_vars" | grep -qxF "$1" && printf ' (already set)' || true
}

# kind_of echoes "secret" or "var" for a name, from what the workflows use.
kind_of() {
  local entry
  for entry in $detected; do
    case "$entry" in
      "vars.$1"|"VAR:$1") echo var; return 0 ;;
    esac
  done
  echo secret
}

# push stores a value as the kind the workflows expect for that name. The value
# is written on stdin only, so it never reaches ps or the shell history.
push() {
  local name="$1" value="$2"
  if [ "$(kind_of "$name")" = "var" ]; then
    printf '%s' "$value" | gh variable set "$name"
    echo "set $name variable"
  else
    printf '%s' "$value" | gh secret set "$name"
    echo "set $name"
  fi
}

# read_tty reads one line into the named variable from the terminal, so prompts
# still work when stdin is piped. Falls back to stdin with no tty attached.
read_tty() {
  if [ -r /dev/tty ]; then
    IFS= read -rs "$1" < /dev/tty
  else
    IFS= read -rs "$1"
  fi
}

prompt_secret() {
  local name="$1" label="$2" value
  printf '%s: ' "$label" > /dev/tty 2>/dev/null || printf '%s: ' "$label"
  read_tty value
  printf '\n'
  if [ -z "$value" ]; then
    echo "skipping $name (empty)"
    return 0
  fi
  push "$name" "$value"
  unset value
}

prompt_var() {
  prompt_secret "$@"
}

ask_yes() {
  local answer
  printf '%s [y/N]: ' "$1" > /dev/tty 2>/dev/null || printf '%s [y/N]: ' "$1"
  read_tty answer
  printf '\n'
  [ "$answer" = "y" ] || [ "$answer" = "Y" ]
}

# Local copies of what we upload, kept out of the repo and chmod-600.
secret_dir="${EASYKEY_SECRET_DIR:-/Volumes/WS/Secret/easykey}"
if ! mkdir -p "$secret_dir" 2>/dev/null || ! chmod 700 "$secret_dir" 2>/dev/null; then
  secret_dir="$HOME/.easykey/secrets"
  mkdir -p "$secret_dir" && chmod 700 "$secret_dir"
  echo "note: writing local key copies to $secret_dir"
fi

# read_sparkle pushes the Sparkle keypair already in the login keychain. It
# never creates a keypair: if none exists this refuses unless --rotate-sparkle,
# because a fresh key would make every installed build reject future updates.
read_sparkle() {
  local private public
  if ! private="$(sparkle_private_key 2>/dev/null)" || [ -z "$private" ]; then
    if [ "$rotate_sparkle" -eq 1 ]; then
      generate_sparkle
      return 0
    fi
    echo "no Sparkle EdDSA key found in the login keychain." >&2
    echo "Installed apps trust the key already shipped in them, so this script" >&2
    echo "will not create a new one. Either import the existing key, or pass" >&2
    echo "--rotate-sparkle if you really mean to invalidate every install." >&2
    return 1
  fi
  # generate_keys is idempotent: with a key already in the keychain it prints
  # that keypair rather than replacing it.
  public="$(sparkle_public_key)"
  if [ "$public" != "$published_sparkle_public_key" ]; then
    echo "WARNING: the Sparkle key in your keychain is not the published one." >&2
    echo "  keychain: $public" >&2
    echo "  published: $published_sparkle_public_key" >&2
    echo "Uploading it will break updates for builds that trust the published key." >&2
    ask_yes "continue anyway?" || { echo "skipping Sparkle keys"; return 0; }
  fi
  push SPARKLE_PUBLIC_ED_KEY "$public"
  push SPARKLE_PRIVATE_ED_KEY "$private"
  mkdir -p "$secret_dir" && chmod 700 "$secret_dir"
  printf '%s' "$public" > "$secret_dir/sparkle-public.key"
  printf '%s' "$private" > "$secret_dir/sparkle-private.key"
  chmod 600 "$secret_dir/sparkle-private.key"
  echo "wrote $secret_dir/sparkle-public.key and sparkle-private.key"
}

generate_sparkle() {
  local public private
  echo "NOTE: creating a NEW Sparkle keypair. Builds already installed trust" >&2
  echo "the old key and will reject every update signed with this one." >&2
  ask_yes "type y only if no EasyKey build is installed anywhere" || {
    echo "skipping Sparkle keys"
    return 0
  }
  public="$(sparkle_public_key)"
  private="$(sparkle_private_key)"
  push SPARKLE_PUBLIC_ED_KEY "$public"
  push SPARKLE_PRIVATE_ED_KEY "$private"
  mkdir -p "$secret_dir" && chmod 700 "$secret_dir"
  printf '%s' "$public" > "$secret_dir/sparkle-public.key"
  printf '%s' "$private" > "$secret_dir/sparkle-private.key"
  chmod 600 "$secret_dir/sparkle-private.key"
  echo "wrote $secret_dir/sparkle-public.key and sparkle-private.key"
}

# export_p12 exports the Developer ID identity as .p12 from the keychain,
# base64-encodes it for the CI secret, and derives the Team ID from the
# certificate itself. Nothing is pasted by hand.
export_p12() {
  local password p12 b64 team
  password="$(openssl rand -base64 24)"
  p12="$secret_dir/easykey-signing.p12"
  b64="$secret_dir/easykey-signing.p12.b64"
  mkdir -p "$secret_dir" && chmod 700 "$secret_dir"
  security export -k "${KEYCHAIN:-$HOME/Library/Keychains/login.keychain-db}" \
    -t identities -f pkcs12 -o "$p12" -P "$password"
  chmod 600 "$p12"
  base64 -i "$p12" -o "$b64"
  chmod 600 "$b64"
  printf '%s' "$password" > "$secret_dir/p12-password.txt"
  chmod 600 "$secret_dir/p12-password.txt"
  gh secret set APPLE_SIGN_P12_BASE64 < "$b64"
  echo "set APPLE_SIGN_P12_BASE64"
  printf '%s' "$password" | gh secret set APPLE_SIGN_P12_PASSWORD
  echo "set APPLE_SIGN_P12_PASSWORD"
  # Derive the Team ID from the certificate's OU. A missing or unparseable
  # certificate must not abort the run under `set -e`/`pipefail` — the caller
  # can still set APPLE_TEAM_ID at the prompt below.
  team="$( { security find-certificate -c "Developer ID Application" -p 2>/dev/null \
    || true; } | { openssl x509 -noout -subject -nameopt multiline 2>/dev/null \
    || true; } | awk -F'= ' '/organizationalUnitName/ {print $2; exit}' || true)"
  if [ -n "$team" ]; then
    printf '%s' "$team" | gh secret set APPLE_TEAM_ID
    echo "set APPLE_TEAM_ID ($team)"
    printf '%s' "$team" > "$secret_dir/apple-team-id.txt"
  else
    echo "could not read the Team ID from the certificate; you will be prompted for APPLE_TEAM_ID" >&2
  fi
}

if [ -z "$only_names" ]; then
  if ask_yes "read the Sparkle keypair from the login keychain and set it as secrets?"; then
    # Not fatal: a missing key only skips this pair, the rest still uploads.
    read_sparkle || echo "skipped the Sparkle keys"
  else
    prompt_secret SPARKLE_PRIVATE_ED_KEY "Sparkle EdDSA private key$(already_set SPARKLE_PRIVATE_ED_KEY) (empty to skip)"
    prompt_secret SPARKLE_PUBLIC_ED_KEY "Sparkle EdDSA public key$(already_set SPARKLE_PUBLIC_ED_KEY) (empty to skip)"
  fi

  if ask_yes "export the Developer ID .p12 from the keychain and set it as secrets?"; then
    export_p12
  else
    prompt_secret APPLE_SIGN_P12_BASE64 "Developer ID .p12 as base64$(already_set APPLE_SIGN_P12_BASE64) (empty to skip)"
    prompt_secret APPLE_SIGN_P12_PASSWORD ".p12 password$(already_set APPLE_SIGN_P12_PASSWORD) (empty to skip)"
    prompt_secret APPLE_TEAM_ID "Apple Team ID$(already_set APPLE_TEAM_ID) (empty to skip)"
  fi
fi

prompt_detected() {
  local entry kind name label
  for entry in $detected; do
    case "$entry" in
      secrets.*) kind=secret; name="${entry#secrets.}" ;;
      vars.*) kind=var; name="${entry#vars.}" ;;
      VAR:*) kind=var; name="${entry#VAR:}" ;;
      *) kind=secret; name="$entry" ;;
    esac
    # Sparkle / Apple signing have local readers above; the generic loop only
    # handles the rest so each name is asked for exactly once.
    case "$name" in
      SPARKLE_PRIVATE_ED_KEY|SPARKLE_PUBLIC_ED_KEY|APPLE_SIGN_P12_BASE64|APPLE_SIGN_P12_PASSWORD|APPLE_TEAM_ID) continue ;;
    esac
    label="$name (empty to skip)"
    case "$name" in
      APPLE_APP_SPECIFIC_PASSWORD) label="app-specific password (empty to skip)" ;;
      APPLE_ID) label="Apple ID email (empty to skip)" ;;
      SPARKLE_FEED_URL) label="HTTPS Sparkle appcast URL (empty to skip)" ;;
      EASYKEY_SUPPORT_URL) label="HTTPS support URL (empty to skip)" ;;
      EASYKEY_PRIVACY_POLICY_URL) label="HTTPS privacy-policy URL (empty to skip)" ;;
    esac
    if [ "$kind" = "var" ]; then
      prompt_var "$name" "$label$(already_set_var "$name")"
    else
      prompt_secret "$name" "$label$(already_set "$name")"
    fi
  done
}

prompt_detected

echo "done; verify with: gh secret list && gh variable list"
