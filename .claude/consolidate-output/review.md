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

## [L-1] "Iterative Testing for Timing-Dependent Autonomous Features" (LOW — possible migration)

- **Iter**: 5
- **Content Type**: LEARNINGS (deep dive)
- **File**: `.claude/learnings/multi-agent-patterns.md`
- **Pattern**: Iterative Testing for Timing-Dependent Autonomous Features
- **Possible classifications**: Standalone reference in multi-agent-patterns (current), migrate to testing-patterns.md (general testing principle)
- **Why LOW**: Pattern was learned in autonomous agent context and examples reference agent behavior, but the core principle (iterative live testing for timing-dependent features) is broader than multi-agent. Could fit either file.
- **Curate command**: `/learnings:curate learnings/multi-agent-patterns.md`

## [L-2] "Three-Branch Gate Announcements" (LOW — possible migration)

- **Iter**: 5
- **Content Type**: LEARNINGS (deep dive)
- **File**: `.claude/learnings/multi-agent-patterns.md`
- **Pattern**: Three-Branch Gate Announcements
- **Possible classifications**: Standalone reference in multi-agent-patterns (current), migrate to claude-authoring-learnings.md (learnings protocol design pattern)
- **Why LOW**: Pattern describes how learnings loading gates should have 3 announcement branches. It's about the learnings protocol design (gate observability), not agent orchestration per se. But it was learned in a multi-agent calibration context and applies to agents running gates.
- **Curate command**: `/learnings:curate learnings/multi-agent-patterns.md`
