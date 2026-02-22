# Skill Design Patterns

## Gap vs Inconsistency Boundary

When a skill identifies documentation issues, "gaps" and "inconsistencies" must be explicitly defined with a clear, non-overlapping boundary — otherwise the same item appears in both.

**Definitions:**
- **Gap** — Docs don't mention something at all. The code has a pattern/feature/system that is completely absent from documentation.
- **Inconsistency** — Docs exist but contradict the code. The doc says X, the code does Y.

**Why this matters:**
- Without explicit boundaries, items like "CLAUDE.md says transactions arrive via REST but they actually come from polling" are both a gap AND an inconsistency
- Duplication wastes tokens and confuses readers about where the authoritative finding lives
- The fix is to make each category's definition exclude the other explicitly

**Pattern:** In skill instructions, include a preamble for each category:
- Gaps section: "Do NOT include items where docs exist but contradict the code; those belong in inconsistencies."
- Inconsistencies section: "Do NOT duplicate items from the gaps section."

## Skills Should Self-Document Permission Needs

Skills that read or write files outside the project directory should include a **Prerequisites** section listing the exact `permissions.allow` patterns needed for prompt-free execution.

**Why:**
- Users shouldn't have to reverse-engineer which permissions a skill needs through trial and error
- Permission rule syntax is non-obvious (e.g., `Read()` covers Glob/Grep, not `Glob()` or `Search()`)
- A prerequisites section serves as both documentation and a copy-paste config block

**Pattern:** Add a `## Prerequisites` section to SKILL.md with a JSON snippet listing exact permission patterns.

## Merging Diverged Skills Across Repos

When two repos have independently evolved the same skill, merge by keeping unique features from both sides and parameterizing platform differences via a shared reference file.

**Pattern:**
1. Compare both versions side by side — identify unique sections in each
2. Use the more complete version as the base
3. Append unique sections from the other version
4. For platform-specific commands (gh vs glab, PR vs MR), create a shared reference file (e.g., `_shared/platform-detection.md`) with detection logic and a mapping table
5. Add "Step 0: Detect platform" to each skill that references the shared file
6. Keep PR-based naming (majority convention) and let runtime detection handle GitLab

**Why parameterize instead of maintaining two copies:**
- One codebase to maintain, no future drift
- Learnings applied to one skill automatically apply to both platforms
- Shared reference file is a single source of truth for CLI/terminology mapping

## Cross-Skill Reference File Deduplication

When curating a skill, compare its reference files against reference files in companion skills — especially producer/consumer pairs or skills in the same workflow. Duplicated reference files diverge silently as each skill evolves independently.

**Detection:** During skill curation (step 3s evaluation), read reference files from related skills and check for >80% content overlap. The superset version is usually in the skill that uses the content more heavily.

**Resolution:** Move the superset version to `_shared/` and update both skills' SKILL.md to reference the shared path. This ensures future improvements propagate to both skills automatically.

**Why this happens:** When a producer/consumer skill pair is developed, both need guidance on the same topic (e.g., "how to write good agent prompts"). The guidance gets written in one skill first, then copied to the other with minor additions. Over time the copies diverge as each skill adds its own refinements.

## Skill Improvement Feedback Loop

After running a skill in a real session, assess its performance while context is fresh:

1. **What worked** — note patterns that executed smoothly and produced good results
2. **What didn't** — identify friction, improvisation, or gaps in the skill instructions
3. **Prioritize by value** — rank improvements by impact on execution quality:
   - Quality regression prevention (codifying improvised approaches) >> minor efficiency gains
   - One-line fixes with real impact >> structural overhauls
   - Diminishing returns are real — stop at 3-5 improvements per session
4. **Apply in the same session** — context is fresh, the skill files are already read, and the user can validate immediately

**Why same-session:** Skill improvements lose fidelity across sessions. The specific friction points, improvised workarounds, and "I had to figure out X manually" moments fade quickly. Capturing them while the execution is in working memory produces more precise fixes.

## Producer/Consumer Contract Validation

When two skills form a producer/consumer pair (e.g., a planner skill produces plans that an executor skill consumes), validate that the producer knows how to generate every section the consumer expects.

**Pattern:** For each section the consumer references:
1. Check whether the **producer's** SKILL.md has instructions to generate that section
2. Don't just grep the target ecosystem — a term appearing in the executor doesn't mean the planner produces it

**Why grep-only checks fail:** Searching for a section name in the target repo and finding many references in the consumer made it look covered. But the producer had no instruction to produce that section — the producer/consumer contract was broken.

## _shared Files: Discovery and Frontmatter

Files in `commands/_shared/` (or `<group>/_shared/`) are internal reference docs, not standalone skills. But Claude Code treats any `.md` file in `commands/` as an invocable skill and lists it in the system-reminder. This is cosmetic — agents see the description and route correctly — but the skill list gets noisier.

**Fix:** Add frontmatter with a description that starts with "Internal reference —" and ends with "Used by other skills, not invoked directly."

```yaml
---
description: "Internal reference — GitHub vs GitLab detection logic. Used by git skills, not invoked directly."
---
```


## Scope _shared/ Files to Their Skill Group

When a `_shared/` reference file is only used by skills within a single group, it should live in that group's `_shared/` directory rather than the global `commands/_shared/`. Only truly cross-group references belong in global `_shared/`.

**Decision criteria:** Grep for all references to the shared file. If every reference is within a single skill group → move it into `<group>/_shared/`. If references span multiple groups or standalone skills → keep in global `_shared/`.

**Benefits:**
- Collocates reference docs with the skills that use them
- Makes it obvious which group "owns" the content
- Reduces the global `_shared/` to genuinely cross-cutting references

## Orchestrator/Agent Separation for Multi-Step Skills

Split SKILL.md into two files when a skill has a multi-step background workflow:

1. **Orchestrator (SKILL.md)** — Handles user interaction only: identifying items, displaying for selection, gathering input. Target ~80 lines.
2. **Background agent steps (separate .md)** — Contains the autonomous workflow executed by a Task agent. Includes command templates, decision tables, file placement rules, error recovery.

Key design choices:
- No eager `@` references in SKILL.md — list reference files as conditional (plain text). Load via Read tool only when needed.
- Pass background steps via Task prompt — orchestrator reads the file and includes content in the Task tool's prompt parameter.
- Neither file carries the other's concerns.

## Background Steps File Structure

- **Aliases at top**: Define shorthand for repeated values (not shell variables, just agent instructions)
- **Decision tables for branching**: Use markdown tables instead of nested if/else prose
- **Inline warnings at point of use**: Place warnings where the agent encounters the situation, not in a separate notes section at the bottom
- **Error recovery at bottom**: Keep concise (2-3 rules)

## Avoid Internal Jargon in User-Facing Report Columns

Skill output templates (tables, summaries) should use language meaningful to someone unfamiliar with the skill's internal classification model. Column headers like "Why LOW" reference an internal confidence tier — readers unfamiliar with the HIGH/MEDIUM/LOW system interpret it as "low value" or "low priority." Use action-oriented labels instead (e.g., "Tradeoff" — explains what you'd give up by acting on the item).

