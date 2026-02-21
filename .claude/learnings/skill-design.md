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
