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
