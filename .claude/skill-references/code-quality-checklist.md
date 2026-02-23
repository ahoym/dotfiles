# Code Quality Self-Review Checklist

Review your implementation for these structural issues before presenting results:

## Extract when you see:
- **Methods operating on a field subset** — extract to a helper class (single responsibility)
- **Duplicated code blocks** (even with small variations) — extract to a helper method
- **Repeated test object construction** — extract to a factory function with sensible defaults
- **Files exceeding ~500 lines** — consider splitting into focused modules

## Don't extract:
- Three similar lines are fine — premature abstraction is worse than mild repetition
- Helpers used exactly once rarely justify extraction
- Test helpers that obscure what's being tested

This checklist applies to code you wrote, not pre-existing code outside your scope.
