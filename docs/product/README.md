# Product

_Last reviewed: 2026-08-15_

This section tells the product story of EasyKey: what the app is, who it is for, how a new user gets to their first result, and the quality gates the product stands behind — verified accessibility behavior and interface localization. Engineers and product-minded readers who want the "what and why" before the "how" should start here; the engineering detail behind the claims lives in the sibling sections.

## At a glance

EasyKey is a menu-bar utility for typing Vietnamese in any application with Telex, Simple Telex, or VNI rules, plus a private clipboard history and opt-in translation — all keyboard transformation happens on-device with no analytics or telemetry. The section covers five facets: what the product is and who it serves, the install-to-first-result path, the verified accessibility behaviors, the supported interface locales, and what happens to user settings when the app upgrades (see [migrations/README.md](migrations/README.md)). Product promises stated here are backed by the named verification methods in each child document.

## Scope and boundaries

This section owns the product's *behavior and promises*: what EasyKey does, who it is for, how to get started, accessibility conformance practice, and language support. It does not own how the system is built ([architecture](../architecture/README.md)), the release and update mechanics ([engineering](../engineering/README.md)), or the security posture behind the privacy promises ([security](../security/README.md)). Migration records that affect user-visible settings are covered here; how the released artifact is deployed and distributed across channels lives in [operations](../operations/README.md).

## Start here

| You want to | Read |
|---|---|
| Learn what EasyKey is and who it is for | [overview.md](overview.md) |
| Install the app and get to your first Vietnamese result | [quickstart.md](quickstart.md) |
| Verify accessibility behaviors before relying on them | [accessibility.md](accessibility.md) |
| Understand which languages the interface ships in and how lookups fall back | [localization.md](localization.md) |
| See what changes when the app moves between versions | [migrations/README.md](migrations/README.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Product overview](overview.md) | What is EasyKey, what does it do, and who is it for? |
| [Quickstart](quickstart.md) | How do I download, install, and reach my first typed Vietnamese result? |
| [Accessibility](accessibility.md) | Which accessibility behaviors are verified, and by what method? |
| [Localization](localization.md) | Which interface locales are supported, and what happens when a string is missing at runtime? |
| [Migrations](migrations/README.md) | What happens to user settings when the app moves between versions — what is migrated, what changes, and how is it verified? |
<!-- docforge-children:end -->

## Related sections

- README — the parent index of all sections.
- [Architecture](../architecture/README.md) — how the product promises are implemented.
- [Engineering](../engineering/README.md) — how the product is built, tested, and shipped.
- [Operations](../operations/README.md) — how the released channels carry the product across versions.
- [Security](../security/README.md) — privacy posture and data handling behind "no telemetry".
