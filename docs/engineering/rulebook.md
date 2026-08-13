---
id: "existing-conventions"
title: "Engineering Conventions"
docforge_provenance:
  schema: "2.0"
  doc_id: "existing-conventions"
  path: "docs/engineering/rulebook.md"
  generated_at: "2026-08-03T10:27:57+00:00"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections: []
---
# Engineering Conventions

These conventions define how Swift code should be designed, written, reviewed, and tested. They apply to production code, tests, scripts, and generated code accepted into the repository.

Project compiles in Swift 5 language mode. Tooling must parse and format source using same language mode; do not introduce Swift 6-only syntax or semantics without an explicit migration.

Priorities, in order:

1. Correct behavior and data safety
2. Clear intent and maintainability
3. Simple design
4. Testability and explicit boundaries
5. Measured performance

Clean Code, Clean Architecture, KISS, DRY, and SOLID are decision tools, not goals by themselves. When rules conflict, choose the design that makes current behavior easiest to understand and change safely.

## 1. Clean Swift Code

### 1.1 Names Reveal Intent

- Follow Swift API Design Guidelines.
- Name types and protocols with nouns that describe roles or concepts.
- Name functions and computed properties for what they do or return.
- Use verb phrases for mutating or effectful operations: `startMonitoring()`, `saveSettings()`, `removeExpiredEntries()`.
- Use noun phrases for values: `currentApplication`, `encodedText`, `isMonitoring`.
- Name Boolean values as assertions: `isEnabled`, `hasPermission`, `shouldRestoreInput`.
- Prefer domain vocabulary over technical placeholders such as `manager`, `helper`, `utility`, `data`, `info`, or `handler`.
- Avoid abbreviations unless conventional in Swift or Apple frameworks.
- Use searchable names. Restrict single-letter names to tiny mathematical scopes or short loops.
- Include units in names when types do not express them: `debounceNanoseconds`, `maximumFileBytes`.
- Avoid type information in names. Swift's type system already communicates it.

```swift
// Unclear
func doIt(_ value: String, flag: Bool) -> String

// Clear
func encodeForLegacyApplication(_ text: String) -> String
```

### 1.2 Functions Do One Thing

- Keep each function at one level of abstraction.
- Make control flow read top-to-bottom like prose: validate, transform, persist, publish.
- Prefer early exits with `guard` over deeply nested conditionals.
- Extract a function when extraction gives a meaningful name to a concept, removes duplication of knowledge, or isolates an effect.
- Do not split linear, readable code into tiny functions merely to satisfy a line count.
- Prefer zero to two parameters. Group values only when they form a real domain concept, not to hide a long parameter list.
- Avoid Boolean mode parameters. Use separate operations or an enum when modes represent meaningful choices.
- Keep commands and queries distinct. A query should not mutate hidden state; a command should make its effects obvious.
- Avoid hidden dependencies on global state, singletons, clocks, file systems, pasteboards, or process state. Pass collaborators or values explicitly when tests or behavior need control.
- Keep side effects near system boundaries. Domain transformations should be deterministic whenever practical.

### 1.3 Types Stay Cohesive

- Give each type one primary reason to change, defined by actor or responsibility rather than method count.
- Keep related state and invariants together.
- Split a type when separate responsibilities change independently, require unrelated dependencies, or force unrelated tests.
- Do not split a cohesive type into protocol-class pairs without a real substitution or boundary need.
- Prefer composition over inheritance.
- Default classes to `final`. Permit inheritance only when substitutability is intentional, documented, and tested.
- Prefer structs and enums for values, state machines, configuration, commands, and results.
- Use classes for shared identity, lifecycle ownership, framework requirements, or coordinated mutable state.
- Make invalid states unrepresentable with enums, dedicated value types, and restricted mutation.
- Use access control deliberately. Start with `private`; widen only for a concrete caller.

### 1.4 Swift Idioms

- Prefer immutability: use `let` unless mutation is required.
- Prefer standard-library operations when they remain readable. Use an explicit loop when a chain obscures control flow or allocates unnecessarily.
- Prefer exhaustive `switch` statements for domain enums. Avoid `default` when listing cases lets compiler detect missing behavior.
- Use `if let`, `guard let`, optional chaining, and nil coalescing to model absence explicitly.
- Never force unwrap or use `try!` in production code unless an invariant makes failure impossible and nearby text explains that invariant.
- Avoid implicitly unwrapped optionals outside framework lifecycle constraints.
- Prefer typed constants over magic strings and numbers.
- Use extensions to group conformances or closely related behavior, not to hide an oversized type across many locations.
- Avoid broad convenience extensions on standard-library or framework types when semantics are project-specific.
- Preserve value semantics. Do not introduce reference sharing where copied state is expected.
- Use key paths, property wrappers, result builders, and other advanced language features only when they improve local clarity.

### 1.5 Formatting

- Formatter and linter output are authoritative for mechanical style.
- Use four-space indentation and trailing commas in multiline declarations and literals.
- Keep lines within configured limits; wrap by semantic group rather than arbitrary columns.
- Keep declarations near their use and related methods near each other.
- Order a type for reading: public state and initialization, public behavior, internal behavior, private implementation.
- Do not align assignments with spaces. Alignment creates noisy diffs.
- Remove dead code and commented-out code. Version control retains history.
- Leave touched code cleaner without expanding change scope into an unrelated refactor.

## 2. Comments

Write comments only at public boundaries. Private implementation must be self-explanatory through names, types, and structure.

Permitted:
- File-level summary describing the module's or file's purpose and responsibility.
- Class, struct, enum, protocol, and actor documentation explaining role, invariants, and threading contract.
- Public and internal methods exposed across modules or files, documenting parameters, return value, side effects, and preconditions.
- Any comment essential for a caller to use the API correctly without reading the implementation.

Forbidden:
- Comments inside private functions or private implementation details.
- `MARK` sections, TODO comments, commented-out code, closing-brace annotations, or trailing comments.
- Redundant comments that restate what the code already says.

When code needs explanation, first try extracting a well-named function or type, introducing a domain value, or adding a test. Place architecture rationale and platform workarounds in repository documentation rather than source.

## 3. Error Handling

- Model expected outcomes in return types. Use optional values for ordinary absence and typed errors for recoverable failure.
- Throw errors when callers can recover, present feedback, retry, or add context.
- Catch only when code can recover, translate to a domain error, add useful context, or establish a boundary.
- Never silently swallow failures with empty `catch` blocks or indiscriminate `try?`.
- `try?` is acceptable only when failure intentionally means absence or best-effort cleanup and that meaning is obvious.
- Fail fast for violated programmer invariants with `precondition` or `assert`, chosen according to release behavior.
- Preserve underlying errors when translating them unless exposing them would leak sensitive information.
- Keep user-facing messages separate from diagnostic details.
- Log metadata needed to diagnose failure. Never log keystrokes, clipboard contents, secrets, tokens, or private user data.
- Use empty collections instead of optional collections when "no elements" is valid.

## 4. Swift Concurrency

- Treat isolation as part of API design, not an implementation detail.
- Isolate UI and AppKit state to `@MainActor`.
- Keep expensive CPU work and blocking I/O off main actor.
- Prefer structured concurrency with `async let` and task groups. Use unstructured `Task` only when lifecycle ownership is explicit.
- Store and cancel long-lived tasks when owner stops, disappears, or starts replacement work.
- Check cancellation in loops, retries, debounce operations, and expensive transformations.
- Do not use `Task.detached` to silence actor-isolation errors.
- Make values crossing isolation boundaries `Sendable`.
- Use actors for shared mutable state that can be accessed concurrently. Do not add actors around immutable values or main-actor-only state.
- Avoid `@unchecked Sendable`. When unavoidable, document synchronization invariant and test concurrent behavior.
- Never block async code with semaphores or synchronous waits.
- Make callback isolation explicit when bridging AppKit, Core Foundation, or legacy APIs.
- Prefer checked continuations and guarantee each continuation resumes exactly once.

## 5. Architecture

Architecture protects business rules from volatile platform details while keeping feature work easy to locate.

### 5.1 Dependency Direction

Source dependencies point toward stable policy:

1. Domain and engine logic contain rules, state transitions, value types, and platform-neutral configuration.
2. Platform services adapt operating-system events and APIs into domain inputs and apply domain outputs.
3. Application coordination owns lifecycle, composition, UI state, windows, menus, and feature wiring.
4. Views render state and send user intent. They do not own persistence, system integration, or domain rules.

Rules:

- Domain code must not import UI or application frameworks.
- Platform adapters may depend on domain abstractions and values.
- Application code may compose all lower-level components.
- Lower-level components must not reference application types.
- Framework-specific objects must not cross into domain APIs. Translate them at boundaries.
- Dependency cycles are architecture defects.
- Enforce dependency direction with automated fitness tests.

### 5.2 Feature Cohesion

- Organize application behavior by user-facing capability.
- Keep views, presentation state, and feature-specific adapters close when they change together.
- Move logic into domain types when it expresses reusable policy or invariants.
- Move platform interaction behind a narrow adapter when it depends on AppKit, system permissions, files, pasteboards, hotkeys, processes, or networking.
- Avoid generic shared folders. Share code only when ownership and reason to change are clear.
- Keep composition in an application boundary. Constructors should reveal required dependencies.

### 5.3 Boundaries And Dependency Injection

- Prefer direct construction and initializer injection.
- Introduce a protocol at a genuine boundary: multiple implementations, test substitution, platform isolation, or ownership inversion.
- Let consumers define narrow protocols based on behavior they need.
- Do not create a protocol for every concrete type.
- Do not add dependency-injection frameworks when ordinary Swift initialization is sufficient.
- Pass plain Swift values across boundaries.
- Keep adapters responsible for translation, not business policy.

### 5.4 SwiftUI And AppKit

- SwiftUI views are descriptions of UI, not service containers.
- Keep `body` free of I/O, expensive transformation, mutation, and object construction with lifecycle significance.
- Own reference state once and pass it down explicitly.
- Derive presentation values from source state instead of storing duplicate state.
- Keep navigation, window, menu, and popover coordination outside leaf views.
- Wrap AppKit behavior behind focused presenters, coordinators, or representables.
- Respect view identity. Do not change structural identity merely to trigger refreshes.
- Use semantic colors, system text styles, standard controls, and accessibility labels.
- Ensure controls work with keyboard navigation, VoiceOver, increased text size, and reduced motion where applicable.

## 6. KISS And YAGNI

- Implement simplest design that satisfies current requirements safely.
- Prefer direct calls over event buses, registries, factories, or plugin systems when one caller and one implementation exist.
- Do not build extension points for hypothetical future requirements.
- Do not add configuration for values without a real need to vary.
- Avoid wrappers that rename an API without isolating policy, effects, or platform details.
- Keep straightforward workflows linear and visible.
- Optimize only after measurement identifies a relevant bottleneck.
- Complexity requires evidence: current behavior, known variation, measured performance, safety, or test isolation.

KISS does not mean placing everything in one type. A small boundary that removes platform coupling or protects an invariant can be simpler than a large function.

## 7. DRY And AHA

DRY applies to knowledge, not matching text.

- Keep each business rule, invariant, serialization key, limit, and formula authoritative in one place.
- Tolerate incidental duplication when similar code serves different actors or changes for different reasons.
- Follow Rule of Three for uncertain abstractions: observe pattern more than once before extracting it.
- Extract sooner when duplicated knowledge can create inconsistent behavior, privacy risk, or data loss.
- Prefer a little readable duplication over a shared function full of flags and branches.
- If an abstraction becomes conditional and callers use disjoint subsets, inline it, remove irrelevant branches, and discover better boundary.
- Keep test setup explicit until shared construction improves readability rather than hiding relevant state.

Before extracting shared code, ask:

1. Does behavior represent same knowledge?
2. Will callers change for same reason?
3. Is common API smaller and clearer than duplicated code?
4. Are known variations represented without Boolean flags or type checks?

## 8. SOLID In Swift

Use SOLID to improve cohesion and coupling. Reject mechanical application that adds indirection without clarity.

### 8.1 Single Responsibility

- Group behavior owned by same actor and changed for same reason.
- Separate domain transformation, persistence, UI presentation, and platform interaction when their change drivers differ.
- Do not interpret SRP as one method per type.

### 8.2 Open/Closed

- Extend stable behavior through enums, composition, strategies, or protocols when variation is known.
- Prefer editing simple code over predicting extension points.
- Avoid inheritance-based extension unless framework requires it or subtype contract is genuine.

### 8.3 Liskov Substitution

- Every conforming type must honor protocol semantics, not merely compile.
- Do not implement required operations with traps, empty behavior, or unsupported-operation errors.
- Preserve preconditions, postconditions, and invariants across substitutions.
- Test shared contracts when multiple implementations exist.

### 8.4 Interface Segregation

- Keep protocols focused on consumer needs.
- Split protocols when conformers need dummy implementations or clients depend on unused requirements.
- Prefer capability names such as `SettingsLoading` or `ClipboardWriting` over vague names such as `ServiceProtocol`.

### 8.5 Dependency Inversion

- Stable policy owns abstractions needed to invoke volatile details.
- Platform and persistence adapters implement those abstractions.
- Inject clocks, file access, system APIs, and network clients when behavior needs deterministic testing.
- Do not invert dependencies that are already stable, pure, and cheap to use directly.

## 9. Testing

- Test observable behavior through public or internal APIs. Do not expose implementation solely for tests.
- Use many fast unit tests for domain rules, focused integration tests for boundaries, and few end-to-end tests for critical workflows.
- Structure tests as Arrange, Act, Assert.
- Give tests behavior-focused names that state condition and expected result.
- Keep one behavioral reason for failure per test.
- Cover success, boundary values, malformed input, cancellation, recovery, and state transitions where relevant.
- Prefer real value types and lightweight fakes over broad mocks.
- Mock at nondeterministic or expensive boundaries, not every collaborator.
- Keep tests deterministic. Control time, files, process state, and system callbacks.
- Add a regression test before fixing a reproducible bug when feasible.
- Test concurrent code for cancellation and stale-result races.
- Test architecture rules that compiler cannot express, including forbidden imports and dependency cycles.
- Treat flaky tests as defects. Fix or quarantine with tracked reason; never normalize reruns as solution.

## 10. Privacy, Security, And Reliability

- Collect and retain minimum data required for feature.
- Process sensitive user content locally unless feature explicitly requires transmission.
- Never record raw keyboard input or clipboard payloads in logs or analytics.
- Store secrets in Keychain, not preferences, source, logs, or plain files.
- Validate file size and format before decoding imported data.
- Write persistent data atomically when partial writes could corrupt state.
- Define migration behavior for persisted models before changing schema.
- Prefer safe defaults when stored configuration is missing or invalid; surface diagnostics when fallback matters.
- Bound caches, histories, retries, and queues.
- Clean up observers, event taps, tasks, windows, temporary files, and system resources according to owner lifecycle.

## 11. Performance

- Correctness and clarity precede optimization.
- Measure with Instruments or targeted benchmarks before changing design for speed.
- Keep latency-sensitive event paths deterministic, bounded, and free from blocking I/O.
- Avoid repeated allocation, encoding, regex construction, or full-collection work in hot paths when measurement shows cost.
- Keep UI work on main actor small. Move pure expensive work away, then publish result on correct actor.
- Prefer algorithmic improvements over micro-optimizations.
- Document performance invariants only when regression would be easy and costly.

## 12. Change Discipline

- Keep each change focused and reviewable.
- Separate behavior changes from broad mechanical refactors when practical.
- Preserve public behavior unless change explicitly intends otherwise.
- Update tests and documentation with code they describe.
- Review in this order: correctness, architecture, safety/privacy, concurrency, tests, simplicity, names, style.
- Approve code that improves overall health; do not demand unrelated perfection.
- Record significant, hard-to-reverse architecture decisions with context, decision, alternatives, and consequences.

## 13. Definition Of Done

Before considering work complete:

- Behavior meets requirement and handles relevant failures.
- Names communicate intent without explanatory comments.
- Functions and types remain cohesive.
- Dependencies follow architecture direction.
- No speculative abstraction or duplicated business rule was introduced.
- Mutable state has clear owner and isolation.
- Sensitive data is not logged or exposed.
- Tests cover changed behavior and regression risk.
- Formatter, linter, build, and tests pass.
- Documentation remains accurate without links to implementation-specific files.
