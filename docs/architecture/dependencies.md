---
id: "dependencies"
title: "Dependencies"
docforge_provenance:
  schema: "2.0"
  doc_id: "dependencies"
  path: "docs/architecture/dependencies.md"
  generated_at: "2026-08-03T10:00:00Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "dependencies-and-integrations"
      sources:
        - path: "EasyKey.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
          role: "manifest"
          git_blob: "feb7b4ba06bf6bec15596f2320b7974cbb0a6a78"
      unresolved: []
    - id: "runtime-dependencies"
      sources:
        - path: "EasyKey.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
          role: "manifest"
          git_blob: "feb7b4ba06bf6bec15596f2320b7974cbb0a6a78"
        - path: "EasyKeyApp/UpdateService.swift"
          role: "code"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
        - path: "EasyKey.xcodeproj/project.pbxproj"
          role: "config"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
      unresolved: []
    - id: "development-dependencies"
      sources:
        - path: "Makefile"
          role: "config"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
        - path: "Scripts/qa-gate.sh"
          role: "config"
          git_blob: "6cc6488bf99423e199fc6d9fdb04ff9283a12208"
      unresolved: []
    - id: "external-services"
      sources:
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          role: "code"
          git_blob: "c4df84fdde3f664cd167d91ce3a64b387e6ef30e"
        - path: "EasyKeyApp/Features/Translation/GoogleTranslationProvider.swift"
          role: "code"
          git_blob: "a58ea2ffd3149408365009e036353d1c130b3056"
        - path: "EasyKeyApp/Features/Translation/DeepLTranslationProvider.swift"
          role: "code"
          git_blob: "363614188d90243d0959536f6c96b4380790198e"
        - path: "EasyKeyApp/Features/Translation/AppleTranslationProvider.swift"
          role: "code"
          git_blob: "b214166c0c4a16d48731844087c4810f4af89ca9"
        - path: "EasyKeyApp/Features/Translation/OpenAICompatibleTranslationProvider.swift"
          role: "code"
          git_blob: "794a1cebc1383077804548226dc3773ea2b888f4"
        - path: "EasyKeyApp/Features/Settings/Translation/TranslationSettingsModel.swift"
          role: "code"
          git_blob: "6380a5fed49e57b42d37bb611ddcb6d26661ee43"
      unresolved: []
    - id: "sparkle-update-feed"
      sources:
        - path: "Scripts/generate-appcast.py"
          role: "config"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
        - path: "docs/architecture/decisions/sparkle-updates.md"
          role: "doc"
          git_blob: "6c0243290e6675cc6c695a74efd072f87759d6fb"
      unresolved: []
    - id: "cloud-translation-providers"
      sources:
        - path: "EasyKeyApp/Features/Translation/GoogleTranslationProvider.swift"
          role: "code"
          git_blob: "a58ea2ffd3149408365009e036353d1c130b3056"
        - path: "EasyKeyApp/Features/Translation/DeepLTranslationProvider.swift"
          role: "code"
          git_blob: "363614188d90243d0959536f6c96b4380790198e"
        - path: "EasyKeyApp/Features/Translation/OpenAICompatibleTranslationProvider.swift"
          role: "code"
          git_blob: "794a1cebc1383077804548226dc3773ea2b888f4"
        - path: "EasyKeyApp/Features/Translation/TranslationCredentialStore.swift"
          role: "code"
          git_blob: "768aab956a8d02978101105e7a896b6d55c75376"
        - path: "EasyKeyApp/Features/Translation/HostSafety.swift"
          role: "code"
          git_blob: "275d4aa9b65469565580f4a241d4d4a6cbadb3aa"
      unresolved: []
    - id: "apple-on-device-translation"
      sources:
        - path: "EasyKeyApp/Features/Translation/AppleTranslationProvider.swift"
          role: "code"
          git_blob: "b214166c0c4a16d48731844087c4810f4af89ca9"
      unresolved: []
    - id: "dependency-policy"
      sources:
        - path: "Scripts/qa-gate.sh"
          role: "config"
          git_blob: "6cc6488bf99423e199fc6d9fdb04ff9283a12208"
        - path: "Scripts/check-sparkle-pin.sh"
          role: "config"
          git_blob: "d5fbfa88d05ef88b6d22a9d792292db0a054e75f"
        - path: "Makefile"
          role: "config"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
      unresolved: []
    - id: "generated-inventory"
      sources:
        - path: "EasyKey.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
          role: "manifest"
          git_blob: "feb7b4ba06bf6bec15596f2320b7974cbb0a6a78"
        - path: "docs/_archive/THIRD_PARTY_NOTICES.md"
          role: "doc"
          git_blob: "8c0da23df063ee46dc734994bdd9b6e365eb7a72"
      unresolved: []
---
# Dependencies and integrations

_Last reviewed: 2026-08-03_

The repository's dependency surface is deliberately small: one third-party runtime library (Sparkle), the Apple platform SDKs, and the optional cloud translation providers that are pure network integrations. Platform services (Accessibility, Keychain, event tap) are documented in [platform-integration.md](platform-integration.md).

## Runtime dependencies

_Ordered by criticality — the dependency whose failure or removal would hurt most goes first._

| Package | Purpose | Licence | Version | Criticality | If it disappeared |
|---|---|---|---|---|---|
| Sparkle | Signed automatic updates from an HTTPS appcast (`SPUStandardUpdaterController`) | MIT | 2.9.4 (pinned via SwiftPM, revision `b6496a74a087257ef5e6da1c5b29a447a60f5bd7`) | High | Update delivery stops; users must download releases manually from the project page. The updater already self-disables when the feed or EdDSA key is absent, so failure degrades to "no updates", not breakage |
| Apple platform SDKs (AppKit, SwiftUI, CoreGraphics, ApplicationServices, Security, ServiceManagement, Translation) | Everything else — event tap, AX, Keychain, login item, on-device translation | Apple EULA | macOS 14.0+ SDK | High | Not removable by design; the app is a thin layer over them (see [platform-integration.md](platform-integration.md)) |

Sparkle is the only Swift Package; it is linked to the EasyKeyApp target in `project.pbxproj` and pinned to an exact version in `Package.resolved`. The upstream update toolchain used at release time is additionally pinned by SHA-256 (`Scripts/check-sparkle-pin.sh`); the appcast generation pipeline is `Scripts/generate-appcast.py` and its rationale is in decision [sparkle-updates](decisions/sparkle-updates.md).

## Development dependencies

SwiftLint and SwiftFormat are installed per-runner (homebrew) and enforced in CI: `swiftformat --lint` and `swiftlint lint` gate merges, and `make lint`/`make format` wrap them locally. Both are pinned only by "latest stable" — a drifting formatter version is a known, low-impact source of churn. Everything else is Apple tooling: `xcodebuild`, `xcrun xcresulttool`, `xcrun notarytool` (notarization path), and Python 3 for the QA/release scripts. Nothing development-side is licence-encumbered.

## External services

_Repeat per service — direct integrations only._

### Sparkle update feed

- **Purpose:** delivers signed update metadata (version, build, minimum system version, EdDSA signature, DMG enclosure URL).
- **Criticality:** soft — updates are convenience; typing works without them.
- **Authentication:** none to fetch; the update is verified by the bundled `SUPublicEDKey` (EdDSA) and the HTTPS feed requirement in `hasReleaseConfiguration`.
- **Data exchanged:** app version/build plus user-agent on the appcast GET; no personal data.
- **Limits:** none known; the feed is a static RSS XML produced by `Scripts/generate-appcast.py`.
- **Failure handling:** missing HTTPS feed or ED key disables the updater at startup with a log line; a failed check leaves the current version running.
- **Contract:** Sparkle 2.9.4 appcast format, feed at the URL baked in via the `SPARKLE_FEED_URL` build setting.
- **Region:** static hosting; not material.

### Cloud translation providers

- **Purpose:** optional translation of user-entered or captured source text. Provider family: Google Cloud Translation (v2), DeepL, OpenAI, Anthropic, Gemini, OpenRouter, Groq, and user-supplied OpenAI/Anthropic-compatible endpoints.
- **Criticality:** optional — the app is fully functional without any provider; Apple on-device translation covers macOS 15+.
- **Authentication:** per-provider API key stored in the user's Keychain (`KeychainTranslationCredentialStore`), sent as Authorization/bearer or `x-api-key` header; DeepL also supports a user-configured endpoint.
- **Data exchanged:** the source text being translated plus source/target language identifiers; the response text. Nothing else (no clipboard history, no keystrokes).
- **Limits:** 20 s request timeout, 100 KB max request body, 1 MB max response (Google), 256 KB (compatible endpoints), 2048 max output tokens, and a source-text length cap enforced at capture time (`TranslationRequest.maximumSourceTextLength`).
- **Failure handling:** typed `TranslationError` mapping (provider unavailable, unsupported language pair, cancellation); the panel presents the error and keeps the source text. No silent retries.
- **Contract:** fixed endpoints validated at build time (`_validatedURL`); user-supplied compatible endpoints are rejected unless they resolve to public non-private hosts (`EasyKeyApp/Features/Translation/HostSafety.swift`).
- **Region:** provider-determined; EasyKey neither proxies nor selects a region.

### Apple on-device translation

- **Purpose:** local translation on macOS 15+; the only provider that never leaves the device.
- **Criticality:** soft — unavailable on macOS 14, where cloud providers remain the option.
- **Authentication:** none.
- **Data exchanged:** source text stays on-device.
- **Limits:** language availability depends on installed OS language packs.
- **Failure handling:** unsupported pairs and missing packs map to `unsupportedLanguagePair` / `appleLanguageDownloadRequired` so the UI can direct the user to download a pack.
- **Contract:** guarded by `@available(macOS 15.0, *)` — the provider is never constructed on older OSes.
- **Region:** on-device.

## Dependency policy

- **Criteria for adding one:** a dependency must earn its place — the bar is high because the codebase deliberately ships one runtime library. New additions are assessed on maintenance signals, licence compatibility, security history, and whether an existing dependency or the SDK already covers the need.
- **Who approves:** the maintainer; the QA gate (`Scripts/qa-gate.sh`) runs in CI and locally before release.
- **Review cadence:** every release runs the gate (coverage threshold, lint, archive/verify scripts via `make qa`); the dependency surface is re-checked there and on any update to `Package.resolved`.
- **Update policy:** pinned versions (Sparkle exact-revision pin, toolchain SHA-256 pin); CVE triage happens at release time through the gate; majors require a manual decision recorded in the release notes.

## Generated inventory

There is no generated SBOM in this repository. The nearest machine-readable dependency records are `Package.resolved` (SwiftPM pins — the single source of truth for Sparkle) and the human-maintained third-party notices file (`THIRD_PARTY_NOTICES.md` (archived)). If an SBOM is introduced it should be CycloneDX (built for vulnerability and dependency-risk tracking; carries the NTIA minimum fields of supplier, name, version, PURL, dependency relationship, author, timestamp) — that matches this document's risk-oriented purpose better than an SPDX license view. Until then, this document is the judgment layer: rationale, criticality, and failure behaviour for each direct dependency.
