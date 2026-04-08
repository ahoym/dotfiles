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

## [BM-1] context-aware-learnings.md missing from CLAUDE.md (BLOCKED-MED — needs human decision)

- **Iter**: 3
- **Content Type**: GUIDELINES
- **Action**: Wire `guidelines/context-aware-learnings.md` into `CLAUDE.md`
- **Source**: `claude/guidelines/context-aware-learnings.md` (55 lines, learnings search protocol with 6 mandatory gates)
- **Target**: `claude/CLAUDE.md` — either @-reference or procedural table entry
- **Why blocked**: Context cost tradeoff. The learnings corpus (`claude-authoring/guidelines.md:87`) explicitly says this file is behavioral (session-start gate fires before first tool call) and should be @-referenced. But 55 lines of always-on context is significant. Multiple valid approaches.
- **Options**:
  1. @-reference (always-on) — guarantees gates fire from session start, adds 55 lines context cost
  2. Procedural table entry — "When searching for learnings or at session start" — saves context but chicken-and-egg: agent won't know to load it if it doesn't know about session-start gate
  3. Inline a 2-3 line summary in CLAUDE.md (e.g., "Search learnings at session start — see guidelines/context-aware-learnings.md for protocol") + add to procedural table — hybrid approach, minimal cost but may lose gate detail
  4. Skip — leave as-is, accept that the file has no CLAUDE.md delivery mechanism
- **Curate command**: `/learnings:curate claude/guidelines/context-aware-learnings.md`
