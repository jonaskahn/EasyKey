<p align="center">
  <img src="docs/assets/logo.png" width="128" height="128" alt="EasyKey logo"><br>
  <strong>EasyKey</strong><br><br>
  <a href="https://github.com/jonaskahn/EasyKey/releases/latest"><img src="https://img.shields.io/badge/version-0.0.8-6e3dbc9?style=flat-square" alt="Latest version"></a>
  <a href="https://github.com/jonaskahn/EasyKey/actions/workflows/ci.yml"><img src="https://github.com/jonaskahn/EasyKey/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <a href="https://github.com/jonaskahn/EasyKey/actions/workflows/ci.yml"><img src="https://img.shields.io/badge/coverage-90%25-brightgreen?style=flat-square" alt="90% coverage gate"></a>
  <a href="https://github.com/jonaskahn/EasyKey/releases/latest"><img src="https://img.shields.io/badge/download-Releases-111111?style=flat-square" alt="Download EasyKey"></a>
  <br><br>
  <i>Fast, private Vietnamese typing for macOS</i>
</p>

---

EasyKey is a native Vietnamese input utility that lives in your menu bar: type Vietnamese in any app, keep a private clipboard history, expand macros, and translate — all processed locally on your Mac.

```text
vieejt nam  →  việt nam
```

## 🚀 Install

1. Download the latest universal DMG from [GitHub Releases](https://github.com/jonaskahn/EasyKey/releases/latest).
2. Open the DMG, drag **EasyKey** into **Applications**, and launch it.
3. Grant **Accessibility** access when prompted (required for system-wide typing).
4. EasyKey runs from the menu bar.

> Current builds are ad-hoc signed (not notarized). If macOS blocks the app: Control-click **EasyKey** → **Open**, confirm, or use **System Settings → Privacy & Security → Open Anyway**.

## 🖊️ Usage

### ⌨️ Vietnamese typing

Pick an input method in **Settings → Typing** (Telex, Simple Telex, or VNI; Simple Telex is the default) and just type — Vietnamese is composed in any app. Press `⌥Z` to switch languages. EasyKey remembers the language and encoding per app, so switching to one app doesn't disturb another.

### 📋 Clipboard manager (`⌥V`)

Copy anything — text, URLs, images, file references — then press `⌥V` to search, pin, or paste from recent history. Off by default: enable it in **Settings → Clipboard**. History stays in memory unless you opt into encrypted on-device persistence.

### 🌍 Translation (`⌥C`)

Press `⌥C`, type or paste text, and get a translation in place. Apple Translation runs fully on-device on macOS 15+; or connect a cloud provider (DeepL, Google, OpenAI, Anthropic, Gemini, OpenRouter, Groq) in **Settings → Translation**.

### 🧩 Macros

In **Settings → Macros**, set a trigger such as `addr` and an expansion; typing the trigger expands it in any app.

### 🛠️ Compatibility

In **Settings → System**, pause EasyKey in specific apps or force a language per app — useful for terminals, games, or apps that need literal keystrokes.

## ⌨️ Default Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌥` + `V` | Open clipboard manager |
| `⌥` + `C` | Open translate panel |
| `⌥` + `Z` | Switch input language |

All shortcuts are configurable in Settings.

## 🔒 Private by Design

- Everything is processed on your Mac — no analytics, no telemetry, no typing logs.
- Cloud translation is opt-in: source text goes directly to the provider you choose (never through an EasyKey server), after a first-use disclosure.
- Credentials are stored in device-only Keychain items.
- Clipboard persistence, if enabled, is AES-GCM encrypted with a device-only key.

See [data handling and provider links](./docs/security/data-handling.md) for details.

## 📸 Screenshots

| Menu bar | Settings | Apps |
|----------|----------|-------|
| ![EasyKey menu bar popup](docs/assets/Popup.png) | ![EasyKey settings](docs/assets/Settings.png) | ![EasyKey per-app preferences](docs/assets/Apps.png) |

## 📋 Requirements

- macOS 14.0 Sonoma or later
- Apple silicon or Intel Mac
- Accessibility permission

> **Known issue:** typing in Spotlight (`⌘Space`) can look briefly broken right after opening it, then self-correct — a macOS detection-timing limitation, not an EasyKey defect. See [limitations](./docs/reference/limitations.md).

## 🛠️ For Developers

- Build and test from source: [engineering/setup.md](./docs/engineering/setup.md)
- Release process: [engineering/release.md](./docs/engineering/release.md)
- Engineering conventions: [engineering/rulebook.md](./docs/engineering/rulebook.md)
- Exact Telex rules: [flows/telex.md](./docs/flows/telex.md)

## 🙏 Acknowledgements

Inspired by [OpenKey](https://github.com/tuyenvm/OpenKey) by Mai Vũ Tuyên and [UniKey](https://www.unikey.org/) by Phạm Kim Long — heartfelt thanks to both authors for their pioneering work on Vietnamese typing software.

## 📄 License and Notices

EasyKey is available under the [MIT License](./LICENSE). This project is an independent clean-room implementation based on public typing conventions, character standards, and observed behavior. See [NOTICE](./NOTICE) for the implementation statement and [THIRD_PARTY_NOTICES.md](./docs/THIRD_PARTY_NOTICES.md) for third-party acknowledgements.
