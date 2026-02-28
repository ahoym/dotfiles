# Blockers

Items that require human review before proceeding. These are surfaced during `/ralph:consolidate:resume` for morning review.

<!-- Each blocker follows this format:

## [B-N] Title

- **Content Type**: LEARNINGS | SKILLS | GUIDELINES
- **Action**: What was proposed
- **Source**: Where the content lives
- **Target**: Where it would go
- **Why blocked**: Why autonomous judgment wasn't sufficient
- **Options**:
  1. Option A — description
  2. Option B — description
  3. Skip — leave as-is

**Status**: OPEN | RESOLVED (decision)

-->

## [B-1] Unreferenced guideline: validation.md

- **Content Type**: GUIDELINES
- **Action**: Wire `validation.md` into CLAUDE.md via `@` reference, or decide its fate
- **Source**: `.claude/guidelines/validation.md` (12 lines, 2 patterns)
- **Target**: CLAUDE.md `@`-reference section
- **Why blocked**: CLAUDE.md is outside `.claude/` write scope — can't modify it autonomously. Whether to add always-on context cost is preference-dependent.
- **Options**:
  1. Add `@.claude/guidelines/validation.md` to CLAUDE.md — makes it always-on (only 12 lines, minimal cost)
  2. Delete `validation.md` — patterns are generic enough that models may follow them unprompted
  3. Move content into an existing learning file (e.g., `skill-design.md` which already has "Validate Factual Claims" section) — changes content type but makes it conditionally loadable
  4. Skip — leave as unreferenced dead weight

**Status**: RESOLVED (Option 3 — folded content into `learnings/skill-design.md` under new "Validate Means Run It" section, deleted `guidelines/validation.md`)
