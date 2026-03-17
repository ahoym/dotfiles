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

## [L-3] `--name-only` flag contradiction (LOW — needs verification)

- **Iter**: 14
- **Content Type**: LEARNINGS (deep dive)
- **File**: `.claude/learnings/gitlab-cli.md` vs `.claude/skill-references/gitlab/fetch-review-data.md`
- **Pattern**: `glab mr diff --name-only` existence
- **Possible classifications**: gitlab-cli.md is correct (no flag, workaround needed) OR fetch-review-data.md is correct (flag exists)
- **Why LOW**: Direct contradiction between learning and skill-reference. gitlab-cli.md L14 says "`glab mr diff` has no `--name-only` flag" and provides a workaround. fetch-review-data.md L34 shows `glab mr diff <number> --name-only` as a valid command. Cannot resolve without testing `glab mr diff --name-only` against a real MR.
- **Curate command**: `/learnings:curate learnings/gitlab-cli.md`
