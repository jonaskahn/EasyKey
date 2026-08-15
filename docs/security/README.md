# Security

_Last reviewed: 2026-08-15_

This section documents the security posture of EasyKey: the exact platform permission footprint the app uses, with the manifest evidence for each capability. Engineers reviewing the app, auditors, and anyone making a trust decision about a keystroke-transforming utility should read it. Disclosure practice and the handling of reports are governed by the root Security policy, which this section routes to rather than restates.

## At a glance

The permission footprint is a single bounded question: exactly one TCC-gated capability — Accessibility — plus one login item, everything else ungated with manifest evidence. The child document owns it in depth, and the root Security policy owns disclosure and reporting.

## Scope and boundaries

This section owns the *permission footprint*: which TCC-gated capabilities and ungated resources the app uses, with its manifest evidence. It does not own the implementation of the architecture being secured ([architecture](../architecture.md)) or the operational channels the artifact ships through ([operations](../operations/README.md)). The root Security policy owns disclosure and reporting process; this section never restates a fact a child document or the policy owns.

## Start here

| You want to | Read |
|---|---|
| Verify the exact permission footprint and its manifest evidence | [permissions.md](permissions.md) |
| Understand disclosure and report handling | Security policy |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Permissions](permissions.md) | Which TCC-gated capabilities and ungated resources does the app use, with what evidence? |
<!-- docforge-children:end -->

## Related sections

- README — the parent index of all sections.
- Security policy — the root policy for disclosure, reporting, and handling (related, not a child).
- [Architecture](../architecture.md) — the system design the permission footprint applies to.
- [Operations](../operations/README.md) — the distribution channels the artifact ships through.
