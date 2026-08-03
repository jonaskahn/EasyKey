---
id: "setup_guide"
title: "Setup Guide"
docforge_provenance:
  schema: "2.0"
  doc_id: "setup_guide"
  path: "docs/engineering/setup.md"
  generated_at: "2026-08-03T08:44:07Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "prerequisites"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
        - path: "Scripts/archive.sh"
          git_blob: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          role: "code"
      unresolved: []
    - id: "steps"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
        - path: "Scripts/archive.sh"
          git_blob: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          role: "code"
        - path: "Scripts/clean-local.sh"
          git_blob: "51ee51c9ae3eb4397ea4ad56bf3a10565a3c0674"
          role: "code"
      unresolved:
        - "<REPOSITORY_URL>"
    - id: "verify"
      sources:
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
        - path: "Scripts/qa-gate.sh"
          git_blob: "6cc6488bf99423e199fc6d9fdb04ff9283a12208"
          role: "code"
      unresolved: []
    - id: "common-problems"
      sources:
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "Scripts/clean-local.sh"
          git_blob: "51ee51c9ae3eb4397ea4ad56bf3a10565a3c0674"
          role: "code"
      unresolved: []
    - id: "next"
      sources:
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "7a094e2c60f68ffca552947082f4330c2806213a"
      unresolved: []
---
# Local setup

_Last reviewed: 2026-08-03_

This path builds EasyKey from source and runs its test suite. A first build
compiles the entire project and takes longer than later incremental builds.

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| macOS | 14.0 (Sonoma) or later | stated in the README Requirements section |
| Xcode | 15 or later | includes the Swift toolchain; the project compiles in Swift 5 language mode |
| Git and command-line tools | any recent | needed for cloning and helper commands |
| SwiftLint, SwiftFormat | optional | `brew install swiftlint swiftformat`; `make lint` and `make format` skip them when absent |
| Accessibility permission | runtime only | granted at first launch; System Settings → Privacy & Security → Accessibility |

Access you will need, and who grants it: none for building, testing, and
running locally. A local DMG (`make local-dmg`) additionally requires four
non-secret environment variables — `SPARKLE_FEED_URL`, `SPARKLE_PUBLIC_ED_KEY`,
`EASYKEY_SUPPORT_URL`, `EASYKEY_PRIVACY_POLICY_URL` — because the release
configuration is baked into the build (`Scripts/archive.sh` enforces HTTPS).
Signed distribution adds Apple Developer credentials (Developer ID Application
certificate, team identifier, notarization profile) — Apple Developer Program,
held by the repository owner; see [RELEASE.md](release.md).

## Steps

1. Clone the repository and enter it. The public archive URL is listed in the
   Build from Source section of [product overview](../product/overview.md).

   ```bash
   git clone <REPOSITORY_URL>
   cd EasyKey
   ```

   Verify: the `EasyKey` directory contains `EasyKey.xcodeproj`, `Makefile`,
   and the `EasyEngineCore/`, `EasyKeyKit/`, `EasyKeyApp/` source directories.

2. Build the debug app:

   ```bash
   make build
   ```

   Verify: Xcode prints `** BUILD SUCCEEDED **`, and
   `build/Build/Products/Debug/EasyKey.app` exists.

3. Optional: install the style tools so the lint and format targets enforce
   the repository's style instead of skipping:

   ```bash
   brew install swiftlint swiftformat
   ```

4. Run the full test suite (unit and UI, serial, with code coverage):

   ```bash
   make test
   ```

   Verify: Xcode prints `** TEST SUCCEEDED **`.

5. Launch EasyKey:

   ```bash
   make run
   ```

   Verify: a menu-bar icon appears. Grant Accessibility when prompted — typing
   transformation stays unavailable until the permission is granted
   (System Settings → Privacy & Security → Accessibility).

6. Smoke-test the engine: type `vieejt nam` in any text field. Verify: it
   transforms to `việt nam`.

7. Optional: package a local universal DMG when you have the four release
   configuration variables from the prerequisites:

   ```bash
   export SPARKLE_FEED_URL=<feed-url>
   export SPARKLE_PUBLIC_ED_KEY=<ed25519-public-key>
   export EASYKEY_SUPPORT_URL=<support-url>
   export EASYKEY_PRIVACY_POLICY_URL=<privacy-url>
   make local-dmg
   ```

   Verify: `DMG created: build/EasyKey-<version>-universal.dmg`. This is an
   ad-hoc signed build without notarization.

## Verify

```bash
make qa
```

Expected output:

```text
Phase 8 automated QA gate passed.
```

`make qa` runs the full test suite, then `Scripts/verify-qa-artifacts.sh`
checks that the fixture-driven engine conformance test, the keyboard-service
integration test host, the settings workflow UI tests, and the fixture data
under `Fixtures/` are all present.

## Common problems

**xcodebuild reports it cannot find a destination** — the Xcode toolchain is
not selected or command-line tools are missing. Open Xcode once to finish its
first-run setup, then rerun `make build`.

**Typing transformation does nothing after launch** — Accessibility
permission is missing or was revoked. Grant it in System Settings → Privacy &
Security → Accessibility and relaunch EasyKey.

**`make lint` prints "SwiftLint not installed. Install with: brew install
swiftlint"** — this is the skip behavior, not an error; the target still
exits successfully. Run `brew install swiftlint` to enable the check.

**UI tests flake during `make test-parallel`** — all shards share one
`UserDefaults` domain on a single Mac. Fall back to the serial run with
`make test`; the Makefile documents this limitation.

**`make local-dmg` fails with "SPARKLE_PUBLIC_ED_KEY environment variable is
not set"** — the release configuration check requires all four variables to
be exported in the current shell; export them as in step 7.

**Odd behavior persists across runs (stale preferences, leftovers)** — wipe
build artifacts and local app and test data with `make clean-all`. The local
cleanup quits EasyKey and removes preferences, containers, caches, and saved
state.

## Next

- Run the tests: [testing.md](testing.md)
- Engineering rules: [conventions.md](conventions.md)
- Codebase overview: [../architecture/high-level.md](../architecture/high-level.md)
- Ship a build: [release.md](release.md)
