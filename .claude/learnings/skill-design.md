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

**Discovered from:** First run of `/explore-repo` — the same 4 critical items appeared in both SYSTEM_OVERVIEW.md's gaps section and inconsistencies.md.

## Exploration Skills Should Default to Report-Only

Skills that analyze, explore, or audit a codebase should produce reports but NOT offer to apply fixes or edit documentation.

**Why:**
- Separating "understand" from "fix" keeps each phase focused
- Applying fixes requires different confirmation and review than reading a report
- Users may want to review findings before deciding what to act on, in a separate session
- Report-only skills are simpler to build and test — no edit logic, no conflict handling
- The user can always ask for fixes in a follow-up interaction with the report as context

**Pattern:**
- Skill produces output files (e.g., `SYSTEM_OVERVIEW.md`, `inconsistencies.md`)
- Skill prints a console summary with key metrics
- Skill ends — no `AskUserQuestion` for "which fixes to apply"
- If the user wants fixes, they initiate that as a separate task

## Stateful Mode Detection via File Existence

A single skill can operate in different modes across invocations by checking what output files already exist on disk, rather than requiring separate skills for each phase.

**Pattern:**
1. On invocation, glob for expected output files
2. For each file found, read its metadata header (commit hash, date) to check staleness
3. Determine mode based on file state:
   - Missing files → run the scan/generation phase for those files
   - All files present, no synthesized output → run synthesis
   - All present + synthesized, but stale → re-scan stale files
   - Everything current → nothing to do

**Benefits:**
- One command to remember (`/explore-repo`), not two (`/explore-repo` + `/synthesize-repo`)
- Each invocation is a fresh context (solves the context window pressure problem)
- Natural checkpoint between phases — user can inspect intermediate files before synthesis
- Graceful degradation: if 3 of 7 agents fail, next run picks up only the missing 3
- Supports incremental updates — only re-scans domains whose source has changed

**Key detail:** Staleness is determined by comparing the `commit` field in the file's metadata header against `git rev-parse --short HEAD`. Coarse-grained (any new commits = re-scan) for v1, fine-grained (only re-scan changed domains) as future enhancement.

**Discovered from:** Redesigning `/explore-repo` — needed a way to split scan and synthesis across separate invocations without requiring the user to learn two different commands.

## Skills Should Self-Document Permission Needs

Skills that read or write files outside the project directory should include a **Prerequisites** section listing the exact `permissions.allow` patterns needed for prompt-free execution.

**Why:**
- Users shouldn't have to reverse-engineer which permissions a skill needs through trial and error
- Permission rule syntax is non-obvious (e.g., `Read()` covers Glob/Grep, not `Glob()` or `Search()`)
- A prerequisites section serves as both documentation and a copy-paste config block

**Pattern:** Add a `## Prerequisites` section to SKILL.md with a JSON snippet:
```markdown
## Prerequisites

For prompt-free execution, add these allow patterns to `~/.claude/settings.json`:

\```json
"Read(~/.claude/learnings/**)",
"Edit(~/.claude/learnings/**)"
\```
```

**Good example:** `learnings:compound` includes a Prerequisites section with all required Read/Write/Edit patterns for `~/.claude/` subdirectories.

**Discovered from:** Debugging why `/learnings:curate` kept prompting for Glob permissions — the skill had no documentation of what permissions it needed, and the correct syntax (`Read()` not `Glob()`) was non-obvious.

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

**Example:** `parallel-plan/make/prompt-writing-guide.md` (180 lines) and `parallel-plan/execute/agent-prompting.md` (208 lines) covered ~90% identical content (prompt structure, fast/slow agents, TDD workflow, landmarks, boundaries). The executor's version was a superset (added model selection, shared contract sections). Consolidated into `_shared/agent-prompting.md`.

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

**Example:** After running `/learnings:curate` broad sweep, identified 5 improvements. Ranked them: broad sweep mode (#1, prevents quality regression) >> persona enhancement guidance (#5, one-line fix) > whole-file deletion (#4, small gap) >> thin pointer detection (#2, minor efficiency) = genericize action (#3, rare). Applied top 3.

## Skill Orchestration: Wrapper Skills That Delegate Methodology

A wrapper skill can orchestrate another skill by reading its SKILL.md at step 0 and following its methodology, while overriding specific steps (e.g., the approval flow). This avoids duplicating domain knowledge — classification models, reference files, and analysis logic stay in one place.

**Pattern:**
1. Wrapper skill's Step 0: "Read `../inner-skill/SKILL.md` to internalize the analysis methodology"
2. Wrapper follows the inner skill's analysis steps (e.g., steps 1-6) for each iteration
3. Wrapper replaces the inner skill's interaction step (e.g., step 7 approval) with its own logic (e.g., auto-apply loop)
4. Wrapper references inner skill's reference files by path — no copies

**Benefits:**
- Single source of truth for domain knowledge (classification model, persona design, etc.)
- Changes to the inner skill automatically flow through to the wrapper
- Wrapper stays lean — pure orchestration logic, no duplicated analysis instructions
- Clear separation: inner skill owns "how to analyze," wrapper owns "when to apply"

**Discovered from:** Designing `/learnings:consolidate` as a multi-sweep orchestrator around `/learnings:curate`.

## Confidence-Tiered Loop Design

When an iterative skill produces recommendations at different confidence levels, use confidence tiers to determine automation level in each loop phase:

**Pattern:**
1. **Phase 1 (HIGH loop):** Auto-apply HIGH-confidence items → re-analyze → repeat until none remain
2. **Phase 2 (MEDIUM batch):** Present remaining MEDIUMs as a single batch for user approval (fresh analysis, not accumulated)
3. **Phase 3 (Verification):** Re-analyze after user-approved changes → if new HIGHs surface, cycle back to Phase 1; if new MEDIUMs, back to Phase 2; if clean, done

**Why this ordering works:**
- HIGHs are safe to auto-apply by definition (classification criteria say "apply without additional verification")
- Burning through HIGHs first changes the landscape — some MEDIUMs will resolve as side effects
- The MEDIUM batch after HIGHs gives an accurate picture of what actually needs human judgment
- Post-MEDIUM verification catches cascading effects (approved changes may surface new patterns)

**Generalizable to:** Any iterative skill with confidence-rated recommendations — code review fixups, dependency upgrades, migration tasks, etc.

## Fresh Analysis Beats Accumulation in Iterative Loops

When looping through analyze-apply cycles, re-analyze from scratch after each round of changes rather than accumulating findings across iterations.

**Why:**
- Each applied action changes the state — folding content, deleting files, enhancing personas
- An earlier MEDIUM assessment may become moot (resolved as side effect of a HIGH action)
- An earlier "keep" may become a new HIGH (content is now partially redundant after a merge)
- Stale accumulated findings lead to incorrect batch presentations and wasted user attention

**Pattern:** At each phase transition (e.g., "HIGHs exhausted, now show MEDIUMs"), run a fresh full analysis of current state. The MEDIUM batch should reflect the world *after* all HIGH actions, not a union of assessments from earlier sweeps.

**Counterintuitive aspect:** It feels wasteful to re-analyze everything when you "already know" the MEDIUMs. But the cost of a fresh sweep is low (minutes), while the cost of presenting stale recommendations is high (user approves something that's no longer relevant, or misses something new).

## Dual Safety Caps for Nested Loops

Iterative skills with nested loop structures need two layers of safety caps:

**Pattern:**
- **Per-phase cap** (e.g., 5 iterations): Prevents the inner loop from running away. When hit, offer an escape hatch that moves to the next phase rather than just stopping (e.g., "downgrade remaining HIGHs to MEDIUMs for human review").
- **Overall cap** (e.g., 10 total iterations): Prevents the outer cycle (Phase 1 → Phase 2 → Phase 3 → Phase 1...) from looping indefinitely. When hit, pause and show current state with option to continue or stop.

**Why both caps:**
- Per-phase cap alone doesn't prevent the Phase 1→2→3→1 cycle from repeating forever
- Overall cap alone allows one phase to consume all iterations (5 HIGH sweeps, 5 MEDIUM batches = cap hit without ever verifying)
- The escape hatch (downgrading persistent HIGHs) acknowledges that cascading recommendations may benefit from human judgment rather than more automation

**Extends:** `iterative-loop-design.md` expansion/contraction pattern — adds structured termination for confidence-tiered loops.

## Permission Patterns Must Match Invocation Paths

Bash permission patterns in `settings.json` use literal string matching. If a pattern uses `~` (e.g., `Bash(bash ~/.claude/commands/**)`), the invocation must also use `~` — not the expanded `/Users/<user>/.claude/commands/...` path.

**Why this matters:** Skills with inventory scripts or helper commands that are invoked via Bash need consistent path conventions between the permission pattern and the actual command.

**Pattern:** Always use `~` in both:
- The permission pattern: `Bash(bash ~/.claude/commands/**)`
- The invocation: `bash ~/.claude/commands/quantum-tunnel-claudes/inventory.sh ...`

**Discovered from:** quantum-tunnel-claudes inventory script was being prompted for permission despite having a matching allow pattern, because the invocation used the fully expanded path.

## Diff Excerpts Hide Structural Gaps

When comparing diverged files between repos, line-level diff output (`diff | grep '^> ' | head -30`) shows textual differences but hides structural ones. Missing sections, instruction steps, or format rules are invisible in diff excerpts — you need to read both full files to see document shape.

**Threshold:** If a file has >15 source-unique lines, read both versions in full. Below that threshold, diff excerpts + targeted grep are sufficient.

**Why 15 lines:** Below 15, the diffs are typically terminology swaps or minor additions visible in the excerpt. Above 15, there's enough unique content that structural differences (new sections, reordered steps, missing format rules) become plausible.

**Discovered from:** quantum-tunnel-claudes missed that `parallel-plan/make/SKILL.md` was missing a Branch Strategy section — the diff showed "MR" references which led to batch-dismissing the entire file as terminology changes.

## Producer/Consumer Contract Validation

When two skills form a producer/consumer pair (e.g., `parallel-plan:make` produces plans that `parallel-plan:execute` consumes), validate that the producer knows how to generate every section the consumer expects.

**Pattern:** For each section the consumer references:
1. Check whether the **producer's** SKILL.md has instructions to generate that section
2. Don't just grep the target ecosystem — "Branch Strategy" appearing in the executor doesn't mean the planner produces it

**Why grep-only checks fail:** Searching for "Branch Strategy" in the target repo and finding 9+ references in `parallel-plan:execute` made it look like the concept was covered. But the planner (`parallel-plan:make`) had no instruction to produce Branch Strategy sections — the producer/consumer contract was broken.

**Discovered from:** quantum-tunnel-claudes missed this gap because the analysis used grep to check coverage rather than reading both the producer and consumer skills.

## _shared Files Need "Not Invoked Directly" Frontmatter

Files in `commands/_shared/` are internal reference docs, not standalone skills. But Claude Code treats any `.md` file in `commands/` as an invocable skill and lists it in the system-reminder. Without frontmatter, they show up with just their heading text (e.g., "Platform Detection"), giving agents no signal that they shouldn't be invoked.

**Fix:** Add frontmatter with a description that starts with "Internal reference —" and ends with "Used by other skills, not invoked directly."

**Example:**
```yaml
---
description: "Internal reference — GitHub vs GitLab detection logic. Used by git skills, not invoked directly."
---
```

**Discovered from:** Frontmatter audit — agents were seeing `_shared:platform-detection: Platform Detection` in the skill list with no indication it was a reference doc.

## Disambiguation Cross-References Between Similar Skills

When two skills serve related but distinct purposes, the lower-level skill's description should cross-reference the higher-level one. This gives agents a clear routing rule without requiring trigger phrases.

**Pattern:** Add a single sentence at the end of the description pointing to the alternative:
- `learnings:curate`: "...For exhaustive multi-sweep curation, use learnings:consolidate instead."
- `learnings:consolidate`: "...Orchestrates repeated learnings:curate sweeps."

**Why this works better than trigger phrases:** An agent reading "For exhaustive multi-sweep, use consolidate instead" gets an unambiguous routing rule. Trigger phrases like "Use when the user says 'deep clean'" require the agent to pattern-match against user phrasing, which is less reliable.

**When to apply:** Any time two skills in the same domain could plausibly match the same user request. The cross-reference should clarify the relationship (wrapper vs inner, single-pass vs multi-pass, preview vs execute).

## Consolidation Tuning Insights

- Between-sweep reports work well for visibility during iterative consolidation runs
- `AskUserQuestion` multi-select is limited to 4 options — consolidation runs with many MEDIUM items need grouped choices or a different presentation strategy
- Post-run review caught two systemic issues that became content principles in `content-type-decisions.md`: genericizing tool-specific references, and no TODOs/feature requests in context files
- **Cadence signal:** A second consolidation run on a recently-curated collection yielded 0 HIGHs and only 2 minor MEDIUMs (misplaced persona content, stale execution log). Consolidation has diminishing returns when run shortly after a clean first run — use `/learnings:curate <file>` for targeted cleanup between full consolidation sweeps

## Scope _shared/ Files to Their Skill Group

When a `_shared/` reference file is only used by skills within a single group, it should live in that group's `_shared/` directory rather than the global `commands/_shared/`. Only truly cross-group references belong in global `_shared/`.

**Decision criteria:** Grep for all references to the shared file. If every reference is within a single skill group → move it into `<group>/_shared/`. If references span multiple groups or standalone skills → keep in global `_shared/`.

**Example:**
- `platform-detection.md` — referenced by 9 git skills only → moved to `git/_shared/`
- `agent-prompting.md` — referenced by 2 parallel-plan skills only → moved to `parallel-plan/_shared/`
- `corpus-cross-reference.md` — referenced by `learnings:curate` + `quantum-tunnel-claudes` → stays in global `_shared/`

**Benefits:**
- Collocates reference docs with the skills that use them
- Makes it obvious which group "owns" the content
- Reduces the global `_shared/` to genuinely cross-cutting references
- Reference paths become shorter (e.g., `@_shared/platform-detection.md` instead of `@../_shared/platform-detection.md`)

## Group _shared/ Files Are Discovered as Skills

When `_shared/` directories are placed inside skill groups (e.g., `git/_shared/`), their `.md` files are discovered by Claude Code as invocable subskills (e.g., `git:_shared:platform-detection`). The frontmatter "Internal reference — ... not invoked directly" mitigates this by signaling to agents that the file shouldn't be used as a command, but it still appears in the skill list.

**Implication:** This is a cosmetic issue, not a functional one. Agents see the "not invoked directly" description and route correctly. But the skill list gets slightly noisier with internal reference entries.

**Discovered from:** After moving `platform-detection.md` to `git/_shared/` and `agent-prompting.md` to `parallel-plan/_shared/`, both appeared in the system-reminder skill list as `git:_shared:platform-detection` and `parallel-plan:_shared:agent-prompting`.
