# Code Quality Instincts

Fundamental practices that apply across languages and frameworks. These are the filters that should run on every line of code — during implementation, not just refactoring.

## Don't duplicate logic across modules

If a calculation exists in a utility, import it. Don't inline a copy — even if the copy is "just a few lines." Duplication means two places to update and two places for bugs to diverge.

## Single source of truth for definitions

Never define the same interface, type, constant, or enum in two files. One canonical location, re-exported where needed.

## Port intent, not implementation

When porting code from another repo, adapt to the target's structure. Don't carry over idioms that made sense in the original context but not the new one.
