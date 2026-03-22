# Learning Authoring Patterns

Craft patterns for writing learnings files including genericization, scope classification, cross-reference conventions, persona boundary tests, and directory organization.
**Keywords:** genericize, project-specific, scope classification, cross-refs, persona-learning boundary, provenance, hub-spoke, discovery vs semantic, catch-all directory, CLAUDE.md index, dedup
**Related:** claude-authoring-content-types.md

---

## Genericize Project-Specific Content in Global Learnings

Global learnings (in `~/.claude/learnings/`) should use domain-neutral examples. When curating, replace project-specific references with portable equivalents.

**What to replace:**

| Project-Specific | Generic Replacement |
|---|---|
| `acme_client`, `api_client` | `api_client`, `service_client` |
| `AssetMovementResult`, `PaymentResult` | `ResponseModel`, `OperationResult` |
| `TypeMatcher(str)` (custom test helper) | "custom matcher objects" (generic framing) |
| `customerReference` (domain field) | `referenceId`, `trackingId` |
| Project-specific class/method names in examples | Domain-neutral names that illustrate the same concept |

**What to keep:**
- Language/framework names (`Pydantic`, `FastAPI`, `Spring Boot`)
- Standard library types and patterns
- The underlying insight — only the example wrapping changes

**When to apply:** During `/learnings:curate`, check each "Standalone reference" pattern for project-specific content. If the examples use names from a specific codebase, genericize them while preserving the pattern's teaching value.

**Exception — concrete examples that outweigh genericization:** When a project-specific example IS the teaching material — making a gotcha vivid and memorable in a way a generic replacement can't — keep it. The genericization rule exists to prevent learnings from being useless outside the project. If the pattern is already useful regardless of the specific example (the lesson is universal even though the illustration is domain-specific), the example's concreteness wins.

**Provenance vs structural content:** Distinguish between provenance notes ("discovered while building X") and structural examples (a domain-specific regex that makes a collision visible). Provenance is always safe to remove — it adds no teaching value. Structural examples need case-by-case judgment: would a generic replacement teach the same lesson as effectively?

**Create project-specific instances when genericizing.** When removing domain-specific content from a global learning, check if the originating project has a learnings directory (e.g., `docs/claude-learnings/`). If so, add the project-specific instance there. The global file teaches the generic pattern; the project file preserves the concrete gotcha where it's most useful.

## Persona-Learning Boundary Test

When curating, use the **"what mistake could I still make?"** test to evaluate whether a learning adds value beyond its persona rule. Personas carry one-liner gotchas; learnings carry recipes, code examples, and deeper context. If a persona rule fully prevents the mistake, the learning is redundant. If the learning prevents a mistake the persona rule alone wouldn't catch, it earns its keep.

## Avoid Nesting Subdirectories Inside learnings/

Content is either a guideline (in `guidelines/`) or a learning (in `learnings/`). Do not create a `guidelines/` subfolder inside `learnings/` — it creates type ambiguity and discoverability issues.

**The problem:** Files in `learnings/guidelines/` look like guidelines (behavioral, prescriptive) but live in the learnings directory. They won't be found by guideline searches, won't be candidates for `@`-import, and their location suggests they're reference material when they're actually behavioral rules.

**Rule:** If content is behavioral/prescriptive, decide: is it universal enough for `guidelines/`? If yes, put it there. If it's domain-specific, put it in a persona or keep it as a flat learning in `learnings/`. No middle ground.

## Scope Classification Needs Language-Awareness

Extraction subagents classify learnings as "general" when the underlying principle feels universal, even when the examples and syntax are language-specific. Python patterns like `# noqa` suppression, `__all__` exports, and sentinel `None` defaults were classified as general scope because the concepts (fix root causes, define public APIs) are universal — but the actual content is only useful in Python contexts. Writers should cross-check: if a learning references language-specific syntax, tooling, or idioms, route it to the language-specific file regardless of how universal the principle feels.

## Grep Before Creating New Files

When creating a new learnings file, first grep `~/.claude/learnings/` for existing files matching the domain. Without this check, near-duplicate files accumulate (e.g., `parallel-planning.md` and `parallel-plans.md` about the same topic). Similarly, check if the insight already exists in a more authoritative location before creating a domain-specific copy — platform behavior patterns compounded from a parallel-plan session may already be covered in `claude-code.md`.

Additionally, when creating a new learnings file, check personas in `~/.claude/commands/set-persona/` for `Cross-Refs` sections that cover the same domain — a new file won't be discoverable through persona activation unless it's wired in. Suggest adding a reference link to matching personas.

## Cross-Reference Convention (`## Cross-Refs`)

Learnings files can cross-reference related files to enable **lateral discovery** — finding files that are relevant to what you already loaded but wouldn't be found by keyword search alone. Cross-refs are conditional (non-`@`) signposts, not eager loads.

**Format:** A `## Cross-Refs` footer as the last section in the file, with 1-5 refs:

```markdown
## Cross-Refs

.claude/learnings/postgresql-query-patterns.md — migration patterns overlap with Flyway/Spring Boot
.claude/learnings/java-observability-gotchas.md — Spring Boot instrumentation pitfalls
```

**Rules:**
- **Scope:** Learnings-only (`~/.claude/learnings/`) for now — not cross-type to skills or guidelines
- **Only non-obvious relationships.** If keyword search would find the connection (shared vocabulary in filenames or content), a cross-ref adds no value. Reserve for relationships where the agent wouldn't think to search.
- **1-5 refs max per file.** The number is a guardrail, not a target — each ref must pass the non-obvious test. Hub files that route to a cluster may exceed 5 when each ref adds non-keyword-discoverable value.
- **Include a reason.** The one-liner after the path explains *why* the relationship exists, which helps the agent (and user) judge relevance without loading the target.
- **Path format:** `~/.claude/learnings/<file>.md` (absolute tilde path — works outside the repo's CWD and matches Read tool resolution from any context)
- **Placement:** Always the last section in the file, after all content sections.

**Hub-spoke rule:** When files form a hub-spoke cluster (e.g., `claude-authoring-content-types.md` routing to `claude-authoring-skills.md`, `claude-authoring-guidelines.md`, etc.), spokes should cross-ref the hub (upward navigation — the agent needs a breadcrumb back to the routing table) but NOT sibling spokes (lateral navigation — the hub already handles that). Spoke-to-spoke refs duplicate hub routing and grow linearly with new spokes.

**Bidirectionality:** When adding A → B, check whether B → A is also valuable. Relationships can be asymmetric — "spring-boot-gotchas relates to postgresql for migrations" doesn't necessarily mean postgresql needs to link back to spring-boot. Add the reverse only when both directions provide lateral discovery value.

**Growth:** Cross-refs grow organically through `/learnings:curate` content-mode passes, not through bulk backfill. When curate touches a file, it considers cross-ref opportunities as part of the pass.

**Staleness:** Cross-refs can decay two ways:
1. **Target deleted** — the file no longer exists (caught by glob)
2. **Relationship decay** — the file exists but the stated reason no longer holds (e.g., content was refactored to cover different topics). Curate checks both during its staleness pass.

**Prioritize islands.** Files with no persona refs and no inbound cross-refs are discoverable only by filename match. Target these first, especially when they share no obvious keyword overlap with related files.

## Deep Coverage Analysis for Deleted Content

When consolidation removes sections, verify concepts have new homes — not just that keywords appear elsewhere. Check both git history (original content) and current corpus (where concepts landed). Categorize each deleted section as: COVERED (concepts exist elsewhere), PARTIALLY COVERED (some missing), or GAP (unique content dropped). For partial coverage, add the missing pieces to existing files rather than re-creating the deleted section.

## Provenance Tracking in Retros

When reviewing learnings load effectiveness (e.g., in `/session-retro`), tag each loaded file with its provenance: hard gate (session-start, plan-mode, implementation-start), soft gate (confidence-level, friction-triggered, keyword-triggered), persona proactive, skill reference, operator-prompted, self-directed, or cross-ref. This surfaces whether the search protocol is doing its job or whether useful files are only reached through persona coverage or manual reads. Missed soft gates are the highest-value finding — they reveal where the protocol should fire but doesn't.

## Avoid Naming Learnings After Repos or Ambient Context Terms

Filenames are the search protocol's primary index. If a file is named after a repo (e.g., `dotfiles-workflow.md` in the dotfiles repo), the session-start gate matches it on every session — branch names, CWD paths, and git status all contain the repo name. The file gets loaded regardless of relevance, wasting context budget.

**Fix:** Name learnings after the *pattern*, not the *source*. `worktree-pr-hygiene.md` > `dotfiles-workflow.md`. If the content is repo-specific and actionable, it belongs in that repo's `CLAUDE.md` instead.

## CLAUDE.md as Curated Directory Index

A `CLAUDE.md` in a reference directory (e.g., `~/.claude/learnings/`) can serve as a curated index: one entry per file with a filename and one-line description grouped by domain. This replaces the glob → derive terms → sniff pipeline with a single read.

**Design:** Federated — each directory owns its `CLAUDE.md`. A parent index conditionally references child indexes (`if ~/.claude/learnings-private/CLAUDE.md exists, read it too`). No eager loading; files are read on demand after scanning the index.

**Why it works:** The sniff step (read 5 lines to check relevance) exists because filenames alone are weak signals. Descriptions make sniffing unnecessary. The pipeline was compensating for missing structure.

**Maintenance cost:** Low when there's a regular consolidation cadence — add an entry when adding a file, remove when removing.

## Cross-Reference Types: Semantic vs Discovery

Two distinct purposes for `## Cross-Refs` cross-references in learnings files:

- **Discovery** ("this file also exists") — redundant when a curated index is present; the index surfaces all files with descriptions. Can be dropped.
- **Semantic** ("when using X with Y, the interaction matters because Z") — carries contextual reasoning that no index description can replicate. Keep these; they fire when a file is *already loaded* and provide targeted follow-up context.

**Test:** Does the cross-reference explain *why* the interaction matters, or just that another file exists? If the latter, the index makes it redundant.

## Avoid Catch-All Directories

When organizing files into subdirectories, don't create a `general/` or `misc/` directory for uncategorized files. Keep them at the root instead.

**Why:** A catch-all directory hides clustering signals. When 3+ root files share a theme, the clustering is visible and the promotion path to a new domain directory is obvious. Inside a catch-all, the same signal is buried in a grab-bag that never gets reviewed. The directory name carries no domain signal — it's a category that means "uncategorized."

**Rule:** Files that don't fit a domain directory stay at the root. Promote to a new directory when a theme emerges (3+ files). Review root files during curation passes.

### Keyword gate design: dedup as scoping mechanism

When reintroducing a broad trigger (e.g., keyword-based learnings search), existing narrower gates + dedup can handle scoping naturally — a broad trigger doesn't need its own specificity filter if other gates already cover the common cases and dedup prevents redundant loads. Quoted terms from the operator bypass dedup as an explicit override.

## Cross-Refs

- `claude/learnings/claude-authoring-content-types.md` — hub: content type taxonomy, routing table, boundary cases
