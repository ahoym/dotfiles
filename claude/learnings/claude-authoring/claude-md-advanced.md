Advanced CLAUDE.md patterns: signpost lazy-loading, modular refactoring, conflict resolution documentation, and the solatis two-file pattern for context budgeting.
- **Keywords:** CLAUDE.md, signpost, lazy load, modular includes, refactor, conflict resolution, solatis, token budget, context budgeting
- **Related:** none

---

## Signpost Pattern: Non-`@` Lazy-Loaded References

File paths listed in CLAUDE.md **without** the `@` prefix are not eagerly inlined — they're plain text. But proactive agents notice these paths and read them on demand when the topic becomes relevant. This creates a lightweight lazy-loading mechanism.

**Format:**
```markdown
## Lazy-loaded references (read when relevant)

.claude/guidelines/deployment.md - Production deployment checklist
docs/architecture/auth-flow.md - Authentication sequence and token lifecycle
```

**Behavior contrast:**
- `@path` → eagerly inlined, always costs tokens
- `path` (no `@`) → visible as text, read by agent judgment when relevant

**When to use signposts over `@`:** Context that's useful but not universally needed — domain-specific guidelines, deep-dive references, or situational checklists. Reserve `@` for context every session needs.

**Validation method:** Add a unique marker string to the signposted file, start a fresh session, and check whether the agent (a) ignores it, (b) reads it proactively via a Read tool call, or (c) reports the marker without a Read call (indicating eager inlining — a failure). Success = (b).

## Refactor Monolithic CLAUDE.md into Modular Guideline Includes

A monolithic CLAUDE.md (130+ lines) can be refactored into modular files under `.claude/guidelines/` using `@` includes. The root file shrinks to a navigational hub (~8 lines of `@` references). Refactoring into modules creates a natural affordance for content expansion — sections that felt too bulky for a monolithic file grow organically when they have their own file. Expect new content to emerge during the extraction, not just a pure move.

## Document Conflict Resolution Strategy Alongside Structural Changes

When introducing structural changes that will cause merge conflicts (e.g., switching from inline content to `@` includes), document the conflict resolution strategy in the same PR. Forward-looking documentation prevents confusion when conflicts inevitably arise. Example: "check inline version for NEW additions not yet in modular files, incorporate into the appropriate module, resolve main file to keep `@` includes."

## Solatis Two-File Pattern for Context Budgeting

Community pattern (solatis/claude-config) using strict token budgets per documentation layer:

| Layer | Budget | Content |
|-------|--------|---------|
| CLAUDE.md | ~200 tokens | Pure tabular index: `\| File \| What \| When to read \|`. No prose. |
| README.md | ~500 tokens | "Invisible knowledge" — architecture decisions, invariants, tradeoffs that can't be learned from source |
| Function docs | ~100 tokens | One-line summary + "use when..." trigger |
| Module docs | ~150 tokens | Top-of-file docstring: what + why it's separate |

**Enforcement**: technical-writer and quality-reviewer sub-agents run in a planner pipeline. Content test: "Could a developer learn this by reading source?" If yes, delete.

**Comparison with signpost pattern**: Solatis budgets the *writing* (caps on doc size). The signpost/lazy-load pattern budgets the *reading* (defer loading until relevant). Both reduce context cost — they're complementary, not competing.

## Cross-Refs

No cross-cluster references.
