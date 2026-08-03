---
id: "product_index"
title: "Product"
docforge_provenance:
  schema: "2.0"
  doc_id: "product_index"
  path: "docs/product/README.md"
  generated_at: "2026-08-03T09:30:00Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "orientation"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "product"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/product/overview.md"
          role: "doc"
          git_blob: "85ccf9556dca36aadb79f1610d3ad0bc6f21e143"
        - path: "docs/product/quickstart.md"
          role: "doc"
          git_blob: "c332d0281fddf0ba3fc7cdd707abd44752e89d82"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/product/overview.md"
          role: "doc"
          git_blob: "85ccf9556dca36aadb79f1610d3ad0bc6f21e143"
        - path: "docs/product/accessibility.md"
          role: "doc"
          git_blob: "24956c41a0a1f86e6d2352f017eb9435dc815269"
        - path: "docs/product/localization.md"
          role: "doc"
          git_blob: "fdf4dbdfc4386bc9ad24bb5fa3f197dfb13225f1"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/product/overview.md"
          role: "doc"
          git_blob: "85ccf9556dca36aadb79f1610d3ad0bc6f21e143"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/product/overview.md"
          role: "doc"
          git_blob: "85ccf9556dca36aadb79f1610d3ad0bc6f21e143"
        - path: "docs/product/quickstart.md"
          role: "doc"
          git_blob: "c332d0281fddf0ba3fc7cdd707abd44752e89d82"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/product/overview.md"
          role: "doc"
          git_blob: "85ccf9556dca36aadb79f1610d3ad0bc6f21e143"
        - path: "docs/product/quickstart.md"
          role: "doc"
          git_blob: "c332d0281fddf0ba3fc7cdd707abd44752e89d82"
        - path: "docs/product/accessibility.md"
          role: "doc"
          git_blob: "24956c41a0a1f86e6d2352f017eb9435dc815269"
        - path: "docs/product/localization.md"
          role: "doc"
          git_blob: "fdf4dbdfc4386bc9ad24bb5fa3f197dfb13225f1"
        - path: "docs/product/migrations/README.md"
          role: "doc"
          git_blob: "509256d3bd9b26366032d444fda256e2fe90423a"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "be324cfd1a847e1b3c9162f9196e9be1fd526347"
      unresolved: []
---
# Product

_Last reviewed: 2026-08-03_

This section tells the product story of EasyKey: what the app is, who it is for, how a new user gets to their first result, and the quality gates the product stands behind — accessibility behavior and interface localization. Engineers and product-minded readers who want the "what and why" before the "how" should start here; the engineering detail behind the claims lives in the sibling sections.

## At a glance

EasyKey is a menu-bar utility for typing Vietnamese in any application with Telex, Simple Telex, or VNI rules, plus a private clipboard history and opt-in translation — all keyboard transformation happens on-device with no analytics or telemetry. The section covers four facets: what the product is and who it serves, the install-to-first-result path, the verified accessibility behaviors, and the two supported interface locales. Product promises stated here are backed by the named verification methods in each child document.

## Scope and boundaries

This section owns the product's *behavior and promises*: what EasyKey does, who it is for, how to get started, accessibility conformance practice, and language support. It does not own how the system is built ([architecture](../architecture/README.md)), the release and update mechanics ([engineering](../engineering/README.md)), or the security posture behind the privacy promises ([security](../security/README.md)).

## Start here

| You want to | Read |
|---|---|
| Learn what EasyKey is and who it is for | [overview.md](overview.md) |
| Install the app and get to your first Vietnamese result | [quickstart.md](quickstart.md) |
| Verify accessibility behaviors before relying on them | [accessibility.md](accessibility.md) |
| Understand which languages the interface ships in and how lookups fall back | [localization.md](localization.md) |

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

- [Documentation home](../README.md) — the parent index of all sections.
- [Architecture](../architecture/README.md) — how the product promises are implemented.
- [Security](../security/README.md) — privacy posture and data handling behind "no telemetry".
