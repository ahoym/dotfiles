# Human Review Items

Items the autonomous agent couldn't or shouldn't resolve alone. Surfaced during `/ralph:consolidate:resume`.

**How to use**: Run `/learnings:curate <file>` on specific files listed below to review and decide interactively.

<!-- Each item follows one of these formats, tagged by origin:

## [L-N] Title (LOW — ambiguous classification)

- **Iter**: Iteration number when found
- **Content Type**: LEARNINGS | SKILLS | GUIDELINES
- **File**: Source file path
- **Pattern**: Section/pattern name
- **Possible classifications**: What it could be (with rationale for each)
- **Why LOW**: Why autonomous judgment wasn't sufficient
- **Curate command**: `/learnings:curate <file>`

## [BM-N] Title (BLOCKED-MED — needs human decision)

- **Iter**: Iteration number when found
- **Content Type**: LEARNINGS | SKILLS | GUIDELINES
- **Action**: What was proposed
- **Source**: Where the content lives
- **Target**: Where it would go
- **Why blocked**: Why autonomous judgment wasn't sufficient
- **Options**:
  1. Option A — description
  2. Option B — description
  3. Skip — leave as-is
- **Curate command**: `/learnings:curate <file>`

## [MAX-ROUNDS] / [MAX-DEEP-DIVES] (loop limit hit)

- **Details**: What remains unprocessed
- **Action needed**: Resume or manual curation

-->

## [L-1] Stale transition note in cross-repo-sync.md (LOW)

- **Iter**: 1
- **Content Type**: LEARNINGS
- **File**: `.claude/learnings/cross-repo-sync.md`
- **Pattern**: Line 5 — "Old `-pr`/`-mr` variants still exist during transition — delete after testing confirms the unified versions work."
- **Possible classifications**: The old PR/MR-named skill variants appear to have been fully replaced by unified `-request` names. The note is stale. Options: (a) remove the sentence, (b) update to past tense "Old variants have been replaced by unified names."
- **Why LOW**: Can't definitively verify from learnings alone whether any consuming project still references the old names.
- **Curate command**: `/learnings:curate learnings/cross-repo-sync.md`

## [L-2] ~~Duplicate "structured footnotes" pattern across files~~ RESOLVED (Iter 8)

Resolved by deep dive: skills version compressed to pointer referencing process-conventions.md, keeping the unique composite-key filtering instruction. Template lives in process-conventions (single source of truth), skill instruction points there.

## [L-3] "Worktree Branches Block `gh pr checkout`" placement (LOW)

- **Iter**: 8
- **Content Type**: DEEP_DIVE (claude-authoring-skills.md)
- **File**: `.claude/learnings/claude-authoring-skills.md`
- **Pattern**: "Worktree Branches Block `gh pr checkout`" — describes `gh pr checkout` failing when branch is in a worktree.
- **Possible classifications**: (a) Keep in skills — it's about how skills should detect and handle worktrees. (b) Migrate to `claude-code.md` — it's a platform/CLI gotcha. (c) Duplicate in both as a cross-ref.
- **Why LOW**: Straddles skill design instruction (how to handle it) and platform gotcha (why it happens). Both framings are valid.
- **Curate command**: `/learnings:curate learnings/claude-authoring-skills.md`
