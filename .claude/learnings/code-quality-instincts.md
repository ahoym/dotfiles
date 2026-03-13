# Code Quality Instincts

Fundamental practices that apply across languages and frameworks. These are the filters that should run on every line of code — during implementation, not just refactoring.

## Don't duplicate logic across modules

If a calculation exists in a utility, import it. Don't inline a copy — even if the copy is "just a few lines." Duplication means two places to update and two places for bugs to diverge.

## Single source of truth for definitions

Never define the same interface, type, constant, or enum in two files. One canonical location, re-exported where needed.

## Port intent, not implementation

When porting code from another repo, adapt to the target's structure. Don't carry over idioms that made sense in the original context but not the new one.

## Remove dead code aggressively during refactors

Refactor phases are opportunities to audit and prune. When adding new functionality, check for functions/constants the new code supersedes and remove them along with their tests. Net-negative line counts on feature PRs are a healthy signal.

- **Takeaway**: Every refactor is an audit opportunity — delete what the new code replaces.

## Reuse existing calculation functions instead of duplicating logic

When implementing new features, check if the calculation you need already exists in the codebase. Inline reimplementations diverge silently from the canonical version.

- **Takeaway**: Search for existing implementations before writing new calculation logic.

## Use named guard variables for multi-condition early returns

Instead of multiple separate `if ... return` statements, name each condition with a descriptive boolean variable and chain into a single guard. Documents what each condition protects against.

- **Takeaway**: Named guards make multi-condition returns self-documenting.

## Inline dict values when keys already describe them

Intermediate variables that duplicate dict key names add indirection without value. Inline the function call directly into the dict literal unless the variable is reused elsewhere or the key name doesn't describe the value.

- **Takeaway**: Don't create variables just to name dict values that are already named by their keys.

## Never log authentication tokens or PII

Auth tokens logged at INFO level are a security vulnerability. PII in logs creates compliance risk. Downgrade level AND remove the sensitive value. Treat log statements containing secrets or PII as security bugs.

## Generic error messages for uniqueness constraint violations

Don't reveal which field caused a uniqueness violation (e.g., "email already exists"). Generic messages like "duplicate entry" reduce enumeration attack surface.

## Avoid unnecessary wrapper methods

One-line delegation methods add indirection without value. Call dependencies directly unless the wrapper adds caching, error handling, or other real behavior. Extends to service layers: remove indirection that doesn't add validation or transformation.

## Rename parameters to reflect intent, not implementation

When a parameter name describes implementation (`clientId` for what's actually an idempotency key), rename to match semantic role (`requestId`). Misleading names cause bugs.

## Name features for what they actually do

If the implementation is a single train/test split, don't call it "walk-forward analysis." Name for current behavior, not aspirational scope.

## Add discoverability comments for cross-cutting behavior

When a global handler silently catches what domain-specific handlers previously handled, add comments pointing to the global one. Cross-cutting behavior needs breadcrumbs at the point of displacement.

## Domain isolation: keep conversion logic in the owning domain

When Service A needs data from Domain B, expose a method on Service B rather than reaching into B's repositories directly. Preserves boundaries and keeps transformation logic with the domain that understands it.

## Defer work that isn't needed yet

Don't add schema columns, endpoints, or abstractions for features that haven't been designed. It's cheaper to add later than to migrate away from the wrong one. "Do we technically need this?" is a powerful review question.

## Always include negative test cases

Happy-path-only tests are incomplete. Include not-found, invalid input, and edge case scenarios.

## Don't commit hardcoded test data in production code paths

Placeholder values (hardcoded IDs, sample UUIDs) in production code are merge hazards. Parameterize or remove with a TODO reference.

## Prefer enums over strings for fields with known value sets

When a field represents a fixed set of values, use an enum or equivalent. Makes the model self-documenting and prevents invalid values at compile time.

## Add comments explaining domain-specific constants

Constants that encode business rules (terminal status sets, cutoff values) need inline documentation explaining the "why" behind the value set.

## Update tests when API contract changes

When switching identity sources (e.g., request-param to JWT), tests must stop passing the old parameter. Stale test params are false documentation of the API surface.

## Log level demotion requires justifying where signal is preserved

When downgrading log levels, identify the alternative location where the information is still logged appropriately. Without justification, important signals disappear from production logs.