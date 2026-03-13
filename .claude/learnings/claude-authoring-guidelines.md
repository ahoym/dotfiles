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

## Content Type Taxonomy

Full placement decision table for the Claude configuration surface:

| Content type | Location | What belongs here | Placement test |
|---|---|---|---|
| **Guideline** | `guidelines/` | Behavioral rules ("always do X") | Shapes behavior universally, `@`-loaded from CLAUDE.md |
| **Learning** | `learnings/` | Domain knowledge: gotchas, recipes, patterns | Conditional reference, loaded by persona or keyword search |
| **Persona** | `commands/set-persona/` | Judgment lens: priorities, tradeoffs, review instincts | "Would activating this change what I do?" — if just a gotcha list, not ready |
| **Skill reference** | `skill-references/` | Shared patterns consumed by 2+ skills | Single source of truth; skills read selectively, not `@`-loaded |
| **Template** | Inside skill directory | Message body content (reply text, PR descriptions) | Body-only — no posting commands. Promote to `skill-references/` if shared |
| **Memory** | `memory/` | Facts, context, project state | Last resort — if it would be useful to a skill or persona, use a discoverable file instead |
| **CLAUDE.md** | Project root or subdirectory | Navigational hub, architecture, relationships | `@` refs for always-needed context; signposts (non-`@`) for conditional |

**Boundary cases:**
- Prescriptive but conditional on domain → learning or persona gotcha, not guideline
- Guideline that restates a skill's default behavior → redundant, remove it
- Learning fully covered by a persona one-liner → apply the persona-learning boundary test (does the learning add recipes/context the rule alone can't trigger?)
- Content in memory that's a behavioral rule → migrate to guideline

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
## Hard Gates Need Tool-Call Triggers

Enforcement gates for agent self-discipline are only "hard" when tied to discrete tool calls (`EnterPlanMode`, `Task`, `Write`, `Skill`). Gates tied to judgment calls ("is this my first substantive response?", "did a keyword appear?") are soft layers dressed as hard rules — they compete with the primary task and lose.

When designing enforcement for agent behavior, ask: "What tool call triggers this check?" If there's no tool call, it's a soft layer regardless of how mandatory the language sounds. Soft layers are still valuable (they fire sometimes), but don't count on them for critical checks.

## Unreferenced Guidelines Are Dead Weight

A guideline not `@`-referenced from CLAUDE.md and not referenced by any skill or persona has no delivery mechanism. The content may be valid but it never loads — making it invisible to the agent.

**During curation**: Grep the corpus for the guideline filename. If nothing references it, the content needs to either earn an `@`-reference (if universal) or move to the correct content type (learning for reference info, persona gotcha for domain-specific patterns).

**Common pattern**: Domain-specific debugging heuristics and operational procedures get created as guidelines because they contain prescriptive language ("do X before Y"). But prescriptive ≠ behavioral. The test: does it change behavior universally, or provide knowledge conditionally? If conditional → learning or persona, not guideline.

## Don't Create Guidelines That Restate Skill Defaults

A guideline is redundant when skills already handle the behavior as part of their instructions. It's counterproductive when it overrides explicit user intent.

**Test:** For any proposed guideline, ask: "Does a skill already route this correctly by default?" If yes, the guideline adds no value for the default case and risks overriding the user when they intentionally deviate.

**Example:** A "store learnings in `~/.claude/`, not repo branches" guideline was redundant because `learnings:compound` already writes to `~/.claude/learnings/` by default. Worse, it intercepted explicit requests like "save these learnings to the repo" — overriding the user's stated intent to put project-specific content in the project.

**Rule:** Guidelines should shape ambiguous situations, not override explicit instructions. If a skill handles the default and the user explicitly asks for something different, honor the user.

## Uniform Convention Over Case-by-Case Optimization

When a structural pattern applies to a category (e.g., "every persona gets a gotcha file"), apply it uniformly — even when a specific instance doesn't strictly need it (e.g., a gotcha file with a single consumer). Predictability of the convention matters more than minimizing artifact count. Case-by-case exceptions erode the pattern and force future decisions that the uniform rule would have automated.

## Three-Tier Guideline Separation: Universal / Language / Project

When extracting guidelines from a monolithic config, use a deliberate taxonomy: (1) universal software engineering principles (helper class extraction, factory functions, SRP — applicable to any language, uses pseudocode examples), (2) language-specific practices (docstrings, linting, float comparisons), and (3) project-specific conventions (noqa directives, test file naming, domain-specific patterns). The universal tier's portability across projects is the key design goal — pseudocode examples, not language-specific ones.

- **Takeaway**: Structure guidelines in three tiers (universal/language/project) with pseudocode at the universal level for cross-project portability.
