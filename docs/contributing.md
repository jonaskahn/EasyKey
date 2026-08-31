# Contributing

_Last reviewed: 2026-08-27_

Use this file to learn which EasyKey areas have structural review boundaries and how to escalate when no named owner exists. It orients contributors after they have the clone-to-merge path; it does not replace that path. Read it when you need to know who must approve a layer change, not when you need the commands that gate merge.

## At a glance

The verified contribution path and required checks live in the root [CONTRIBUTING.md](../CONTRIBUTING.md). Follow that file to set up, change, check, and open a pull request. This section owns orientation and ownership: there is no path-based review assignment file file, so review authority is the structural rules the test suite already fails on, plus maintainer merge on `main`.

| You want to | Read |
|---|---|
| Get a change accepted | [CONTRIBUTING.md](../CONTRIBUTING.md) |
| Know who reviews a layer | [Ownership](#ownership) |
| Build, test, or ship | [Engineering](engineering.md) |
| Report a vulnerability | [SECURITY.md](../SECURITY.md) |

## Scope and boundaries

This section owns contributor orientation and ownership boundaries. It does not own the ordered checks, Make targets, or CI job list — those stay in [CONTRIBUTING.md](../CONTRIBUTING.md) and [engineering.md](engineering.md). Adjacent sections own the rest: [engineering.md](engineering.md) (setup, tests, release, publishing), [architecture.md](architecture.md) (blocks and import direction as system shape), [operations.md](operations.md) (CI versus operator DMG), [security.md](security.md) (posture; reporting stays in [SECURITY.md](../SECURITY.md)), [product.md](product.md), [flows.md](flows.md), [reference.md](reference.md), [decisions.md](decisions.md). Parent index: [Documentation](README.md). Compact layout has no extra files under a contributing folder.

| In this file | Answers |
|---|---|
| [Ownership](#ownership) | Who owns this area, and who do I escalate to if they're unavailable? |

## Ownership

No path-based review assignment file file and no in-repo team or channel declaration. Frequent authorship is not treated as ownership. Escalation for every row is the same evidenced path: open a pull request against `main`; a maintainer reviews and merges. There is no named backup reviewer.

| Area | Responsibility boundary | Escalation |
|---|---|---|
| EasyEngineCore | Review authority over Core staying Foundation-only: no AppKit, SwiftUI, Combine, or UIKit, and no import of EasyKey, EasyKeyKit, or EasyKeyApp. The architecture fitness suite fails when those imports appear. | Undetermined named owner — maintainer review on the pull request |
| EasyKeyKit | Review authority over Kit not importing the app module. Permitted dependency direction is App → Kit → Core. | Undetermined named owner — maintainer review on the pull request |
| EasyKey.app | Review authority over the accessory process: UI, settings, clipboard, translation surfaces, Sparkle, and login-item registration. The app may import Kit and Core one-way; Core and Kit must not import the app. | Undetermined named owner — maintainer review on the pull request |
| Translation | Review authority over translation logging and persistence: sensitive values must not reach application logs; persisted settings must not store source or translated text, history, API keys, or prompts; the translation model must not persist via Codable, UserDefaults, or FileManager. Fitness tests fail the suite when those rules break. | Undetermined named owner — maintainer review on the pull request |
| EasyKeyLoginHelper | Review authority over the nested login helper remaining a host launcher. Coverage accounting excludes this target from the 90% line gate. | Undetermined named owner — maintainer review on the pull request |
| Tests | Review authority over architecture-fitness coverage and suite registration. CI fails when a tracked test file is missing from its Xcode target. | Undetermined named owner — maintainer review on the pull request |
