Java code quality: imports, TODO cleanup, method naming after refactors.
- **Keywords:** fully-qualified types, imports, TODO, dead code, method naming, refactor
- **Related:** ~/.claude/learnings/code-quality-instincts.md

---

### Remove fully-qualified type prefixes in source files when imports exist

Use short type names with imports. Fully-qualified inline types (e.g., `java.util.List<String>` in a method body) are only appropriate when resolving a naming conflict between two imported types. When an import already exists, the inline prefix is redundant noise.

### Remove TODO comments or dead code before merging

Resolve TODOs before merge. If the work genuinely can't be done in the same MR, open a follow-up ticket and reference it — speculative or orphaned comments in production code add confusion without committing to action.

### Method names must reflect actual behaviour after refactor

When a hardcoded value becomes a parameter, the method name must be updated to match. Example: `fromNowToLast7days` becomes `fromNowToLastNDays` once the 7 is parameterised. Stale names are misinformation — they cause callers to make wrong assumptions about what the method does.
