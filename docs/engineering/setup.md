---
id: "setup_guide"
title: "Setup Guide"
description: "Prerequisites, install, configuration, run, verification, recovery"
docforge_provenance:
  schema: "2.0"
  doc_id: "setup_guide"
  path: "docs/engineering/setup.md"
  generated_at: "2026-08-13T11:07:59Z"
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
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          git_blob_normalized: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          role: "doc"
        - path: "Makefile"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          git_blob_normalized: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          role: "config"
        - path: "docs/reference/tech-stack.md"
          git_blob: "59c9d316ad97e7dfef4d9a8b16c0c60caee27fd6"
          git_blob_normalized: "59c9d316ad97e7dfef4d9a8b16c0c60caee27fd6"
          role: "doc"
        - path: "Scripts/archive.sh"
          git_blob: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          git_blob_normalized: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          role: "code"
        - path: "Scripts/notarize.sh"
          git_blob: "18256dcf44a32ce9c2cef44d2196ee44fef8fd63"
          git_blob_normalized: "18256dcf44a32ce9c2cef44d2196ee44fef8fd63"
          role: "code"
      unresolved: []
    - id: "steps"
      sources:
        - path: "README.md"
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          git_blob_normalized: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          role: "doc"
        - path: "Makefile"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          git_blob_normalized: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          role: "config"
        - path: "Scripts/archive.sh"
          git_blob: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          git_blob_normalized: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          role: "code"
        - path: "Scripts/clean-local.sh"
          git_blob: "51ee51c9ae3eb4397ea4ad56bf3a10565a3c0674"
          git_blob_normalized: "51ee51c9ae3eb4397ea4ad56bf3a10565a3c0674"
          role: "code"
      unresolved:
        - "<REPOSITORY_URL>"
    - id: "verify"
      sources:
        - path: "Makefile"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          git_blob_normalized: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          role: "config"
        - path: "Scripts/qa-gate.sh"
          git_blob: "148320feb241615087d1cda4ef51cac8706e78bf"
          git_blob_normalized: "148320feb241615087d1cda4ef51cac8706e78bf"
          role: "code"
        - path: "Scripts/verify-qa-artifacts.sh"
          git_blob: "11ce62a91f372b4527c134c17645b8c7b655f51b"
          git_blob_normalized: "11ce62a91f372b4527c134c17645b8c7b655f51b"
          role: "code"
        - path: "Scripts/check-test-registration.sh"
          git_blob: "4a36185850f52eac0e1796f1313b86b1a666c322"
          git_blob_normalized: "4a36185850f52eac0e1796f1313b86b1a666c322"
          role: "code"
      unresolved: []
    - id: "common-problems"
      sources:
        - path: "Makefile"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          git_blob_normalized: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          role: "config"
        - path: "README.md"
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          git_blob_normalized: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          role: "doc"
        - path: "Scripts/clean-local.sh"
          git_blob: "51ee51c9ae3eb4397ea4ad56bf3a10565a3c0674"
          git_blob_normalized: "51ee51c9ae3eb4397ea4ad56bf3a10565a3c0674"
          role: "code"
      unresolved: []
    - id: "next"
      sources:
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "8bb5cc9a4b9d059453e9f103da683c7956067cf4"
          git_blob_normalized: "8bb5cc9a4b9d059453e9f103da683c7956067cf4"
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
held by the repository owner; see the [release guide](release.md).

## Steps

1. Clone the repository and enter it. The repository is public; the release
   badge at the top of the [README](../../README.md) links to the public
   release page.

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
under `Fixtures/` are all present, and `Scripts/check-test-registration.sh`
fails when a tracked test file is missing from its Xcode target.

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

**UI tests fail under `make test-parallel` ("Lost connection to the
application")** — every UI shard launches the same `EasyKey.app` bundle, so
one shard's `app.launch()`/`terminate()` can kill another shard's app
mid-test; the unit shard is app-hosted and dies the same way. The Makefile
runs local shards serially by design, so fall back to `make test` for the
reliable serial run.

**`make local-dmg` fails with "SPARKLE_PUBLIC_ED_KEY environment variable is
not set"** — the Makefile's release-config check catches a missing
`SPARKLE_PUBLIC_ED_KEY` first, and `Scripts/archive.sh` then requires all
four variables (with HTTPS enforcement); export them as in step 7.

**Odd behavior persists across runs (stale preferences, leftovers)** — wipe
build artifacts and local app and test data with `make clean-all`. The local
cleanup quits EasyKey and removes preferences, containers, caches, and saved
state.

## Next

- Run the tests: [testing.md](testing.md)
- Engineering rules: [conventions.md](conventions.md)
- Codebase overview: [../architecture/high-level.md](../architecture/high-level.md)
- Ship a build: [release.md](release.md)
