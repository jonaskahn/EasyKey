# Operations

_Last reviewed: 2026-08-15_

This section covers how a running EasyKey is delivered: the single deployable artifact, the distribution channels that carry it, and how each channel authenticates the artifact. Operators and engineers answering "how does this app get built, shipped, and distributed?" start here.

## At a glance

EasyKey has exactly one deployable artifact — a universal DMG — and one delivery environment: the public release channel, fed by a tag-triggered CI workflow whose release is draft-gated by the maintainer. Two distribution channels consume the same artifact: direct DMG download and Sparkle in-app updates. Because the app runs entirely on the user's Mac with no server components, every channel is manual, maintainer-operated, and authenticated with the evidence the child document records. The child document owns the exact steps and facts.

## Scope and boundaries

This section owns *delivery and distribution*: the artifact, the channels that carry it, and how each authenticates it. It does not own how the artifact is built and tested, which is an engineering workflow ([engineering](../engineering/README.md)), nor the security posture around the app ([security](../security/README.md)). Nothing here restates the steps a child document owns.

## Start here

| You want to | Read |
|---|---|
| See how users receive updates and how each channel authenticates the artifact | [distribution.md](distribution.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Distribution](distribution.md) | What channels ship the app, and how is the artifact discovered and authenticated in each? |
<!-- docforge-children:end -->

## Related sections

- README — the parent index of all sections.
- [Engineering](../engineering/README.md) — the build and test workflow the artifact comes from.
- [Reference](../reference/README.md) — platform compatibility and configuration facts the operations steps depend on.
- [Security](../security/README.md) — the security policy and permission footprint that govern the app.
