Advanced CLAUDE.md patterns: signpost lazy-loading, modular refactoring, conflict resolution documentation, and the solatis two-file pattern for context budgeting.
- **Keywords:** CLAUDE.md, signpost, lazy load, modular includes, refactor, conflict resolution, solatis, token budget, context budgeting, guideline directory reform, route conditional by theme, dedup on move, split test, fingerprint grep verify
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

## Split a Mixed `@`-Loaded File: Conventions Stay, Procedures Signpost Out

When an `@`-loaded guideline file mixes always-relevant **conventions** (naming, path style, commit rules) with situational **procedures** (rebase steps, rename-check workflows), split it: conventions stay eager; procedures move to an on-demand learning. The split test — *"does every session need this rule, or only sessions doing X?"* Procedures fail it and cost context on every unrelated session.

Leave a one-line pointer in the vacated file (→ the learning) and add the moved content to the learnings index in the same change. An extracted procedure with no inbound link gets rediscovered and rewritten — the pointer + index entry is what surfaces it "when doing X."

## Reforming a Whole `@`-Loaded Directory: Route by Theme, Dedup on the Way Out

Applying the split test across an entire `@`-loaded guideline *set* (not one file) — route each conditional section by theme, don't dump it all in one place:
- **Cross-cutting craft** (refactor / review heuristics, not domain-bound) → one new dedicated learning.
- **Domain-specific** (test conventions, a subsystem gotcha) → that domain's existing home (e.g. `tests/CLAUDE.md`).
- **A distinct cluster** (e.g. language gotchas) → a small new seed file; 2 items is enough to start one.

**Read the destination before copying.** Conditional guideline content is often *already duplicated* at its natural home (test-writing patterns frequently live in both the guideline and `tests/CLAUDE.md`), so the split doubles as a dedup — keep one copy, leave the guideline a pointer. Verify with a fingerprint grep: each moved section present in exactly one destination, absent from the vacated file (only the signpost paraphrase remains).

## A Pointer or Summary Is Only as Durable as Its Target

An index entry, signpost, or auto-memory note that *points to or summarizes* a separate source-of-truth artifact dangles when the target isn't durable: a `tmp/claude-artifacts/` doc is gitignored + machine-local (gone on a fresh checkout), and a memory that paraphrases a doc silently diverges when the doc is edited and orphans it when the memory is deleted. If an artifact must persist across sessions, put it in a tracked path (`docs/`); keep memory/index entries thin (location + trigger), not content summaries that rot.

## Cross-Refs

No cross-cluster references.
