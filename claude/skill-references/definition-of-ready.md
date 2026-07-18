---
description: "Definition of Ready (DoR) heuristic for routing a ticket to auto-implement vs clarify-first. Used by sweep:epic-advance and the eventual implementer runner. Encodes 'can a competent engineer form a reasonable plan and start?' as a string-matching heuristic with worked examples."
---

# Definition of Ready

A ticket is **ready** when a competent engineer could pick it up, form a reasonable implementation plan, and start coding without first having to ask blocking questions. Not-ready tickets need a clarification round-trip (typically: implementer-runner posts focused questions, operator answers, ticket re-evaluates next run).

This heuristic is intentionally permissive — it matches how senior engineers actually triage ambiguous tickets. Open questions with a recommended resolution, a hint to investigate, or a punt-to-MR-review path are **not blockers**. Only fundamental ambiguity that prevents forming a plan disqualifies a ticket.

## The rule

```
ready =
     (AC_concrete OR slice_design)        // scope is specified
  AND no_blocking_ambiguity                // path forward exists for any open questions
```

Either of (AC concreteness) or (slice design) alone is sufficient for scope. Concrete AC tells the engineer *what behavior* to deliver; slice design tells them *where the code goes*. A competent engineer fills whichever the ticket leaves open.

## Check 1: Scope specified

### AC concreteness

Body has a structured acceptance-criteria section AND the criteria name concrete change targets:

- A heading matching `(Acceptance Criteria|AC|Definition of Done|DoD)` (case-insensitive)
- Followed by checkbox or bullet list with content that names: specific files, classes, methods, fields, configuration values, error semantics, or test scenarios

**Examples of concrete AC bullets:**
- `[ ] Bean registers only when app.feature.cache.enabled=true`
- `[ ] Returns empty list (never null) on transport-level errors`
- `[ ] Add field userId: string to GET /users response`

**Examples of vague AC bullets:**
- `[ ] Implement user SPI`
- `[ ] Should work correctly`
- `[ ] Handles errors`

### Slice design

Body has a section that gives implementer-grade direction for *this* ticket's slice:

- A heading matching `(Scope|Approach|Implementation|Plan|Design|Solution)` with non-empty content (>2 lines, not just "TBD" or one-liners)
- Content references concrete artifacts: file paths, class names, annotations, wiring patterns, library calls, sibling-file analogues

Slice design must be **ticket-specific**, not just broader context. A link to the parent epic's design doc with no in-ticket section is broader context — supports the slice but doesn't satisfy this check on its own.

### Background context

Links to broader docs (Confluence, Figma, ADRs, parent epic body) are **supporting evidence** but never sufficient alone. They help when paired with concrete AC ("AC says add field X; broader doc says why") but cannot substitute for either AC concreteness or slice design.

## Check 2: No blocking ambiguity

Open questions are tolerable when the ticket gives the implementer a path forward. They block only when starting would require guessing the answer.

### Strong-block patterns (any one → not ready)

- Body contains: `do not implement`, `do not start until`, `blocked on (design|spec|approval)`, `pending (design|spec|architecture)`, `wait for X to confirm`
- `TBD` standalone — not followed by a tentative answer or recommendation
- An `Open Question(s)` / `Questions` / `Unknowns` section with items that have no recommendation phrase, no hint, and no investigation path nearby

### Path-forward patterns (neutralize open questions)

A question is **not** a blocker when nearby text contains any of:

- Recommendation: `recommended`, `let's go with`, `we should`, `lean toward`, `tentatively`, `likely`
- `Option [A-Z] — ... (recommended)` or `Option [A-Z] is the right call`
- Investigation hint: `verify in code`, `check the schema`, `grep for`, `look at <file>`, `see <ticket>`, `same as <pattern>`, `mirror <thing>`, `analogous to`
- Punt-to-review: `confirm in MR`, `flag in PR`, `ask in review`

### Soft signals (count toward not-ready but don't auto-block)

- AC bullets with bare `?` or `TBD` (no surrounding hint)
- Multiple open-question items, none with recommendations

A single soft signal alone usually doesn't disqualify; multiple soft signals plus weak scope tip the verdict to clarify.

### Where to look

| Signal source | What to scan |
|---|---|
| Body | Sections, AC bullets, prose |
| Comments | Newest-first; questions from non-author without an author reply |
| Parent epic | Inherited blocks (e.g., "this epic is gated on architecture review") |

## Verdict

Combine the two checks:

| Scope (Check 1) | Blocking ambiguity (Check 2) | Verdict |
|---|---|---|
| ✓ (AC concrete OR slice design) | ✗ (no blockers) | **implement** |
| ✓ | ✓ (blocker present) | **clarify** |
| ✗ (vague + no slice design) | * | **clarify** |

The verdict carries a **reason** — which check failed, which signal triggered. The plan emitter renders this in the Active/Deferred tables; the implementer-runner consumes it to know whether to attempt directly or fall back to clarify.

## Output schema

```typescript
interface DoRResult {
  ready: boolean;
  verdict: "implement" | "clarify";
  scope: {
    acConcrete: boolean;
    sliceDesign: boolean;
    backgroundContext: string[];  // URLs/refs found, supporting evidence only
  };
  ambiguity: {
    blockers: AmbiguityHit[];      // strong-block patterns matched
    softSignals: AmbiguityHit[];   // questions with no path forward
    pathForwards: AmbiguityHit[];  // questions with recommendations/hints (neutralized)
  };
  reason: string;  // human-readable, surfaced in plan output
}

interface AmbiguityHit {
  pattern: string;  // which detection pattern matched
  excerpt: string;  // ~200 chars of surrounding text
  location: "body" | "comments" | "parent-epic";
}
```

## Worked example: PROJ-90

**Ticket:** "Svc: Implement DbUserLoader"

**Check 1 — Scope:**
- AC concrete: ✓ — five bullets naming `@Primary`, `@ConditionalOnProperty`, specific grouping logic to port from `AccountGrouper.groupByRegionAndType`, error semantics
- Slice design: ✓ — `## Scope` names the file path `svc-server/.../adapter/user/DbUserLoader.java`, annotations, constructor injection, method behavior

**Check 2 — Blocking ambiguity:**
- `## Open question` section: Option A vs Option B — but contains "Option A recommended" → path forward (not a blocker)
- AC bullet 5: `[ ] Sets isCompanyOwned correctly — verify with the operator how company-owned users are flagged in the vendor schema (likely a dedicated column or a type field)` — contains "likely" → investigation hint, path forward (not a blocker)
- Strong-block patterns: none
- Net: no blocking ambiguity

**Verdict: implement**

**Reason:** "Concrete AC + slice design present. Two open items have path forward (Option A recommended; isCompanyOwned has investigation hint). Implementer should adopt Option A, investigate the vendor schema for an isCompanyOwned analog, and surface unresolved questions in MR description for review."

This is the right call — a senior engineer wouldn't stop on this ticket. They'd implement, investigate the hints, and use the MR description to surface anything still unresolved.

## How the implementer-runner uses this

The runner applies the same rule when picking up a ticket. If the dispatcher routed the ticket as `implement` but the runner — with full body + comments — concludes the ticket is actually not ready, it falls back to `clarify` mode (posts focused questions, exits). This makes the dispatcher's heuristic forgiving: false positives at dispatch time are caught at runner time.

For ambiguity items with path forward, the runner is instructed to:
1. Adopt recommendations as written
2. Investigate hints (codebase grep, sibling tickets, parent epic)
3. If still unresolved, leave a `TODO(Q):` with the question and surface it in the MR description: `## Open from ticket\n- <Q>. Implemented assuming X — please confirm in review.`

This pattern means open questions don't block delivery; they become review-time conversations with concrete code attached.

## Cross-Refs

- `~/.claude/skill-references/jira-issue-mapping.md` — field extraction (where to read body, comments, parent)
- `~/.claude/skill-references/mr-state-classification.md` — classification taxonomy that feeds DoR (only `not-started` and `in-progress-no-mr` tickets get DoR-evaluated)
- `~/.claude/skill-references/epic-fetch-classify.md` — pipeline that produces the input for DoR evaluation

## Open question for next iteration

**How does this compare to canonical Agile Definition of Ready?** Standard Agile DoR typically includes: well-defined story, clear AC, dependencies identified, estimable, testable, sized appropriately. We cover AC, dependencies (via `blockedBy`), and partially testability (via `## Tests` sections). We don't currently check:
- Estimable (story points present)
- Sized appropriately (within sprint capacity, single-deliverable)

Worth comparing against established DoR templates to see what we're missing and whether those gaps matter for auto-dispatch (vs. just being agile-ceremony hygiene).
