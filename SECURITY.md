# Security policy

_Last reviewed: 2026-08-27_

**0.0.14** is the only version in scope for security reports. Report through this repository’s issue tracker, marked as a security report. There is no published private contact, no `security.txt`, and no published safe-harbor commitment.

Technical posture (threat model, data classes, permissions) is owned by compact [security](docs/security.md). Sparkle HTTPS appcast and EdDSA-signed update archives are owned by compact [engineering](docs/engineering.md).

## Supported versions

| Version | Supported |
|---|---|
| 0.0.14 | yes — current marketing version and the README version badge |
| Older tagged releases | no documented support window; treat only 0.0.14 as in scope |

In scope for reports:

- EasyKey.app, the typing engine, and the keyboard service
- The login helper
- The Sparkle update channel (HTTPS appcast plus EdDSA-signed archives)
- Data handling and platform permissions as described in [security](docs/security.md)

Not authorized:

- Destructive testing
- Data exfiltration
- Denial-of-service of other users’ machines
- Social engineering of the maintainer or other users

## Reporting a vulnerability

This repository publishes no issue template and no dedicated private reporting address. Open a repository issue and mark it as a security report so it is triaged as one.

What to include:

- Reproduction steps, app version (for example 0.0.14), and macOS version
- Believed impact, and which data or capability is affected
- Configuration that matters (permissions granted, providers configured, persistence enabled)

What not to do:

- Do not probe beyond reproducing the issue
- Do not exfiltrate data
- Do not use social engineering
- Do not attach real API keys, Keychain exports, or other secrets to a public issue

## Response expectations

No acknowledgement, assessment, or disclosure SLA is published, and this page does not invent one. As a coordinated-disclosure default, reports are intended to be acknowledged, assessed, and addressed within 90 days, coordinating disclosure with the reporter before publicizing.

No safe-harbor commitment has been published for this project; this page does not grant one.
