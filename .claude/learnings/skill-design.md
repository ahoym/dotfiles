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
2. Use the more complete version as the base, append unique sections from the other
3. For platform-specific commands (gh vs glab, PR vs MR), create a shared reference file with detection logic and a mapping table
4. Add "Step 0: Detect platform" to each skill that references the shared file
5. Keep PR-based naming (majority convention) and let runtime detection handle GitLab

One codebase to maintain means no future drift — learnings applied to one skill automatically apply to both platforms.

## Cross-Skill Reference File Deduplication

When curating a skill, compare its reference files against reference files in companion skills — especially producer/consumer pairs or skills in the same workflow. Duplicated reference files diverge silently as each skill evolves independently.

**Detection:** During skill curation (step 3s evaluation), read reference files from related skills and check for >80% content overlap. The superset version is usually in the skill that uses the content more heavily.

**Resolution:** Move the superset version to `skill-reference/` (or a skill group's shared location) and update both skills' SKILL.md to reference the shared path. This ensures future improvements propagate to both skills automatically.

**Why this happens:** When a producer/consumer skill pair is developed, both need guidance on the same topic (e.g., "how to write good agent prompts"). The guidance gets written in one skill first, then copied to the other with minor additions. Over time the copies diverge as each skill adds its own refinements.

## Skill Improvement: Fix and Assess In-Session

Apply skill improvements and repairs in the same session — context fades quickly across sessions. Specific friction points, improvised workarounds, and failure modes are most accurately captured while in working memory.

**Proactive assessment** (after running a skill):
1. **What worked** — note patterns that executed smoothly
2. **What didn't** — identify friction, improvisation, or gaps
3. **Prioritize** — quality regression prevention >> minor efficiency gains; one-line fixes with real impact >> structural overhauls. Stop at 3-5 improvements per session.

**Reactive repair** (skill hits a bug mid-execution):
- Fix immediately — the failure mode, workaround, and user reaction are all in context
- Scope: one constraint workaround or behavioral tweak per incident. Don't refactor the whole skill because one step was awkward.

## Producer/Consumer Contract Validation

When two skills form a producer/consumer pair (e.g., a planner skill produces plans that an executor skill consumes), validate that the producer knows how to generate every section the consumer expects.

**Pattern:** For each section the consumer references:
1. Check whether the **producer's** SKILL.md has instructions to generate that section
2. Don't just grep the target ecosystem — a term appearing in the executor doesn't mean the planner produces it

**Why grep-only checks fail:** Searching for a section name in the target repo and finding many references in the consumer made it look covered. But the producer had no instruction to produce that section — the producer/consumer contract was broken.

## Orchestrator/Agent Separation for Multi-Step Skills

Split SKILL.md into two files when a skill has a multi-step background workflow:

1. **Orchestrator (SKILL.md)** — User interaction only: identifying items, displaying for selection, gathering input. Target ~80 lines. No eager `@` references — list reference files as conditional (plain text).
2. **Background agent steps (separate .md)** — Autonomous workflow executed by a Task agent. Orchestrator reads the file and passes content via the Task tool's prompt parameter.

**Background steps file structure:**
- Aliases at top for repeated values (agent instructions, not shell variables)
- Decision tables for branching (markdown tables, not nested if/else prose)
- Inline warnings at point of use (not in a separate notes section)
- Error recovery at bottom (2-3 rules)

## AskUserQuestion Has a 4-Option Maximum

`AskUserQuestion` enforces `maxItems: 4` on the options array. This is a hard schema constraint — not configurable. Skills that present learnings, tasks, or choices to the user will fail at runtime if they try to offer >4 options.

**Workarounds (in order of preference):**
1. **Auto-save high-confidence items** — Remove them from the selection set entirely. Only prompt for uncertain items, which usually fit in 4 options.
2. **Group by theme** — Combine related items into a single option (e.g., "CI patterns (3 items)" instead of 3 separate options).
3. **Use free-text input** — Present a numbered table and let the user type "1,3,5" or "all" as a regular message instead of using the widget.
4. **Multi-round prompting** — Split into batches of 4, though this adds friction.

**Where this bites:** `/learnings:compound` when a session produces >4 learnings. The fix applied there: auto-save High-utility learnings (they're almost always worth keeping) and only prompt for Medium/Low.

## Avoid Internal Jargon in User-Facing Report Columns

Skill output templates (tables, summaries) should use language meaningful to someone unfamiliar with the skill's internal classification model. Column headers like "Why LOW" reference an internal confidence tier — readers unfamiliar with the HIGH/MEDIUM/LOW system interpret it as "low value" or "low priority." Use action-oriented labels instead (e.g., "Tradeoff" — explains what you'd give up by acting on the item).

## Skill-Reference File Placement

Files under `.claude/commands/` are automatically registered as invocable skills. To keep shared reference files referenceable without polluting the skill list, place them in `.claude/skill-reference/` instead — this directory is not scanned by the skill loader.

- `@~/.claude/skill-reference/<file>.md` for `@`-style includes
- `` `~/.claude/skill-reference/<file>.md` `` for bare path references

**When to use `skill-reference/` vs other locations:** Content that is behavioral/prescriptive AND applies to 3+ skills AND is only relevant during specific workflows (e.g., subagent launching). Too specialized for `guidelines/` (always-on cost), too actionable for `learnings/` (won't be loaded by skills).

## Preserve Reference Style During Migrations

When migrating file paths (e.g., relocating shared references), preserve each skill's original reference style rather than normalizing all references to a single style:

- If a skill used `@_shared/file.md` (auto-include directive), update to `@~/.claude/skill-reference/file.md`
- If a skill used `` `~/.claude/commands/.../file.md` `` (bare path in backticks), update to `` `~/.claude/skill-reference/file.md` ``

Adding `@` to files that previously used bare paths changes behavior (auto-include vs manual read instruction). Only update the path portion, not the reference mechanism.

## Absorb Thin Wrapper Skills as Flags

When pruning a skill that's a thin wrapper around a single command or a subset of a broader skill, absorb it as a `--flag` or mode in the broader skill rather than deleting the capability entirely. Example: `preview-conflicts` was step 3 of `resolve-conflicts` — absorbed as `resolve-conflicts --preview` (runs steps 1-3 only).

## Cross-Reference Cleanup After Skill Deletion

After deleting skills, grep remaining skills for the deleted skill names — other skills may reference them in "Related Skills" tables, usage examples, or conditional workflows. Stale references to non-existent skills confuse execution.

## Stale Model Version Strings in Co-Authorship Lines

Skills with `Co-Authored-By` or `Co-authored with` lines hardcode the model version (e.g., "Claude Opus 4.5"). These go stale on model upgrades. During curation sweeps, grep for the previous model version string across all skill directories and bulk-update.

## Curate Reference Files in Content Mode, Not Skill Mode

The curate skill's mode detection (`commands/*` → skill mode) is too coarse. Reference files under `commands/` (e.g., `writing-best-practices.md`, `classification-model.md`) are content files with discrete patterns — they need content mode (pattern-level analysis), not skill mode (package-level evaluation). Skill mode is only appropriate for SKILL.md files and their parent directories.

## Curate Skill Groups Together, Not Individually

When curating skills, evaluate the full group (e.g., all git skills) in one pass. Overlaps, merge opportunities, and thin wrapper candidates are only visible when comparing skills side by side. Individual evaluation misses cross-skill redundancy (e.g., preview-conflicts being a subset of resolve-conflicts).

## Pre-Load vs Deep Dive Signal Inconsistency in Curate

Curate's broad sweep pre-loads ALL skill directories including reference files (step 3 reads: "Read all files in each directory — don't pre-filter"). But the deep dive criteria include an action signal: "the target skill hasn't been read yet to verify coverage." This is contradictory — if the pre-load completed, the skill HAS been read. The signal should reference analysis depth, not read status. Fix: reframe to "broad sweep didn't verify per-pattern coverage against the skill's reference files."

## "Read" ≠ "Verified at Pattern Granularity"

Broad sweep cluster-level analysis loads files into context but checks thematic overlap across clusters, not line-by-line coverage against every reference file. Per-pattern verification (checking each H2/H3 against a specific reference file's content) is what deep dives do. The pre-load gives the *ability* to do per-pattern checks — whether the analysis *actually does* them depends on the sweep tier.

## Separate Orthogonal Dimensions in State Tracking

When a skill's scope expands along a new dimension (e.g., consolidate adding content types), track dimensions independently rather than creating combinatorial state values. `CONTENT_TYPE=SKILLS` + `PHASE=MEDIUM_BATCH` is cleaner than `PHASE=SKILL_MEDIUM_BATCH`. Each dimension changes independently and the loop logic stays generic across content types.

## Corpus Refresh at Content-Type Boundaries

When a multi-phase skill processes content types sequentially (learnings → skills → guidelines), re-read files modified by prior phases at each transition. This is lighter than a full corpus re-read but catches cross-type effects (e.g., a learning migrated into a skill reference file during the learnings phase affects the skill's evaluation). Track modified files via `CUMULATIVE_ACTIONS` targets.

## Context-Specific Guidance → skill-references, Not @-Referenced Guidelines

`@`-referenced guidelines load in every conversation regardless of task. If guidance only applies during code execution (not research, planning, or curation), it doesn't belong in an `@`-referenced file — even if it's only 8 lines. Place it in `skill-references/` and reference from each consuming skill. The content loads only when a relevant skill runs, paying zero tokens otherwise. Example: code quality self-review checklist is relevant to `do-refactor-code` and `parallel-plan:execute` but useless in research or curation sessions.

## "LLM Knows X" ≠ "LLM Consistently Applies X"

When deciding whether to codify a pattern, the question isn't "can the model execute this when asked?" but "does it reliably do so unprompted?" Textbook patterns (extract class, DRY, factories) that the model knows but doesn't consistently apply during implementation still warrant codification — as a lightweight checklist reminder, not a tutorial. The correct form factor is a slim reference file (~15 lines) that reminds, not a 229-line reference file that teaches.

## Stale Path References Are the Primary Skill Maintenance Issue

Skills referencing specific file paths (`~/.claude/lab/script.sh`, `docs/learnings/topic.md`) go stale when files are moved, deleted, or renamed. In curation of 4 skills, 2 had broken path references. During curation, verify every file path in SKILL.md and reference files actually resolves. Paths to external scripts and cross-directory references are more fragile than paths within the skill's own directory.

