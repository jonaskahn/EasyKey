---
docforge_provenance:
  schema: "2.0"
  doc_id: "security_root"
  path: "SECURITY.md"
  generated_at: "2026-08-03T09:24:40Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "router"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "security-policy"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "docs/_archive/PRIVACY.md"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
          role: "doc"
      unresolved: []
    - id: "security-stance"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "docs/security/data-handling.md"
          git_blob: "c7369f8633033883243a6f14efce1b33c70da9ea"
          role: "doc"
      unresolved: []
    - id: "supported-scope"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "config"
      unresolved: []
    - id: "reporting-a-vulnerability"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "docs/security/threat-model.md"
          git_blob: "11052cc08965a7b20651d827ee29645154b0578c"
          role: "doc"
      unresolved: []
    - id: "response-expectations"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "docs/security/threat-model.md"
          git_blob: "11052cc08965a7b20651d827ee29645154b0578c"
          role: "doc"
      unresolved: []
    - id: "where-the-detail-lives"
      sources:
        - path: "docs/_archive/PRIVACY.md"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
          role: "doc"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
      unresolved: []
---
# Security policy

_Last reviewed: 2026-08-03_

EasyKey is a private-by-design macOS menu-bar utility. This page states the security stance, the supported scope for reports, and how to report a vulnerability. Technical analysis lives in the [security section](docs/security/README.md), not here.

## Security stance

- Typing transformation, macros, encoding conversion, settings, and on-device translation run entirely on the Mac; EasyKey collects no analytics or telemetry.
- The clipboard manager is off by default; optional persisted history is sealed with AES-GCM under a 256-bit key held in a device-only, non-synchronizing Keychain item.
- Cloud-translation credentials live in device-only, non-synchronizing Keychain items and never appear in settings files, logs, or exports.
- Cloud translation is strictly opt-in: source text leaves the Mac only from EasyKey translation surfaces, directly to the provider the user chose, after a first-use disclosure.
- Updates are distributed only through the Sparkle channel: HTTPS appcast plus EdDSA-signed archives ([RELEASE.md](docs/engineering/release.md)).

## Supported scope

The current release is **0.0.7** (the `v0.0.7` tag, matching `MARKETING_VERSION`). There is no documented support window for older versions; treat the latest release as the supported one.

In scope for security review and reports:

- The EasyKey application, engine, and keyboard-service components.
- The login helper and the Sparkle update channel.
- Data handling and permissions as described in the [security section](docs/security/README.md).

Not authorized under any report or test: destructive testing, data exfiltration, denial-of-service of other users' machines, or social engineering of the maintainer or other users.

## Reporting a vulnerability

This repository publishes no issue template and no dedicated private reporting address; please report through the repository's issue tracker, marked as a security report so it is triaged as one.

What to include in a report:

- Steps to reproduce, with the app version (for example 0.0.7) and macOS version.
- What you believe the impact is, and which data or capability is affected.
- Any configuration that matters (permissions granted, providers configured, persistence enabled).

What not to do: do not probe in ways that go beyond reproducing the issue, do not exfiltrate data, and do not use social engineering.

## Response expectations

No response-time commitment has been published, and this page makes none up. As a coordinated-disclosure default, we intend to acknowledge, assess, and address reports within a 90-day window, coordinating disclosure with the reporter before publicizing. No safe-harbor commitment has been published for this project.

## Where the detail lives

- [Security section](docs/security/README.md) — routes to the [threat model](docs/security/threat-model.md), [data handling](docs/security/data-handling.md), and [platform permissions](docs/security/permissions.md).
- [Privacy](docs/security/data-handling.md) — data flows, provider handling, and what stays on-device.
- [RELEASE.md](docs/engineering/release.md) — update channel security: HTTPS appcast and EdDSA signatures.
