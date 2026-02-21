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

**Good example:** `compound-learnings` includes a Prerequisites section with all required Read/Write/Edit patterns for `~/.claude/` subdirectories.

**Discovered from:** Debugging why `/curate-learnings` kept prompting for Glob permissions — the skill had no documentation of what permissions it needed, and the correct syntax (`Read()` not `Glob()`) was non-obvious.

## Project-Specific Learnings Become Redundant After explore-repo

When `/explore-repo` has been run on a project and generated a comprehensive project CLAUDE.md, check whether any global learnings (in `~/.claude/learnings/`) about that same project are now redundant.

**Pattern:** During `/curate-learnings`, for any learning file named after a specific project (e.g., `payment-service-setup.md`):
1. Check if the project has a CLAUDE.md generated by `/explore-repo`
2. Compare each learning pattern against the project CLAUDE.md content
3. If 80%+ of patterns are already covered → delete the global learning, add any missing bits to the project CLAUDE.md
4. If <80% covered → keep the global learning but flag overlapping patterns for removal

**Why this happens:** Learnings about a project are often captured early (during onboarding or debugging), before `/explore-repo` creates comprehensive project documentation. The explore-repo output then supersedes most of those early learnings.

**Discovered from:** Curating a project-specific bootstrap learning file — 4 of 5 patterns were already in the project's CLAUDE.md, which had been generated by `/explore-repo` after the learnings were written.

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

## Guideline vs Reference File Placement

Content that is only relevant during a specific skill's execution should be a **reference file inside that skill directory**, not an always-on guideline.

**Decision criteria:**
- Is this needed in every conversation? → **Guideline** (always loaded into context)
- Is this only needed when a specific skill runs? → **Reference file** (loaded conditionally, zero context cost otherwise)

**Why it matters:** Guidelines consume context window in every session. A 50-line guideline about persona structure wastes tokens in 95% of conversations where no persona work happens. As a reference file, it's only loaded when `/curate-learnings` detects a persona opportunity.

**Pattern:** If you create a guideline and realize it's only referenced by one skill, move it to that skill's directory and add it to the skill's "Reference Files (conditional)" list.

**Discovered from:** Created `~/.claude/guidelines/persona-design.md`, then immediately realized it was only relevant during `/curate-learnings` persona detection — moved it to `commands/curate-learnings/persona-design.md`.

## Persona-Aware Curation and Compounding

Both `/curate-learnings` and `/compound-learnings` should be persona-aware:

- **Curate-learnings** (implemented in step 5a): detects when learnings cluster around a domain/stack without a matching persona, suggests creating one. Also detects learnings that belong in an existing persona's gotchas or review checks.
- **Compound-learnings** (not yet implemented): when saving a new learning, should check if it matches an existing persona's domain and offer to fold it into the persona alongside (or instead of) a learnings file.

**Why both skills:** `/curate-learnings` finds persona opportunities in *existing* content (batch). `/compound-learnings` catches them at *creation time* (incremental). Together they ensure personas stay current without manual review.

## Broad Sweep Curation: Cluster-First Approach

When curating all learnings files at once (broad sweep), don't classify all ~50 patterns individually — it's too verbose and most are "standalone reference / keep."

**Pattern:**
1. Cluster files by domain/stack (XRPL+TS, Java+Spring, Python, Meta/tooling)
2. Check each cluster against existing personas for enhancement opportunities
3. Report a summary table of clusters with pattern counts and persona status
4. Only classify individual patterns when they need action (outdated, migrate, enhance persona)
5. Skip meta/tooling clusters for persona analysis (per persona-design.md criteria)

**Output structure:** Cluster table → Persona suggestions table → Highlights-only pattern table → Recommended actions. This keeps the report scannable even with 17 files.

## Thin Pointer Files: Fold and Delete

During curation, files under ~20 lines that primarily point to other files (e.g., "see X persona" and "see Y learning") should be folded into the target and deleted.

**Detection criteria:**
- File is < 20 lines
- More than half the content is cross-references or "see also" pointers
- The substantive content (if any) fits naturally in an existing persona or skill

**Why delete:** Each file adds to the cognitive load of "what's in my learnings?" without adding standalone value. If the content is just routing, the target should contain it directly.

**Example:** `observability-workflow.md` (14 lines) was mostly "see java-devops persona" and "see spring-patterns.md" — the 6-step process folded into java-devops persona's gotchas section, file deleted.

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

**Example:** After running `/curate-learnings` broad sweep, identified 5 improvements. Ranked them: broad sweep mode (#1, prevents quality regression) >> persona enhancement guidance (#5, one-line fix) > whole-file deletion (#4, small gap) >> thin pointer detection (#2, minor efficiency) = genericize action (#3, rare). Applied top 3.

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

**Discovered from:** Designing `/consolidate-learnings` as a multi-sweep orchestrator around `/curate-learnings`.

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
