# Migrations

_Last reviewed: 2026-08-15_

This section documents what happens to a user's data and preferences when EasyKey moves between versions — which stored shapes change, what is upgraded automatically, what is lost, and how to verify the migration. It exists so engineers shipping a breaking change and users upgrading across versions can both find out what to expect. The reader with a specific concern about stored state should start at the child document below.

## At a glance

EasyKey persists user settings across versions, so every schema change is a migration event. The one migration document written so far covers the settings file: how schemas are versioned, how upgrades behave, and what happens on rollback. It answers the question a user or engineer asks at upgrade time: what happens to my settings when the app updates?

## Scope and boundaries

A document belongs here when it is a migration guide for user-facing stored state — what changes across versions and how to verify it. Related material with a different home stays there:

- the current settings schema and behavior — owned by the [product overview](../overview.md);
- how the released artifact is deployed and distributed across channels — owned by the [operations](../../operations/README.md) section;
- the supported version matrix — owned by the [compatibility reference](../../reference/compatibility.md).

## Start here

| You want to | Read |
|---|---|
| Know what happens to user settings across versions | [Migration settings](settings.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Migration settings](settings.md) | What happens to user settings across versions — which schemas are migrated, what changes, and how to verify? |
<!-- docforge-children:end -->

## Related sections

- [Product](../README.md) — the parent index of this folder.
- [Documentation](../../README.md) — the repository docs index.
