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

## [MAX-DEEP-DIVES] (loop limit hit)

- **Details**: What remains unprocessed
- **Action needed**: Resume or manual curation

-->

## [L-1] corpus-cross-reference.md — Coverage Match Types taxonomy overlap with content-mode.md

- **Iter**: 14
- **Content Type**: DEEP_DIVE
- **File**: `.claude/skill-references/corpus-cross-reference.md`
- **Pattern**: Cross-Referencing Content → Coverage Match Types table (Exact/Partial/Thematic/No match)
- **Possible classifications**:
  1. STANDALONE REFERENCE (keep) — content-mode.md has its own version with different framing (maps to confidence levels, not implications); parallel development, not consumer duplication; adding reference would cost load overhead on every curation
  2. DEDUPLICATE — wire content-mode.md step 3 to reference this file's table; reduces taxonomy drift risk between the two sources
- **Why LOW**: content-mode.md is not a declared consumer, so the reference-file gate does not cleanly apply. The taxonomies serve similar but different purposes (one maps "implications," one maps to "confidence levels"). Unclear whether this is intentional parallel development or accidental divergence.
- **Curate command**: `/learnings:curate skill-references/corpus-cross-reference.md`

