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

## [L-2] Duplicate "structured footnotes" pattern across files (LOW)

- **Iter**: 1
- **Content Type**: LEARNINGS
- **File**: `.claude/learnings/process-conventions.md` (lines 130-138) AND `.claude/learnings/claude-authoring-skills.md` (lines 411-426)
- **Pattern**: Both describe the `Persona + Role` structured footnote pattern for multi-agent comment identity.
- **Possible classifications**: (a) process-conventions version is about *when* to use footnotes (process), skills version is about *how to implement* them (skill design) — keep both as different angles. (b) Merge into one location with a cross-reference from the other. (c) Extract to a shared reference since it serves both review process and skill implementation.
- **Why LOW**: The content is genuinely useful in both locations for different audiences (process thinkers vs skill builders). Removing either risks losing discoverability for that audience.
- **Curate command**: `/learnings:curate learnings/process-conventions.md learnings/claude-authoring-skills.md`
