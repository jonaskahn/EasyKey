---
id: "adr-single-instance"
title: "Adr Single Instance"
description: "Decision: terminate at launch when another instance is already running for the current user."
docforge_provenance:
  schema: "2.0"
  doc_id: "adr-single-instance"
  path: "docs/architecture/decisions/single-instance.md"
  generated_at: "2026-08-13T11:25:23Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "context-and-problem-statement"
      sources:
        - path: "EasyKeyApp/AppDelegate.swift"
          git_blob: "a0ba11e8c1cc4bd2a48d1cd346edfade871c67b8"
          role: "code"
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
          role: "code"
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
          role: "history"
      unresolved: []
    - id: "decision"
      sources:
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
          role: "code"
        - path: "EasyKeyApp/AppDelegate.swift"
          git_blob: "a0ba11e8c1cc4bd2a48d1cd346edfade871c67b8"
          role: "code"
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
          role: "history"
      unresolved: []
    - id: "consequences"
      sources:
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
          role: "code"
        - path: "EasyKeyApp/AppDelegate.swift"
          git_blob: "a0ba11e8c1cc4bd2a48d1cd346edfade871c67b8"
          role: "code"
      unresolved: []
    - id: "confirmation"
      sources:
        - path: "EasyKeyTests/AppCoordinatorTests.swift"
          git_blob: "5a9fc0f92803914f6b82f175f9f15693ee1c492b"
          role: "test"
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
          role: "history"
      unresolved: []
---
# 5. Terminate at launch when another instance is already running for the current user

- **Status:** accepted
- **Date:** 2026-07-23
- **Deciders:** project maintainer

## Context and problem statement

EasyKey is a menu-bar accessory app: launching it twice would install two CGEvent taps and two clipboard monitors against the same user session, duplicating every keystroke transformation and clipboard capture. There is no visible window to warn about a duplicate, and the second instance must never reach the point of owning the event tap. The guard is per-user — two users logged into the same Mac may each legitimately run the app. The launch path therefore terminates early when `AppCoordinator.isOnlyInstanceForCurrentUser()` reports another live instance, before the coordinator or any service is created. The test seam for this check was documented in commit 1a1ee32 ("docs(app): document test seam in AppCoordinator.isOnlyInstanceForCurrentUser").

## Considered options

- **Running-applications scan by bundle identifier** — chosen: compare PIDs from `NSRunningApplication.runningApplications(withBundleIdentifier:)` against the current process.
- **Distributed-notification handshake** — an instance announces itself and later instances back off.
- **Lock file** — a pidfile under Application Support.
- **Let both instances run** — rejected: duplicate taps and monitors are a correctness bug, not a UX preference.

## Decision

We chose **the launch-time scan**, implemented as `AppCoordinator.isOnlyInstanceForCurrentUser(otherProcessIdentifiers:)`, with the process-list query injected so tests never spawn a real second process. `AppDelegate.applicationDidFinishLaunching` calls it before creating the coordinator and calls `NSApp.terminate(nil)` when another instance of the same bundle identifier is running; UI-testing launches bypass the guard. (AppDelegate.swift, AppCoordinator.swift)

## Decision drivers

- The duplicate-instance failure mode is severe (double key events, double clipboard capture) and must be prevented before any service starts.
- Per-user scoping falls out of `NSRunningApplication`, which enumerates the current user session.
- The injected `otherProcessIdentifiers` closure is the documented test seam (commit 1a1ee32), so the guard is testable without spawning processes.

## Option comparison

| Option | Good | Neutral | Bad |
|---|---|---|---|
| Launch-time scan | zero persistent state; per-user correct; trivial to test | race window if two launches overlap | second instance quits without bringing the first to the front |
| Distributed-notification handshake | can carry a "please activate me" message | — | more moving parts; notification delivery is not guaranteed |
| Lock file | simple | stale pidfiles need handling | fragile across crashes; awkward per-user semantics |
| Let both run | no guard code | — | duplicate taps, duplicate clipboard capture, confusing UX |

## Consequences

**Positive:** at most one event tap and one clipboard monitor per user session; the guard runs before any service is constructed, so a duplicate launch has no side effects; the check is unit-testable without process spawning.

**Negative:** two near-simultaneous launches can race past the check (it is not re-run), and the second instance terminates without activating the first, so a user who double-launches sees no window.

**Neutral:** UI-testing launches deliberately skip the guard because the test harness starts its own app instance.

## Revisit if

- Launch-by-handle behaviors matter (for example opening a document or URL should activate the existing instance instead of exiting).
- The login helper and the main app can start concurrently in a way that trips the guard.
- macOS changes `NSRunningApplication` semantics for accessory apps.

## Confirmation

`AppCoordinatorTests` covers both outcomes through the injected seam: a process list without other instances returns true, and a list containing another PID returns false. The seam itself is documented in the production code (commit 1a1ee32). Tests run under `make test`; the 90% line-coverage gate is enforced by `make coverage` and CI.
