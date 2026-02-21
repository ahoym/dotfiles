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

## Persona Scoping

Migrated to `compound-learnings/content-type-decisions.md` — see the "Guideline Scoping" table for the 4-scope model (always-on / conditional / persona / search-only).

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
