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

## [L-1] git-patterns.md missing See also section (LOW)

- **Iter**: 11
- **Content Type**: DEEP_DIVE
- **File**: `.claude/learnings/git-patterns.md`
- **Pattern**: Cross-reference discoverability
- **Possible classifications**: bash-patterns.md already has reverse cross-ref → bidirectional linking would be marginally useful
- **Why LOW**: Reverse link already exists in bash-patterns.md; adding forward link is a net-positive but not required for discoverability
- **Curate command**: `/learnings:curate git-patterns.md`

## [L-2] java-backend persona missing references to java-infosec/observability files (LOW)

- **Iter**: 12
- **Content Type**: DEEP_DIVE
- **File**: `.claude/commands/set-persona/java-backend.md`
- **Pattern**: Missing detailed references to java-infosec-gotchas.md, java-observability-gotchas.md, java-observability.md
- **Possible classifications**: Add as detailed references (increases persona token cost) vs rely on keyword discovery (`java-*` naming convention is reliable)
- **Why LOW**: Both approaches are valid. Keyword discovery via `java-*` naming is reliable for the learnings search protocol. Adding references increases always-loaded persona size for marginal discoverability gain.
- **Curate command**: `/learnings:curate commands/set-persona/java-backend.md`
