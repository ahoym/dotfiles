# Guideline Authoring Patterns

## Merging overlapping guidelines

When two guidelines cover similar territory, merge them into a single section rather than keeping both.

**Pattern**: Make the general principle the heading, and fold the specific case in as an example or opening sentence.

**Example from session**: "Ask when uncertain" (don't guess values) and "Express uncertainty explicitly" (be transparent about confidence) both dealt with uncertainty. Merged into "Be honest about what you know and don't know" — the specific case (don't guess values) became the opening sentence, and the general principle (be transparent about confidence) became the broader framing.

**Why this works**: Fewer guidelines are easier to internalize. When two sections overlap, readers (and AI) have to reconcile them. A single section with a clear principle + concrete examples is both shorter and more actionable.

**When to apply**: During guideline curation (`/learnings:curate`), look for sections that address the same underlying behavior from different angles. If one is a specific instance of the other, merge them.

## Avoid Nesting Subdirectories Inside learnings/

Content is either a guideline (in `guidelines/`) or a learning (in `learnings/`). Do not create a `guidelines/` subfolder inside `learnings/` — it creates type ambiguity and discoverability issues.

**The problem:** Files in `learnings/guidelines/` look like guidelines (behavioral, prescriptive) but live in the learnings directory. They won't be found by guideline searches, won't be candidates for `@`-import, and their location suggests they're reference material when they're actually behavioral rules.

**Rule:** If content is behavioral/prescriptive, decide: is it universal enough for `guidelines/`? If yes, put it there. If it's domain-specific, put it in a persona or keep it as a flat learning in `learnings/`. No middle ground.

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
