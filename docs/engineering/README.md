# Engineering

_Last reviewed: 2026-08-15_

This section is the working guide for anyone building or testing EasyKey: how to set up a development environment, how the test suites are organized, which conventions the rulebook enforces, and what publishing exists — or deliberately does not — for the in-repo frameworks. Engineers new to the project should start here.

## At a glance

The engineering workflow runs from a Makefile-driven toolchain: local setup builds the project with Xcode and runs its test bundles, and CI enforces lint, tests, and a coverage gate. Packaging and distribution of the released artifact are covered by the operations section; three documents own the engineering steps: setup, testing, and publishing. The workflow facts live in those documents — this page only routes to them.

## Scope and boundaries

This section owns the *process* of working on the repository: local setup, test organization, enforced conventions, and what publishing exists for the in-repo frameworks. It does not own why the architecture looks the way it does ([architecture](../architecture/README.md)) or the operational channels that carry the released artifact ([operations](../operations/README.md)). The engineering rulebook (notes/rulebook.md) is a hand-written document — canonical for conventions, not generated, and referenced from here rather than restated.

## Start here

| You want to | Read |
|---|---|
| Build EasyKey from source and run the suite locally | [setup.md](setup.md) |
| Run unit, integration, or UI tests — locally or in CI shards | [testing.md](testing.md) |
| Understand the framework artifacts and what publishing does and does not exist | [publishing.md](publishing.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Local setup](setup.md) | How do I build EasyKey from source and run its test suite on my machine? |
| [Testing guide](testing.md) | How are tests organized by layer, and how do I run the unit, integration, and UI suites? |
| [Publishing](publishing.md) | What are the in-repo framework artifacts, and what publishing pipeline exists — or deliberately does not exist — for them? |
<!-- docforge-children:end -->

## Related sections

- README — the parent index of all sections.
- [Operations](../operations/README.md) — the distribution channels that carry the released artifact.
- [Reference](../reference/README.md) — stack, compatibility, and configuration facts the workflows depend on.
