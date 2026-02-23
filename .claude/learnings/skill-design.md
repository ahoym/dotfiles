# Skill Design Patterns

## Gap vs Inconsistency Boundary

When a skill categorizes findings into "gaps" and "inconsistencies," define them with a non-overlapping boundary:
- **Gap** — Code has a pattern/feature completely absent from docs
- **Inconsistency** — Docs exist but contradict the code

In skill instructions, add a preamble to each category excluding the other: "Do NOT include items where docs exist but contradict the code; those belong in inconsistencies."

## Skills Should Self-Document Permission Needs

Add a `## Prerequisites` section to SKILL.md with a JSON snippet of exact `permissions.allow` patterns. Users shouldn't reverse-engineer permissions through trial and error.

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

When curating a skill, compare its reference files against companion skills — especially producer/consumer pairs. Duplicated reference files diverge silently.

**Detection:** Check for >80% content overlap with related skills' reference files. The superset version is usually in the skill that uses the content more heavily.

**Resolution:** Move the superset to `skill-reference/` and update both skills to reference the shared path.

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

When two skills form a producer/consumer pair, validate that the producer generates every section the consumer expects. For each section the consumer references, check whether the **producer's** SKILL.md has instructions to generate it — a term appearing in the executor doesn't mean the planner produces it.

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

## "LLM Knows X" ≠ "LLM Consistently Applies X"

When deciding whether to codify a pattern, the question isn't "can the model execute this when asked?" but "does it reliably do so unprompted?" Textbook patterns (extract class, DRY, factories) that the model knows but doesn't consistently apply during implementation still warrant codification — as a lightweight checklist reminder, not a tutorial. The correct form factor is a slim reference file (~15 lines) that reminds, not a 229-line reference file that teaches.

## Stale Path References Are the Primary Skill Maintenance Issue

Skills referencing specific file paths (`~/.claude/lab/script.sh`, `docs/learnings/topic.md`) go stale when files are moved, deleted, or renamed. In curation of 4 skills, 2 had broken path references. During curation, verify every file path in SKILL.md and reference files actually resolves. Paths to external scripts and cross-directory references are more fragile than paths within the skill's own directory.

## Skills Sweep: Parallel Subagent Summarization

When evaluating 20+ skills in a consolidation sweep, use parallel Explore subagents (clustered by namespace) to read and summarize each skill package — purpose, line count, reference files, cross-references, stale paths. Evaluate from summaries in the main context rather than reading all SKILL.md files directly. This avoids blowing the context window on full-file reads while preserving enough detail for overlap detection and classification. Follow up with targeted Grep checks for cross-cutting issues (co-authorship versions, stale references, deleted skill names).
