# Platform compatibility

_Last reviewed: 2026-08-15_

Minimums are tested evidence, not aspiration: every row is backed by the
declared deployment target and/or CI and release-gate configuration. "Tested
by" distinguishes CI matrix runs from manual gates.

## Supported platforms

| OS / device / architecture | Minimum version | Tested by | Below minimum |
|---|---|---|---|
| macOS (all models) | 14.0 Sonoma (`MACOSX_DEPLOYMENT_TARGET` / `LSMinimumSystemVersion`) | CI builds against the 14.0 target on macOS 15 runners; `Scripts/verify-macos-compatibility.sh` gates every app bundle (Mach-O `minos`, weak Translation linkage, `LSMinimumSystemVersion`); unit suites; release verification in [distribution.md](../operations/distribution.md) | refuses to run (Launch Services enforces `LSMinimumSystemVersion`) |
| Apple silicon (arm64) | 14.0 | CI release matrix builds an arm64 DMG; `make verify-arch` validates `arm64` | not applicable (same OS minimum) |
| Intel (x86_64) | 14.0 | CI release matrix builds an amd64 (x86_64) DMG; `make verify-arch` validates `x86_64` | not applicable (same OS minimum) |
| Universal builds | 14.0 | CI release matrix builds a universal DMG (`arm64 x86_64`) used by Sparkle; `make release` defaults to `ARCHS="arm64 x86_64"` | not applicable |

The app is macOS-only; there are no iOS, iPadOS, or watchOS targets.

## Feature-level requirements

| Feature | Requirement | Degradation when unmet |
|---|---|---|
| Keyboard transformation | Accessibility permission (`KeyboardService.requestAccessibilityPermission`); system-wide event tap | typing stays untransformed until granted — the app runs, the feature does not |
| On-device Apple Translation | macOS 15+ (`TranslationPlatformCapability` is constructed by the app layer; Apple Translation is gated with `if #available(macOS 15.0, *)` in `AppTranslationRuntime`) | on macOS 14 the Apple provider is unavailable; Automatic resolution falls back to the first configured cloud provider |
| Cloud translation providers | macOS 14+; optional per-provider API key in Keychain | provider cards hidden or marked setup-required until credentials exist |
| Sparkle updates | macOS 14+; HTTPS feed URL and EdDSA public key supplied at build time | update checks disabled — a build without the release environment resolves `SUPublicEDKey` empty or to a literal `$(...)` token, which `UpdateService.hasReleaseConfiguration` rejects at init |
| Launch at login | macOS 14+; `SMAppService.loginItem` (login helper target) | setting reports `unsupported`/`failed` status in the System settings card |
| Clipboard manager | macOS 14+; no special permission (system pasteboard APIs) | feature simply off by default; no entitlement required |

## Deprecation horizon

No older platform is currently deprecated and no removal date is scheduled:
macOS 14.0 support is the declared floor in
[product overview](../product/overview.md) and the project file, and the
changelog records no deprecation.
