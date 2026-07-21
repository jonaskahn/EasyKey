<p align="center">
  <img src="docs/assets/logo.png" width="128" height="128" alt="EasyKey logo"><br>
  <strong>EasyKey</strong><br><br>
  <a href="https://github.com/jonaskahn/EasyKey/releases/latest"><img src="https://img.shields.io/badge/version-0.0.3-0969da?style=flat-square" alt="Latest version"></a>
  <a href="https://github.com/jonaskahn/EasyKey/actions/workflows/ci.yml"><img src="https://github.com/jonaskahn/EasyKey/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <a href="https://github.com/jonaskahn/EasyKey/actions/workflows/ci.yml"><img src="https://img.shields.io/badge/coverage-90%25-brightgreen?style=flat-square" alt="90% coverage gate"></a>
  <a href="https://github.com/jonaskahn/EasyKey/releases/latest"><img src="https://img.shields.io/badge/download-Releases-111111?style=flat-square" alt="Download EasyKey"></a>
  <br><br>
  <i>Fast, private Vietnamese typing for macOS with some sweets</i>
</p>

---

EasyKey is a native Vietnamese input utility built for accurate typing across macOS. It combines a clean-room Telex and VNI engine with per-application preferences, text expansion, legacy encoding support, and practical compatibility controls.

```text
vieejt nam  →  việt nam
```

Typing is processed locally. EasyKey uses the macOS Accessibility API and a `CGEvent` tap instead of Input Method Kit. Apple Translation is on-device on macOS 15 or later. Optional cloud translation sends source text directly to the selected provider only from EasyKey translation surfaces. EasyKey includes no analytics or telemetry.

## ✨ Highlights

- ⌨️ Telex, VNI, and Simple Telex typing rules
- 🔤 Unicode, Unicode Combining, TCVN3, VNI-Windows, CP1258
- 🧩 Trigger-based macro expansions with import/export
- 🔀 Smart Switch remembers language per application
- 📋 Private clipboard manager with optional encrypted history
- 🌍 Apple on-device translation or cloud providers
- 🛠️ Per-application compatibility and ignore lists
- 🚀 Signed Sparkle updates, English/Vietnamese localization

See [Telex Rule Set](./docs/TELEX.md) for exact full Telex, Simple Telex, tone-placement, undo, and restoration behavior.

## ⌨️ Default Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌥` + `V` | Open clipboard manager |
| `⌥` + `A` | Open translate panel |
| `⌥` + `Z` | Switch input language |

All shortcuts are configurable in Settings.

## 🔒 Private by Design

EasyKey processes keyboard transformation and preferences on your Mac. General keyboard input is never translated or uploaded. Apple Translation runs on-device on macOS 15 or later.

Cloud translation is optional. In the translation editor, menu popover, or `⌥A` panel, user-entered or captured source text is sent directly to the selected provider when you translate or when the configured auto-translation delay expires. Each edit resets that delay. A first-use disclosure identifies every cloud provider before its first request. EasyKey does not proxy requests through its own service.

Cloud credentials use device-only, non-synchronizing Keychain items. EasyKey does not persist source text, results, or history, and collects no usage data. Providers handle submitted text under their own terms. Credential validation and signed Sparkle update checks are separate network activity; validation does not submit source text. See [Privacy](./PRIVACY.md) for data flows and provider links.

Accessibility permission is required because EasyKey observes and transforms keyboard events system-wide. The permission can be reviewed or revoked at any time in **System Settings → Privacy & Security → Accessibility**.

The **clipboard manager is off by default**. When enabled, it keeps local history for copied text, URLs, images, and file references. Concealed, transient, and auto-generated content is rejected. History remains in memory unless **Keep history after restart** is enabled; then it is AES-GCM encrypted on-device with an unlocked-this-device-only, non-synchronizing Keychain key. Disabling persistence deletes stored data. Clipboard content is never logged or uploaded. Ignored-applications filtering is best effort, not a security boundary, because macOS cannot always identify a clipboard change's source application.

## 📸 Screenshots

| Menu bar | Settings |
|----------|----------|
| ![EasyKey menu bar popup](docs/assets/Popup.png) | ![EasyKey settings](docs/assets/Settings.png) |

## 📋 Requirements

- macOS 14.0 Sonoma or later
- Apple silicon or Intel Mac
- Accessibility permission

## 📦 Installation

1. Download the latest universal DMG from [GitHub Releases](https://github.com/jonaskahn/EasyKey/releases/latest).
2. Open `EasyKey-<version>-universal.dmg`.
3. Drag **EasyKey** into **Applications**.
4. Launch EasyKey and grant Accessibility access when prompted.

Current public builds are universal and ad-hoc signed, but not Developer ID notarized. On first launch, macOS may block the application:

1. Control-click **EasyKey** in **Applications**, then choose **Open**.
2. Confirm **Open** in the security dialog.
3. If needed, open **System Settings → Privacy & Security** and choose **Open Anyway**.

EasyKey runs primarily from the menu bar. Typing transformation remains unavailable until Accessibility access is granted.

---

## 🛠️ Build from Source

Requires Xcode 15+, Git, and command-line developer tools. SwiftLint and SwiftFormat are optional.

```bash
git clone https://github.com/jonaskahn/EasyKey.git
cd EasyKey
make build
make test
make run
```

Create a local universal DMG without signing or notarization credentials:

```bash
make local-dmg
```

Output: `build/EasyKey-<version>-universal.dmg`

Direct Xcode build:

```bash
xcodebuild \
  -project EasyKey.xcodeproj \
  -scheme EasyKeyApp \
  -configuration Debug \
  -destination "platform=macOS"
```

### Make Commands

Run `make` or `make help` for the complete command reference.

| Development | Purpose |
|---------|---------|
| `make build` | Build the debug application |
| `make run` | Build and launch EasyKey |
| `make test` | Run unit and UI tests serially with code coverage |
| `make test-parallel` | Build once, then run tests as parallel shards (faster) |
| `make coverage` | Run tests and enforce the 90% coverage gate |
| `make coverage-parallel` | Sharded parallel run plus the coverage gate |
| `make lint` | Run SwiftLint when installed |
| `make format` | Run SwiftFormat when installed |

| Quality and Cleanup | Purpose |
|---------|---------|
| `make qa` | Run the full QA gate and verify generated artifacts |
| `make clean` | Remove build artifacts |
| `make clean-local` | Quit EasyKey and remove local app and test data |
| `make clean-all` | Remove build artifacts and local data |

| Release | Purpose |
|---------|---------|
| `make release` | Build an unsigned universal Release application |
| `make local-dmg` | Package an ad-hoc signed universal DMG |
| `make archive` | Create a signed archive using Developer ID configuration |
| `make export` | Export the application from an archive |
| `make verify-arch` | Verify arm64 and x86_64 architectures |
| `make verify-release` | Run release integrity checks |
| `make dmg` | Build a signed universal distribution DMG |

Signed distribution requires Developer ID, notarization, and Sparkle release credentials. See [RELEASE.md](./RELEASE.md) for the complete release process.

### Architecture

```text
EasyKey/
├── EasyKeyApp/             # SwiftUI and AppKit application shell
│   ├── Features/           # Onboarding and settings feature slices
│   ├── Coordination/       # Menu bar, windows, login item, and app wiring
│   └── Settings/           # Observable settings integration
├── EasyKeyKit/             # macOS keyboard-service adapters
│   └── Keyboard/           # Event tap, input pipeline, and diagnostics
├── EasyEngineCore/         # Framework-independent domain logic
│   ├── Engine/             # Transformation rules, tones, and encodings
│   ├── Settings/
│   ├── Macros/
│   ├── SmartSwitch/
│   ├── Converter/
│   └── Diagnostics/
├── EasyKeyLoginHelper/     # Launch-at-login helper
├── EasyKeyTests/           # Unit and architecture fitness tests
├── EasyKeyUITests/         # User-interface tests
├── Fixtures/               # Behavioral test fixtures
├── Scripts/                # QA, packaging, and release automation
└── EasyKey.xcodeproj/
```

Dependencies point inward: `EasyKeyApp → EasyKeyKit → EasyEngineCore`

- **EasyEngineCore** contains the independent typing domain and has no AppKit, SwiftUI, or Combine dependency.
- **EasyKeyKit** adapts domain behavior to macOS event taps, keyboard pipelines, and synthesis.
- **EasyKeyApp** provides feature-oriented UI, coordination, localization, settings, and update delivery.

Engineering practices and architectural rules are documented in [CONVENTIONS.md](./CONVENTIONS.md).

### Quality

- CI-enforced 90% line-coverage threshold, excluding the login helper
- CI splits tests into parallel shards, then merges the result bundles for the coverage gate
- Unit, UI, behavioral fixture, and architecture fitness tests
- Universal arm64 and x86_64 release verification
- SwiftLint and SwiftFormat support
- Public API documentation and production force-unwrap restrictions

```bash
make test
make qa
```

`make test-parallel` runs the same shards locally. All shards share one `UserDefaults`
domain on a single Mac, so UI shards may flake; use `make test` for a reliable serial run.

---

## 🙏 Acknowledgements

EasyKey was inspired by [OpenKey](https://github.com/tuyenvm/OpenKey) by Mai Vũ Tuyên and [UniKey](https://www.unikey.org/) by Phạm Kim Long.

Heartfelt thanks to both authors for their pioneering work and lasting contributions to Vietnamese typing software.

---

## 📄 License and Notices

EasyKey is available under the [MIT License](./LICENSE).

This project is an independent clean-room implementation based on public typing conventions, character standards, and observed behavior. See [NOTICE](./NOTICE) for the implementation statement and [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md) for third-party acknowledgements.
