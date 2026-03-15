# Learning Authoring Patterns

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

Additionally, when creating a new learnings file, check personas in `~/.claude/commands/set-persona/` for `Detailed references` sections that cover the same domain — a new file won't be discoverable through persona activation unless it's wired in. Suggest adding a reference link to matching personas.

## Cross-Reference Convention (`## See also`)

Learnings files can cross-reference related files to enable **lateral discovery** — finding files that are relevant to what you already loaded but wouldn't be found by keyword search alone. Cross-refs are conditional (non-`@`) signposts, not eager loads.

**Format:** A `## See also` footer as the last section in the file, with 1-3 refs:

```markdown
## See also

.claude/learnings/postgresql-query-patterns.md — migration patterns overlap with Flyway/Spring Boot
.claude/learnings/java-observability-gotchas.md — Spring Boot instrumentation pitfalls
```

**Rules:**
- **Scope:** Learnings-only (`~/.claude/learnings/`) for now — not cross-type to skills or guidelines
- **Only non-obvious relationships.** If keyword search would find the connection (shared vocabulary in filenames or content), a cross-ref adds no value. Reserve for relationships where the agent wouldn't think to search.
- **1-3 refs max per file.** More than 3 signals the file is a hub that relates to everything — that's noise, not signal.
- **Include a reason.** The one-liner after the path explains *why* the relationship exists, which helps the agent (and user) judge relevance without loading the target.
- **Path format:** `.claude/learnings/<file>.md` (CWD-relative, consistent with Glob/Grep path conventions in this repo)
- **Placement:** Always the last section in the file, after all content sections.

**Bidirectionality:** When adding A → B, check whether B → A is also valuable. Relationships can be asymmetric — "spring-boot-gotchas relates to postgresql for migrations" doesn't necessarily mean postgresql needs to link back to spring-boot. Add the reverse only when both directions provide lateral discovery value.

**Growth:** Cross-refs grow organically through `/learnings:curate` content-mode passes, not through bulk backfill. When curate touches a file, it considers cross-ref opportunities as part of the pass.

**Staleness:** Cross-refs can decay two ways:
1. **Target deleted** — the file no longer exists (caught by glob)
2. **Relationship decay** — the file exists but the stated reason no longer holds (e.g., content was refactored to cover different topics). Curate checks both during its staleness pass.

**Example — curation-specific cross-refs:**
- **Source-vs-echo test** — see `curation-insights.md` → "Source-vs-echo test for deletions"
- **Reusability test** — see `curation-insights.md` → same section

## Deep Coverage Analysis for Deleted Content

When consolidation removes sections, verify concepts have new homes — not just that keywords appear elsewhere. Check both git history (original content) and current corpus (where concepts landed). Categorize each deleted section as: COVERED (concepts exist elsewhere), PARTIALLY COVERED (some missing), or GAP (unique content dropped). For partial coverage, add the missing pieces to existing files rather than re-creating the deleted section.
