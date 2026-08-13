---
id: "security_root"
title: "Security Root"
description: "Supported scope, reporting path, response expectations, safe harbor"
docforge_provenance:
  schema: "2.0"
  doc_id: "security_root"
  path: "SECURITY.md"
  generated_at: "2026-08-13T12:18:58Z"
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
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          git_blob_normalized: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
      unresolved: []
    - id: "security-stance"
      sources:
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          git_blob_normalized: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
        - path: "docs/security/data-handling.md"
          git_blob: "5403a91f4763dbb6e4d1c679f4ec4ff265ac3545"
          git_blob_normalized: "5403a91f4763dbb6e4d1c679f4ec4ff265ac3545"
          role: "doc"
      unresolved: []
    - id: "supported-scope"
      sources:
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          git_blob_normalized: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "515597131540b043af2543b4d881e1509bbe8c40"
          git_blob_normalized: "515597131540b043af2543b4d881e1509bbe8c40"
          role: "config"
        - path: "docs/engineering/release.md"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          git_blob_normalized: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          role: "doc"
      unresolved: []
    - id: "reporting-a-vulnerability"
      sources:
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          git_blob_normalized: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
        - path: "docs/security/threat-model.md"
          git_blob: "56c7498a173ff87203b6373c09c1e8b6b5f0855d"
          git_blob_normalized: "56c7498a173ff87203b6373c09c1e8b6b5f0855d"
          role: "doc"
      unresolved: []
    - id: "response-expectations"
      sources:
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          git_blob_normalized: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
        - path: "docs/security/README.md"
          git_blob: "67d80093c01fb3815d5db89ba9c5c753806426ae"
          git_blob_normalized: "67d80093c01fb3815d5db89ba9c5c753806426ae"
          role: "doc"
      unresolved: []
    - id: "where-the-detail-lives"
      sources:
        - path: "docs/security/README.md"
          git_blob: "67d80093c01fb3815d5db89ba9c5c753806426ae"
          git_blob_normalized: "67d80093c01fb3815d5db89ba9c5c753806426ae"
          role: "doc"
        - path: "docs/security/data-handling.md"
          git_blob: "5403a91f4763dbb6e4d1c679f4ec4ff265ac3545"
          git_blob_normalized: "5403a91f4763dbb6e4d1c679f4ec4ff265ac3545"
          role: "doc"
        - path: "docs/engineering/release.md"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          git_blob_normalized: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          role: "doc"
      unresolved: []
---
# Security policy

_Last reviewed: 2026-08-13_

EasyKey is a private-by-design macOS menu-bar utility. This page states the security stance, the supported scope for reports, and how to report a vulnerability. Technical analysis lives in the [security section](docs/security/README.md), not here.

## Security stance

- Typing transformation, macros, encoding conversion, settings, and on-device translation run entirely on the Mac; EasyKey collects no analytics or telemetry ([README.md](README.md) and [data handling](docs/security/data-handling.md)).
- The clipboard manager is off by default; optional persisted history is sealed with AES-GCM under a 256-bit key held in a device-only, non-synchronizing Keychain item.
- Cloud-translation credentials live in device-only, non-synchronizing Keychain items and never appear in settings files, logs, or exports.
- Cloud translation is strictly opt-in: source text leaves the Mac only from EasyKey translation surfaces, directly to the provider the user chose, after a first-use disclosure.
- Updates are distributed only through the Sparkle channel: HTTPS appcast plus EdDSA-signed archives ([release guide](docs/engineering/release.md)).

## Supported scope

The current release is **0.0.8**, matching `MARKETING_VERSION` in the Xcode project and the version badge in [README.md](README.md). There is no documented support window for older versions; treat the latest release as the supported one.

In scope for security review and reports:

- The EasyKey application, engine, and keyboard-service components.
- The login helper and the Sparkle update channel.
- Data handling and permissions as described in the [security section](docs/security/README.md).

Not authorized under any report or test: destructive testing, data exfiltration, denial-of-service of other users' machines, or social engineering of the maintainer or other users.

## Reporting a vulnerability

This repository publishes no issue template and no dedicated private reporting address; please report through the repository's issue tracker, marked as a security report so it is triaged as one.

What to include in a report:

- Steps to reproduce, with the app version (for example 0.0.8) and macOS version.
- What you believe the impact is, and which data or capability is affected.
- Any configuration that matters (permissions granted, providers configured, persistence enabled).

What not to do: do not probe in ways that go beyond reproducing the issue, do not exfiltrate data, and do not use social engineering.

## Response expectations

No response-time commitment has been published, and this page makes none up. As a coordinated-disclosure default, we intend to acknowledge, assess, and address reports within a 90-day window, coordinating disclosure with the reporter before publicizing. No safe-harbor commitment has been published for this project.

## Where the detail lives

- [Security section](docs/security/README.md) — routes to the [threat model](docs/security/threat-model.md), [data handling](docs/security/data-handling.md), and [platform permissions](docs/security/permissions.md).
- [Data handling](docs/security/data-handling.md) — data flows, provider handling, and what stays on-device.
- [Release guide](docs/engineering/release.md) — update channel security: HTTPS appcast and EdDSA signatures.
