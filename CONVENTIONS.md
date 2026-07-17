# Engineering Conventions

**Grounded in SOLID, DRY, KISS, Clean Code, and Clean Architecture — organized for a domain-driven, vertical-slice codebase.**

## TL;DR

- **Adopt a hybrid architecture**: organize code by business capability (vertical slices / feature folders), keep domain logic framework-independent per the Clean Architecture Dependency Rule, and enforce boundaries with automated fitness functions (ArchUnit / dependency-cruiser / NetArchTest) rather than folder dogma. This directly matches Jonas's SOLID+DRY+KISS, domain-slice-over-technical-layer philosophy.
- **Prioritize simplicity and change-ability over premature purity**: KISS and YAGNI outrank dogmatic DRY; follow AHA ("Avoid Hasty Abstractions") — prefer duplication over the wrong abstraction, and abstract only when the pattern is clear (Rule of Three).
- **Treat SOLID as coupling/cohesion guidance, not ceremony**: apply SRP (one actor/reason to change), OCP, LSP, ISP, and DIP pragmatically; DIP is the backbone of the Clean Architecture Dependency Rule (inner layers define interfaces, outer layers implement them).

## Key Findings

- Clean Architecture, Hexagonal (Ports & Adapters), and Onion are the same idea with different labels: business logic at the center, dependencies point inward, framework independence. Vertical Slice Architecture (VSA) is **not** a competitor — it addresses cohesion (group by feature) while Clean addresses coupling (isolate the domain). They compose.
- The most respected 2023–2026 thought leadership (Jimmy Bogard, Derek Comartin, Milan Jovanović, Anton Martyniuk) converges on a hybrid: keep a framework-independent Domain (and often Infrastructure) layer, but combine the Application + Presentation layers into vertical slices organized by feature/use case.
- The DRY-vs-abstraction tension is settled by AHA/WET: Sandi Metz's "duplication is far cheaper than the wrong abstraction" is the governing heuristic; DRY applies strongest to knowledge/business rules, weakest to incidental similarity.
- SOLID remains useful but is widely mis-taught. SRP is about "one actor/reason to change," not "one method per class." Critics (Dan North's CUPID) rightly warn that dogmatic SOLID produces unintelligible, over-fragmented code — the antidote is to reason in terms of coupling and cohesion.
- Modern conventions increasingly enforce architecture in CI (fitness functions), use Conventional Commits, small PRs (200–400 lines), the test pyramid with AAA / `Method_Scenario_Expectation` naming, and documentation-as-code via ADRs.

## Details

Everything below is written to drop directly into a team `CONVENTIONS.md`. Rules are imperative and actionable; each section notes source credibility.

---

### 1. Clean Code Conventions

*Source: Robert C. Martin, "Clean Code: A Handbook of Agile Software Craftsmanship" (2008) and his Clean Coders video series — the canonical, widely-cited primary source. Naming rules derive from Tim Ottinger's Rules for Variable and Class Naming.*

#### 1.1 Naming

- **Use intention-revealing names.** If a name needs a comment to explain it, the name has failed. `int d;` → `int elapsedTimeInDays;`
- **Function names are verbs; class names are nouns.** Functions *do* things.
- **Inverse Scope Law of names** (Uncle Bob): the *larger* a function's scope, the *shorter* its name (`push`, `read`, `open`); the *smaller/more local* the scope, the *longer and more descriptive* the name (`parseColumnHeaderFromRow`). The same applies to classes — public classes get one-word names, private helpers get longer ones.
- **Avoid disinformation and noise words.** No `Product`, `ProductData`, `ProductInfo` distinctions with no real difference; don't append `List` unless it is one; use plurals (`animals`) instead.
- **Use pronounceable, searchable names.** Constants over magic numbers. No single letters except tiny local scopes (loop counters, one-line closures).
- **Add context via namespaces/classes, not prefixes**; prefix only as a last resort. Don't Hungarian-prefix everything (`GSDAccountAddress`).

#### 1.2 Function Design

- **Functions should be small — then smaller.** Target well under ~20 lines; blocks inside `if`/`else`/`while` should be one line (usually a call to a well-named function).
- **Do one thing, at one level of abstraction.** Code reads top-to-bottom like prose (the Step-Down Rule).
- **Minimize arguments.** Ideal is 0 (niladic), then 1 (monadic), then 2. Avoid 3+; more than three needs very special justification. Prefer wrapping related args into an object.
- **No flag/boolean arguments** — they announce the function does more than one thing. Split into two functions.
- **No side effects.** A function named `checkPassword` must not also initialize the session. Side effects are lies.
- **Prefer no output arguments.** `report.appendFooter()` not `appendFooter(report)`.
- **Command/Query Separation**: a function either does something or answers something, never both.

#### 1.3 Comments Philosophy

- **The best comment is the one you didn't need to write** because the code is expressive. "Don't comment bad code — rewrite it."
- **Team rule — comment surface, not internals:** private/internal functions and implementation logic must be self-documenting through naming and structure alone — **no inline or internal comments**. If a private function needs a comment to be understood, extract and rename instead of explaining. **Comments are reserved for public surface only: public classes, public files (headers), and public methods/functions** — documenting contract, intent, and any non-obvious constraint a caller must know, not restating what the body does line by line.
- **Good comments** (public-surface only, per the rule above): legal/copyright headers, public API/contract documentation (params, return value, invariants, side effects a caller must know), explanation of *why* a public method exists or a non-obvious design decision, warnings of consequences, `TODO`s.
- **Bad comments**: any comment inside a private/internal function body, redundant restatements, closing-brace comments, commented-out code (delete it — version control remembers), mandated Javadoc boilerplate on trivial methods, noise.

#### 1.4 Error Handling

*Source: Clean Code Ch.7 + modern practitioners (Vladimir Khorikov / Enterprise Craftsmanship; Microsoft .NET guidance).*

- **Prefer exceptions to returned error codes** — return codes clutter the caller and get ignored.
- **Don't let error handling obscure logic.** Extract `try` bodies into their own functions. "Error handling is important, but if it obscures logic, it's wrong."
- **Fail fast and visibly** for unrecoverable/programmer errors; don't swallow exceptions (catch-log-return-null hides failure and pollutes telemetry).
- **Exceptions vs. Result types (modern nuance)**: use a `Result<T>` for *expected* domain/validation failures you know how to handle (catch at the lowest level, convert to Result); reserve **exceptions** for genuinely exceptional, unrecoverable conditions and let them propagate to a top-level handler. Vladimir Khorikov (Enterprise Craftsmanship, a well-regarded DDD/.NET source): "Whenever the failure is something you expect and know how to deal with — catch it at the lowest level possible and convert into a Result instance. If you don't know how to deal with it — let it propagate... Don't catch exceptions you don't know what to do about."
- **Never return** `null` **where a collection is expected** — return an empty collection. Avoid passing `null`.

#### 1.5 Formatting & Structure

- **Vertical density**: related code stays together; separate concepts with blank lines. Declare variables close to their use. Dependent/similar functions stay near each other.
- **Keep lines short**; don't force horizontal scrolling ("it's rude to make your readers scroll right"). Don't horizontally align assignments.
- **Follow one consistent team style**; automate it with a formatter/linter so it's never a review topic.
- **Boy Scout Rule**: leave the code cleaner than you found it.

#### 1.6 Code Smells to Avoid

*Source: Martin Fowler & Kent Beck, "Refactoring" (1999, 2nd ed. 2018) — the definitive catalog. Fowler: "a code smell is a surface indication that usually corresponds to a deeper problem."*

- **Bloaters**: Long Method, Large Class, Long Parameter List (>3–4), Primitive Obsession, Data Clumps.
- **OO abusers**: Switch statements begging for polymorphism, Refused Bequest (subclass ignores inherited members).
- **Change preventers**: Divergent Change (one class changed for many reasons — SRP violation), Shotgun Surgery (one change touches many classes).
- **Couplers**: Feature Envy (a method more interested in another class's data), Message Chains, Middle Man, Inappropriate Intimacy.
- **Dispensables**: Duplicated Code, Dead Code, Speculative Generality (abstractions "we might need" — Fowler explicitly lists this as a smell), Comments used to mask bad code.
- Modern note: with AI-generated code, refactoring discipline matters more, not less — Kent Beck's "Tidy First?" (2023) recommends small, separate "tidying" commits distinct from behavior changes.

---

### 2. KISS — Keep It Simple

*Source: broad practitioner consensus (KISS/YAGNI literature), Donald Knuth ("premature optimization is the root of all evil"), and pairing with YAGNI from Extreme Programming.*

- **Default to the simplest thing that works.** Simplicity is a discipline that takes *more* effort than over-engineering, which feels "thorough" and "future-proof."
- **Apply YAGNI ("You Aren't Gonna Need It").** Build only what current requirements demand. If a single logger/payment method is needed now, do not build a provider abstraction for hypothetical future ones — refactor when the second case actually arrives.
- **Avoid premature optimization** and "premature flexibilization" (adding config/abstraction layers for imagined future needs).
- **KISS outranks DRY when they conflict.** A little duplication beats a confusing abstraction.

**KISS violations vs. KISS-compliant (concrete):**


| KISS violation (over-engineered)                                                 | KISS-compliant                                           |
| -------------------------------------------------------------------------------- | -------------------------------------------------------- |
| An abstract event bus for a call that could be a direct function call            | Call the function directly                               |
| A plugin architecture for code with exactly one implementation                   | Concrete implementation; add the seam when a 2nd appears |
| `OrderService → OrderRepository → OrderDao → EntityManager` all for a `findById` | One layer that does the query                            |
| A one-line regex doing five transformations; a six-step array chain              | A readable loop / named steps                            |
| Making a workflow configurable via a DSL before anyone asked                     | Hard-code it until configuration is a real requirement   |


- **Symptoms you've over-engineered** (mirror bad-code symptoms): refactoring increased development time; you must duplicate code because the "flexible" system can't accommodate the real case; relationships between components are a maze.

---

### 3. DRY — Don't Repeat Yourself (and its limits)

*Sources: Andy Hunt & Dave Thomas, "The Pragmatic Programmer" (DRY origin); Sandi Metz, "The Wrong Abstraction" (2016) — extremely widely cited; Kent C. Dodds, "AHA Programming" (2020). All highly regarded primary/practitioner sources.*

- **DRY is about knowledge, not text.** "Every piece of knowledge must have a single, unambiguous, authoritative representation." It applies most strongly to **business rules, validation logic, and formulas** — a rule that changes must change in exactly one place.
- **DRY applies weakly to incidental duplication** — two snippets that look alike today but change for different reasons are *not* true duplication.

**The DRY-vs-premature-abstraction tension (the key nuance):**

- **Rule of Three (WET — "Write Everything Twice"):** tolerate duplication until you've written it a third time; then you understand the pattern well enough to abstract. "You can ask 'Haven't I written this before?' twice, but never three times."
- **AHA — "Avoid Hasty Abstractions":** the acronym was coined by Cher Scarlett and popularized by Kent C. Dodds in "AHA Programming" (kentcdodds.com, June 22, 2020). Dodds's rules: *"optimize for change first"* and stay *"fine with code duplication until you feel pretty confident that you know the use cases"* — wait until "the commonalities will scream at you for abstraction." Thoughtful abstractions are planned, not impulsive.
- **The Wrong Abstraction (Sandi Metz, sandimetz.com, Jan 20 2016, from her RailsConf 2014 talk "All the Little Things"):** *"duplication is far cheaper than the wrong abstraction"* and *"prefer duplication over the wrong abstraction."* The failure mode: someone de-duplicates, then later requirements force parameters and conditionals into the shared code until it becomes an unmaintainable mess of `if` branches. **Sunk-cost trap:** *"When dealing with the wrong abstraction, the fastest way forward is back"* — re-inline the code into each caller, delete the branches each caller doesn't use, then re-abstract from what you learn.

**When is duplication acceptable? Judge by:**

1. **Do these really change together, for the same reason and same actor?** If no → keep them separate.
2. **Is it knowledge duplication (a business rule) or incidental similarity?** Knowledge → DRY it. Incidental → leave it.
3. **Do you actually understand the pattern yet?** If uncertain → duplicate and wait.
4. **How discoverable/dangerous is the duplication?** Silent, undiscoverable duplication of a rule is the dangerous kind — tag it (`// DUPE:`) if you defer it.

- Utility functions with narrow, clear scope (parsing, formatting, validation helpers) are safe to DRY immediately. Test code should lean toward AHA too — a little duplication for readability beats deeply nested `describe`/`beforeEach` sharing.

---

### 4. SOLID — Modern Practical Guidance

*Sources: Robert C. Martin (origin; "Clean Architecture" 2017; cleancoder blog); Barbara Liskov & Jeannette Wing (LSP, 1994); Baeldung, reflectoring.io, Stackify. Balanced against critiques: Dan North's "CUPID" and Derek Comartin's "SOLID? Nope, just Coupling and Cohesion."*

**Framing rule: SOLID is a means to low coupling and high cohesion, not an end. If applying a principle makes the code harder to understand, stop.**

#### 4.1 SRP — Single Responsibility Principle

- **Definition (current, precise): "A module should be responsible to one, and only one, actor."** It is *not* "a class does one thing / has one method." The word "reason" means "a person or group (actor) who requests changes."
- **Rule:** group things that change for the same reason/actor; separate things that change for different reasons. Report *content* and report *formatting* are different actors → different modules.
- **Don't over-fragment.** Treating every individual business rule as its own class replaces cohesion with fragmentation. Grady Booch's guideline (~3–5 responsibilities per class) is a saner cohesion target than "one."

#### 4.2 OCP — Open/Closed Principle

- **Definition:** software entities should be open for extension, closed for modification — add new behavior by *adding* code, not editing stable, tested code.
- **Practical:** favor polymorphism/strategy over growing `if/else`/`switch` chains on a type. Define a `StorageProvider` interface and register new providers rather than editing a client's `if (type == "cloud")`.
- **Modern caveat:** OCP is easily over-applied via inheritance. With version control and refactoring tools, "just change the code" (and bump the version) is often simpler than pre-building extension points. Apply OCP where variation is *known and recurring*, not speculatively.

#### 4.3 LSP — Liskov Substitution Principle

- **Definition (behavioral subtyping):** subtypes must be substitutable for their base type without breaking correctness. Barbara Liskov: *"If for each object o1 of type S there is an object o2 of type T such that for all programs P defined in terms of T, the behavior of P is unchanged when o1 is substituted for o2, then S is a subtype of T."*
- **Contract rules:** in an override, **preconditions cannot be strengthened**, **postconditions cannot be weakened**, **invariants must be preserved**, and no **new exception types** may be thrown that the base didn't declare.
- **Classic violation — Square extends Rectangle:** a `Square` that couples its width/height setters breaks client code that sets width and height independently and asserts `area == w*h`. Fix: make `Rectangle` and `Square` siblings under a `Shape` abstraction; the false "is-a" was the bug.

```csharp
// ❌ Square couples the setters → breaks a client that sets W and H independently
class Square : Rectangle {
    public override int Width  { set { base.Width = base.Height = value; } }
    public override int Height { set { base.Width = base.Height = value; } }
}
// ✅ Siblings under a shared abstraction
abstract class Shape { public abstract int Area(); }
class Rectangle : Shape { public int Width; public int Height; public override int Area() => Width * Height; }
class Square    : Shape { public int Side;                 public override int Area() => Side * Side; }

```

- **Red-flag smells:** an override that throws `NotImplementedException`/`UnsupportedOperationException`, an empty override, or docs saying "don't call this method on this subtype."
- **Rules:** (1) ensure subtypes are fully substitutable — no `if (x is Square)` special-casing in clients; (2) never override to throw "not supported" — the hierarchy is wrong; (3) when behavioral "is-a" fails, **prefer composition over inheritance**; (4) treat any LSP violation as a signal to rethink the hierarchy, and document base-class contracts with tests (compilers can't enforce them).

#### 4.4 ISP — Interface Segregation Principle

- **Definition (Robert C. Martin, "The Interface Segregation Principle," C++ Report 1996; restated in *Agile Software Development: PPP*, 2002):** *"Clients should not be forced to depend upon interfaces [methods] that they do not use."* / *"Many client-specific interfaces are better than one general-purpose interface."*
- **Rule:** split "fat" interfaces into small **role interfaces** named for a capability (`IReporter`), not a class. A class composes several role interfaces.
- **Violation/fix:** a fat `CoffeeMachine { brewFilterCoffee(); brewEspresso(); }` forces an espresso-only machine to `throw UnsupportedOperationException` (which is *also* an LSP violation). Fix: split into `FilterCoffeeMachine` and `EspressoCoffeeMachine`; a machine that does both implements both.
- **Smells:** implementors forced to stub/throw/return null on unused methods; needing to pass `null`/dummy args; huge test setups mocking many unused dependencies.
- **Let the consumer define the interface it needs** — "senders own the interfaces that receivers implement."

#### 4.5 DIP — Dependency Inversion Principle (the architectural backbone)

- **Definition:** high-level policy must not depend on low-level detail; both depend on abstractions. Abstractions must not depend on details; details depend on abstractions.
- **This is the Clean Architecture Dependency Rule.** At runtime, business rules call the database; at *compile time*, the database package depends on (implements) an interface **owned by the business-rules package**. Uncle Bob ("A Little Architecture," cleancoder.com, 2016): *"You invert the dependency. You have the database depend upon the business rules... The source code of the high level policies should not mention the source code of the lower level policies."*
- **ISP + DIP together (from the same dialogue):** each use case defines its own narrow gateway/port interface for just the data access it needs; infrastructure implements it. *"We have the business rules create interfaces for only what they need... Each business rule defines an interface for just the data access facility that it needs."* — "senders own the interfaces receivers implement."
- **Practical:** define `IUserRepository` in the domain/application; implement `PrismaUserRepository`/`EfUserRepository` in infrastructure; inject the concrete via DI. You rarely need a DI *framework* — constructor injection by hand is enough.

**Anti-dogma note for the team:** Dan North calls out that mechanically applied SOLID can yield "unintelligible" code (dozens of tiny interfaces/classes to read one feature). If you find yourself there, re-anchor on **coupling and cohesion** (Comartin) or the **CUPID** properties (Composable, Unix-philosophy, Predictable, Idiomatic, Domain-based). SOLID is a guideline, not a certification exam.

---

### 5. Clean Architecture + Vertical Slices (the core of Jonas's philosophy)

*Sources: Robert C. Martin, "The Clean Architecture" (2012 blog) & book (2017); Alistair Cockburn (Hexagonal/Ports & Adapters, 2005); Jimmy Bogard, "Vertical Slice Architecture" (2018); Derek Comartin (CodeOpinion, 2024); Milan Jovanović & Anton Martyniuk (2024). Primary authors plus the most-cited practitioner blogs.*

#### 5.1 The Dependency Rule (non-negotiable core)

- **Source-code dependencies point only inward.** Nothing in an inner circle may name anything in an outer circle — not a class, variable, function, or data format generated by an outer framework.
- **Layers (schematic, add more if needed):**
  1. **Entities** — enterprise-wide business objects and invariants (innermost, most stable).
  2. **Use Cases** — application-specific business rules orchestrating entities.
  3. **Interface Adapters** — controllers, presenters, gateways; translate between inner models and the outside world.
  4. **Frameworks & Drivers** — web, DB, UI, messaging (outermost, most volatile; "details").
- **Cross boundaries with DIP:** when an inner layer must trigger an outer one, define an interface (output port) in the inner layer and implement it outside. Pass simple DTOs/structs across boundaries, never framework-shaped objects.
- **Payoff:** domain is testable without UI/DB; frameworks and databases become swappable "details."

#### 5.2 Clean ≈ Hexagonal ≈ Onion

These are cousins, not competitors — same principles (dependency inversion, domain at center, framework independence), different vocabulary. Pick the label your team likes; most teams run a hybrid. Choose Hexagonal to emphasize driving/driven ports; Onion for domain-centric services; Clean for explicit use cases.

#### 5.3 Vertical Slice Architecture (VSA) — the cohesion axis

Jimmy Bogard (originator, jimmybogard.com): *"Instead of coupling across a layer, we couple vertically along a slice. Minimize coupling between slices, and maximize coupling in a slice. With this approach, most abstractions melt away, and we don't need any kind of 'shared' layer abstractions like repositories, services, controllers."*

- Organize code by **feature/use case**, not technical layer. A slice contains everything for one request — endpoint, validation, business logic, data access — in one folder.
- VSA optimizes for the **axis of change**: adding a feature adds code in one place instead of editing controllers + services + repositories folders. As Milan Jovanović notes, layered architecture's cost is that "you will have many abstractions between individual layers... more abstractions mean increased complexity," whereas in VSA "all the files for a single use case are grouped inside one folder."
- Each slice may choose its own internal complexity: a CRUD slice can be a simple transaction script; a rich-domain slice can use full DDD/ports-and-adapters. Start simple, refactor toward richer patterns when a slice's business logic grows (this requires a team that can spot code smells).
- **Clarify the common misreadings** (Bogard never said these): "minimize coupling between slices" ≠ "zero shared code"; VSA does not require MediatR; VSA is not just "Clean Architecture with folders renamed."

#### 5.4 Reconciling Clean Architecture WITH Vertical Slices (recommended default)

The two are orthogonal — Clean governs *coupling* (isolate the domain), VSA governs *cohesion* (group by capability). Comartin: "Vertical Slices... does not emphasize coupling at a technical level like Clean Architecture... They aren't mutually exclusive." The recommended hybrid (per Anton Martyniuk and Milan Jovanović):

- **Keep a framework-independent Domain layer** (entities, value objects, aggregates, domain rules) at the center. DDD encapsulation of business rules inside entities keeps slices thin.
- **Keep an Infrastructure layer** for shared external integrations (DB, cache, auth, messaging) to avoid duplicating them across slices — or, for simple apps, use the ORM directly inside a slice (be pragmatic).
- **Merge Application + Presentation into vertical slices** organized by feature/domain area. This is where you get fast navigation and low ceremony.
- **Result — "Screaming Architecture" (Uncle Bob):** the folder structure should shout the *domain* ("this is a shipping system"), not the framework. Group by business capability/aggregate, not by `Controllers/`, `Services/`, `Repositories/`.

**Recommended folder shape (illustrative):**

```
src/
  Domain/                    # framework-independent: entities, value objects, domain events
    Shipping/
    Billing/
  Infrastructure/            # shared adapters: persistence, messaging, auth (implements domain ports)
  Features/                  # vertical slices = Application + Presentation, by capability
    Shipping/
      CreateShipment.cs      # command + validator + handler + endpoint, together
      DispatchShipment.cs
      GetShipmentById.cs
    Billing/
      IssueInvoice.cs

```

- Simple slices may talk to the ORM directly; complex slices push logic into rich domain entities and hide IO behind ports. The domain never depends on `Features/` or `Infrastructure/`.

**When to skip the ceremony (KISS check):** for a CRUD-heavy or small app, plain VSA (no separate Domain/Infrastructure projects) is often the right call — don't add Clean Architecture's layers/indirection to solve problems you don't have. Reserve the full hybrid for complex domains with substantial business logic. A project template is a starting point, not a prescription.

---

### 6. General Team Conventions (for CONVENTIONS.md / CONTRIBUTING.md)

#### 6.1 File / Folder / Module Naming

- **Organize by business capability, not technical type** (see §5.4). Folders should name domain concepts.
- **Name interfaces by role/capability** (`IReporter`, `IShipmentRepository`), name classes by concrete responsibility.
- **File size is a style you impose, not a function of project size** (Uncle Bob): keep most files small; a file/class that grows is a smell.
- **One consistent casing/convention per language**, enforced by linter/formatter config committed to the repo.

#### 6.2 Module Boundaries & Dependency Direction

- **Dependencies point inward** toward the domain (the Dependency Rule). Domain logic must not import framework packages (Express, Spring, NestJS, EF, etc.).
- **Modules expose a public API; other modules may not reach into internals.** If module A needs module B, go through B's public surface (Shopify's Packwerk and Spring Modulith enforce exactly this).
- **No circular dependencies** — treat cycles as architectural defects.
- **Between slices/modules, prefer domain events or thin facades** over direct synchronous coupling when features are meant to be independent.

#### 6.3 Enforce Architecture with Fitness Functions (don't rely on good intentions)

*Source: Neal Ford, Rebecca Parsons, Patrick Kua, "Building Evolutionary Architectures" (2017; 2nd ed. 2023); tooling: ArchUnit (Java), ArchUnitTS / dependency-cruiser / eslint-plugin-import (TS/JS), ArchUnitPython, NetArchTest (.NET).*

- Encode layering, dependency direction, naming, and no-cycle rules as **automated tests in CI**. A rule that only lives in a diagram will erode.
- Example rules: "Domain must not depend on Infrastructure"; "no package cycles"; "controllers must not reference repositories directly"; "files must not exceed N lines." These work in feature-based (package-by-feature) codebases too, via naming/annotation predicates.
- Baseline legacy violations (ArchUnit `freeze`) so rules block *new* violations without demanding a big-bang cleanup.

#### 6.4 Testing Conventions

*Sources: Mike Cohn (test pyramid); Microsoft .NET testing guidance; Steve Smith (Ardalis); widely-used JS testing guides.*

- **Test pyramid**: many fast unit tests, fewer integration tests, fewest slow E2E tests. Domain logic isolated by Clean Architecture is unit-testable without DB/UI.
- **Structure every test as Arrange-Act-Assert (AAA)** (or Given-When-Then for BDD). Small Arrange, single Act, focused Assert.
- **Name tests descriptively**: `MethodName_Scenario_ExpectedBehavior` (e.g., `GetDiscountedPrice_OnTuesday_ReturnsHalfPrice`) or `Given_..._When_..._Then_...`. A vague `TestCalculate()` is banned.
- **One logical assertion/behavior per test.** No loops or conditionals in tests (they hide bugs and branching).
- **Test behavior, not implementation.** Don't test private methods directly — test through the public API. Use dependency injection + stubs/mocks to isolate; don't mock everything; use realistic data.
- **FIRST**: Fast, Independent, Repeatable, Self-validating, Timely. Aim for meaningful coverage on business logic and critical paths — don't chase 100% on trivial one-liners.
- **Apply AHA to tests**: a small, mindful "Test Object Factory" helper beats both zero abstraction and over-DRY nested setups.

#### 6.5 Git Commit Conventions

*Source: Conventional Commits v1.0.0 (based on the Angular convention) — the de facto industry standard; enables automated changelogs & SemVer.*

- **Format:** `<type>[optional scope]: <description>`, blank line, optional body, blank line, optional footer.
- **Core types:** `feat` (→ MINOR), `fix` (→ PATCH), plus `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.
- **Breaking changes:** append `!` (`feat!:`) and/or a `BREAKING CHANGE:` footer (→ MAJOR). `BREAKING CHANGE` must be uppercase.
- **Description**: imperative mood, lower-case, no trailing period, one focused summary line.
- **Branch naming (optional, "Conventional Branch"):** `feature/`, `bugfix/`, `hotfix/`, `release/`, `chore/`; lowercase, hyphen-separated, may include ticket ID (`feature/T-123-new-login`).

#### 6.6 Code Review Norms

*Source: Google's Engineering Practices ("eng-practices," CC-BY 3.0) — the most widely-adopted public standard; corroborated by the SmartBear/Cisco peer-review study.*

- **The standard:** approve a change once it *definitely improves overall code health*, even if not perfect. Seek continuous improvement, not perfection; don't block for days over nits.
- **Keep PRs small.** The SmartBear study of a Cisco Systems team (10 months, ~2,500 reviews, "Best Practices for Peer Code Review") found developers should review **no more than 200–400 lines of code at a time**: a 200–400 LOC review over 60–90 minutes yields ~70–90% defect discovery, and defect-detection ability "starts to fall above 300 lines, with a significant tailing off above 500 LOC." Decompose large work; consider a refactor-only PR first.
- **Reviewers check, in order:** design first (should this code exist here?), then functionality, complexity, tests, naming, comments, style, consistency, documentation. Don't rush to nitpick variable names before assessing design.
- **Prefix comment severity** to remove ambiguity: `Nit:` (minor/optional), `Optional:`, `FYI:` vs. blocking requests.
- **Be courteous; comment on the code, not the person.** Give positive reinforcement, not just criticism.
- **Speed:** respond within one business day. The style guide is the authority for style disputes; if a rule exists, follow it; escalate stuck disagreements to the tech lead rather than let a PR rot.
- **CODEOWNERS**: critical code (auth, billing, personal data) requires two independent approvals; other code, one.

#### 6.7 Documentation-as-Code & ADRs

*Sources: Michael Nygard, "Documenting Architecture Decisions" (2011); Martin Fowler's bliki; AWS/Azure Well-Architected guidance.*

- **Keep docs in the repo**, versioned with the code, in Markdown. For EasyKey, architecture decisions live in this file under **Applied in EasyKey** (and the project tree in `README.md`) rather than a separate `docs/adr/` tree.
- When a standalone ADR is warranted elsewhere: Title, Status, Context, Decision, Consequences (Nygard). Keep it to ~one page ("inverted pyramid" — most important first).
- **Status lifecycle:** Proposed → Accepted → Deprecated/Superseded. Accepted decisions should not be silently rewritten; supersede and cross-link.
- **Write a decision note only for architecturally significant choices** (structure, dependencies, key quality attributes, hard-to-reverse choices). Always include the *why* and the alternatives considered.
- **Tests and docs ship in the same PR as the code they describe.** READMEs/reference docs must be updated when a change affects how users build, test, or interact with the code.

## Applied in EasyKey

This repository follows the hybrid in §5.4:

| Concern | Location |
| --- | --- |
| Domain (no AppKit / SwiftUI / Combine) | `EasyEngineCore/` soft-grouped: `Engine/`, `Settings/`, `Macros/`, `SmartSwitch/`, `Converter/`, `Diagnostics/` |
| Shared logging | `EasyEngineCore/Diagnostics/AppLog` (os.Logger; never logs keystroke content) |
| Settings persistence | `EasyEngineCore/Settings/SettingsRepository` |
| Settings UI observation | `EasyKeyApp/Settings/ObservableSettingsStore` |
| Infrastructure (keyboard, synthesis, compatibility) | `EasyKeyKit/` (`Keyboard/` for event-tap pipeline) |
| Vertical slices (UI features) | `EasyKeyApp/Features/` |
| App shell / coordination | `EasyKeyApp/Coordination/` (includes Show Logs via `LogExporter`) |
| Dependency Rule fitness | `EasyKeyTests/ArchitectureFitnessTests` |

That layout is the accepted architecture for this repo (Clean Architecture dependency rule + vertical feature slices). See also the project tree in `README.md`.

## Recommendations

**Stage 1 — Adopt the foundation now (low cost, high value):**

1. Keep this document as `CONVENTIONS.md`; add Conventional Commits + a formatter/linter in CI when available (highest ROI, zero controversy).
2. Enforce small PRs (200–400 lines) and the Google review standard. Add `Nit:`/`Optional:` prefixes to review vocabulary.
3. Record significant architecture changes in **Applied in EasyKey** (this file) and keep `README.md`’s project structure in sync — no separate `docs/` tree.

**Stage 2 — Establish the architecture (per new module / next refactor):** 4. Default to the hybrid in §5.4 (already applied in EasyKey — see “Applied in EasyKey” above). For genuinely simple/CRUD services elsewhere, use plain VSA and skip the extra layers (KISS). 5. Keep architecture fitness functions in CI; EasyKey encodes the Dependency Rule in `ArchitectureFitnessTests` (source import scan). Extend rules as boundaries grow. 6. Set the test pyramid + AAA + `Method_Scenario_Expectation` naming as the testing standard.

**Stage 3 — Sustain and calibrate:** 7. Run the DRY/AHA discipline in review: challenge new abstractions ("do these truly change together?") and challenge duplication of *business rules*. Prefer duplication over a speculative abstraction. 8. Quarterly, review whether SOLID application is helping or producing fragmentation; if reviewers report "unintelligible" over-abstracted code, re-anchor on coupling/cohesion.

**Thresholds that change the guidance:**

- **Slice business logic growing / repeated across slices** → introduce a richer domain model or extract to the Domain layer (the Rule of Three applies).
- **PRs routinely >400 lines** → decompose work; it's a planning smell.
- **Same knowledge/rule duplicated in 3+ places** → now abstract (Rule of Three met).
- **Swapping DB/framework is being seriously considered** → the Dependency Rule's payoff is now concrete; ensure ports/adapters are clean.
- **Team is junior-heavy** → lean more prescriptive (Clean Architecture's explicit layers give guardrails); VSA's freedom needs senior judgment to avoid slices that "do too much."

## Caveats

- **Much of the vertical-slice/Clean-Architecture literature is .NET-centric** (Bogard, Comartin, Jovanović, Martyniuk) and often assumes MediatR/CQRS. The *principles* are language-agnostic; the specific libraries are not requirements. Adapt idioms to your stack.
- **"Best practice" here reflects strong practitioner consensus, not empirical proof.** Some claims (e.g., exact function/line thresholds, "one method per class") are stylistic; treat numeric limits as defaults, not laws. The 200–400-line PR figure is supported by the SmartBear/Cisco study; the ~20-line function figure is Uncle Bob's stylistic guidance.
- **SOLID is contested.** Respected engineers (Dan North, Derek Comartin) argue it is vague and over-applied; others (NDepend) defend it. This document takes the pragmatic middle: use SOLID as coupling/cohesion guidance, abandon it when it produces fragmentation.
- **The DRY/AHA debate is genuinely unsettled at the margins.** A minority (e.g., Jason Swett) argue "the wrong abstraction" is really just "badly de-duplicated code" and that duplication is usually more expensive. The safe rule stands: don't abstract until you understand the pattern.
- **Fitness-function tooling maturity varies by language** — ArchUnit (Java) is most mature; TypeScript/Python/.NET ports are newer. Validate the tool fits your stack before mandating it in CI.
- **Screaming/vertical-slice organization assumes the team can recognize code smells and refactor** — Bogard himself flags this as a prerequisite. Without that discipline, slices degrade into procedural sprawl.

