# Contributing

_Last reviewed: 2026-08-27_

This repository accepts focused, reviewable changes to EasyKey.app, its frameworks, tests, and docs. Follow this page from a fresh checkout through required checks and a pull request against `main`; a maintainer reviews and merges — that is the first point a contributor cannot complete alone.

## Before you start

| You want to | Read |
|---|---|
| Get a local environment running | [Engineering — setup](docs/engineering.md#setup) |
| Understand the test expectations | [Engineering — testing](docs/engineering.md#testing) |
| Follow this repository's coding conventions | [Engineering](docs/engineering.md) |
| See who reviews which area | [Ownership](docs/contributing.md#ownership) |

Xcode 15 or later, macOS 14.0 or later, and Git with command-line tools. SwiftLint and SwiftFormat are optional locally (`make lint` and `make format` skip them when absent). No credentials or special access are needed to build, test, and run Debug. Signed distribution needs extra secrets; that table lives in the [setup guide](docs/engineering.md#setup).

## The path to an accepted change

1. **Set up the workspace** — clone, then `make build` and `make run`. Full steps and recovery live in [setup](docs/engineering.md#setup). Confirm a clean baseline with `make qa`.
2. **Make one focused change** — keep the change reviewable, separate behavior from mechanical refactors, and update tests and documentation with the code they describe. Import direction is App → Kit → Core; architecture fitness tests fail the suite if Core imports UI or reactive frameworks, or if Core or Kit import the app module. More setup and test commands live in [engineering](docs/engineering.md).
3. **Run the required checks** — `make build`, `make test`, `make coverage`, and `make qa` locally; `make lint` and `make format` when the tools are installed. CI on pull requests to `main` re-runs the merge gates (see Required checks).
4. **Open a pull request targeting `main`** — CI must pass; a maintainer reviews and merges. Do not treat a green hosted-runner job as proof that Accessibility, onboarding UI, or live TranslationSession cases passed on a real Mac; that distinction is owned by [operations](docs/operations.md).

## Required checks

| Check | Where it runs | Owning document |
|---|---|---|
| Build | `make build` (Debug `EasyKey.app`) | [Setup](docs/engineering.md#setup) |
| Tests | `make test` — serial unit, integration, and UI suite with code coverage | [Testing](docs/engineering.md#testing) |
| Coverage | `make coverage` — 90% line coverage excluding the login helper (`COVERAGE_THRESHOLD`, default 90); CI `coverage` job after test shards | [Testing](docs/engineering.md#testing) |
| QA gate | `make qa` — full `xcodebuild test` plus fixture and test-target registration checks | [Testing](docs/engineering.md#testing) |
| Structure | CI `structure` job — standalone Debug builds of EasyEngineCore and EasyKeyKit, plus test-target registration | [Testing](docs/engineering.md#testing) |
| Style | Local: `make lint` / `make format` (skipped if tools are missing). CI `lint` job: `swiftformat --lint .` and `swiftlint lint` (required to merge) | [Testing](docs/engineering.md#testing) |
| Review | Pull request against `main`; maintainer merge | [Ownership](docs/contributing.md#ownership) |

Local `make test-parallel` still runs shards serially on one Mac; overlapping UI and unit shards on one machine is not a supported shortcut. Coverage and CI merge semantics are also described in [operations](docs/operations.md).

## Ownership and escalation

This repository has no path-based review assignment file and names no review team in-tree. Structural boundaries (what each layer may import, and translation log/persistence rules) are the [ownership table](docs/contributing.md#ownership). Security-sensitive or privacy-affecting changes: read the [security policy](SECURITY.md) and the [security section](docs/security.md) before you submit. Release, versioning, and publication: [release](docs/engineering.md#release), [publishing](docs/engineering.md#publishing), and [distribution](docs/operations.md#distribution).

## If this page didn't answer your question

Start at the [documentation index](docs/README.md). Build, test, and ship procedures are in [engineering](docs/engineering.md). Deployable shape is in [architecture](docs/architecture.md). CI versus operator notarization is in [operations](docs/operations.md). Vulnerability reports stay on [SECURITY.md](SECURITY.md).
