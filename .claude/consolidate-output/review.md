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

## [L-1] typescript-specific.md — very thin file (1 pattern)

- **Iter**: 1
- **Content Type**: LEARNINGS
- **File**: `typescript-specific.md`
- **Pattern**: Extending a Union Type Used in Record Keys
- **Why LOW**: Only 14 lines with a single pattern. Could grow naturally as TypeScript-specific patterns accumulate, or could be questioned if the pattern belongs in a broader TypeScript gotchas file. Not safe to auto-fold since the domain scope ("union types, Record keys, type narrowing") suggests planned growth.
- **Curate command**: `/learnings:curate typescript-specific.md`

## [L-2] quarkus-kotlin.md — very thin file (1 pattern)

- **Iter**: 1
- **Content Type**: LEARNINGS
- **File**: `quarkus-kotlin.md`
- **Pattern**: Enum changes require clean build in dev mode
- **Why LOW**: Only 8 lines with a single build gotcha. Quarkus work may be discontinued — if so, this file is a candidate for deprecation. If Quarkus is still active, the file will grow over time.
- **Curate command**: `/learnings:curate quarkus-kotlin.md`

## [L-3] xrpl-dex-data.md — native DEX section overlaps with xrpl-gotchas.md

- **Iter**: 1
- **Content Type**: LEARNINGS
- **File**: `xrpl-dex-data.md`
- **Pattern**: XRPL Native DEX section (lines 65+) — OfferCreate flags, funding rules, auto-bridging, tick size
- **Why LOW**: The native DEX section covers protocol-level DEX mechanics (flags, auto-bridging) that partially overlap with xrpl-gotchas.md (TakerGets/TakerPays semantics, funding rules). The unique value here is the fuller flags table and auto-bridging explanation. Could compress or cross-ref to reduce duplication without losing context. Needs human judgment on which file is authoritative.
- **Curate command**: `/learnings:curate xrpl-dex-data.md`

## [L-4] Cross-ref path inconsistency in learnings files

- **Iter**: 1
- **Content Type**: LEARNINGS
- **File**: Multiple
- **Pattern**: See Also path format varies: `~/.claude/learnings/foo.md` (gitlab-cli.md, ci-cd.md), bare `foo.md` (typescript-specific.md, ui-patterns.md), `.claude/learnings/foo.md` (aws-patterns.md — CWD-relative)
- **Why LOW**: No single standard is established. The `.claude/learnings/foo.md` format in aws-patterns.md is potentially problematic (CWD-relative may fail to resolve in some agent contexts). Should pick one convention and standardize. Human decision needed on which format to adopt globally.
- **Curate command**: `/learnings:curate aws-patterns.md` (start with the CWD-relative outlier)

## [L-5] python-specific.md — no matching Python persona

- **Iter**: 1
- **Content Type**: LEARNINGS
- **File**: `python-specific.md`
- **Pattern**: Pydantic v2 optional fields, TypedDict, env var conversion
- **Why LOW**: All other domain learnings files have at least one matching persona (Java, React, XRPL, Platform). `python-specific.md` has no Python persona. If Python work is recurring, a `python.md` persona would improve discoverability and load consistency. If Python is incidental, no persona needed.
- **Curate command**: `/learnings:curate python-specific.md`

## [L-6] skill-references consumer wiring unverified

- **Iter**: 2
- **Content Type**: SKILLS
- **File**: `~/.claude/skill-references/` (all files)
- **Pattern**: Consumer wiring check — verifying each skill-reference is referenced by at least one skill
- **Why LOW**: The `.claude/skill-references/` directory is a symlink — Glob can't traverse it in the worktree. The spec requires a consumer wiring check (unused skill-references are dead weight — HIGH delete candidate), but it couldn't be executed. Files verified as referenced in skills: `subagent-patterns.md`, `code-quality-checklist.md`, `agent-prompting.md`, `platform-detection.md`, `request-interaction-base.md`, `corpus-cross-reference.md`, and platform cluster files. Manual check recommended: `ls ~/.claude/skill-references/` to ensure no orphaned files.
- **Curate command**: n/a — run `ls ~/.claude/skill-references/` to verify

## [L-7] learnings:consolidate vs autonomous wiggum.sh — parallel consolidation approaches

- **Iter**: 2
- **Content Type**: SKILLS
- **File**: `learnings/consolidate/SKILL.md`
- **Pattern**: Two consolidation workflows — interactive (`/learnings:consolidate` via AskUserQuestion within a single conversation) and autonomous (wiggum.sh loop, multi-invocation, worktree-based)
- **Why LOW**: Both exist and serve different use cases (interactive vs autonomous). The `learnings:consolidate` SKILL.md is not referenced by ralph:consolidate (which uses wiggum.sh directly). Is learnings:consolidate still actively used? If it's a backup/manual fallback, keep it. If the wiggum.sh path has fully superseded it, it could be pruned. Human judgment needed.
- **Curate command**: `/learnings:curate learnings/consolidate`

## [L-8] communication.md — compression opportunity (verbose sub-sections)

- **Iter**: 3
- **Content Type**: GUIDELINES
- **File**: `.claude/guidelines/communication.md`
- **Pattern**: Multiple sub-sections are verbose (e.g., "Stress-test negative conclusions from empirical tests" 3-point checklist, "Calibrate challenge intensity to session phase", several "Autonomy during execution" sub-bullets)
- **Possible classifications**: Compression (auto-apply MEDIUM) vs leave as-is
- **Why LOW**: File is ~180 lines of always-on context. Each sub-section carries distinct behavioral nuance — compression risks losing precision in rules designed to be unambiguous. Cannot assess acceptable compression boundaries without human judgment on which nuances are load-bearing vs redundant with adjacent rules.
- **Curate command**: `/learnings:curate communication.md`

## [L-10] extract-request-learnings/SKILL.md — $PLAN_FILENAME convention undefined

- **Iter**: 15
- **Content Type**: SKILLS
- **File**: `.claude/commands/extract-request-learnings/SKILL.md`
- **Pattern**: Continue mode step 3 says "Read the plan file (`docs/plans/$PLAN_FILENAME`)" — but `$PLAN_FILENAME` is never defined in the skill. Init mode step 4 says "Create plan file at `docs/plans/$PLAN_FILENAME`" — but the naming convention isn't specified.
- **Possible classifications**: (1) Define `$PLAN_FILENAME` as a derived value (e.g., `<repo-name>-review-learnings.md`) in init mode and state it explicitly; (2) Use a glob in continue mode (`docs/plans/*.md`) as the lookup; (3) Leave as-is (implied by context — operators likely understand to use the repo name)
- **Why LOW**: Not a functional blocker (a single plan file per repo means glob works as workaround), but it's an implicit convention that could confuse an operator running this skill in a repo with multiple plan files. Human judgment on whether to formalize.
- **Curate command**: `/learnings:curate commands/extract-request-learnings`

## [L-9] context-aware-learnings.md — large always-on methodology file

- **Iter**: 3
- **Content Type**: GUIDELINES
- **File**: `.claude/guidelines/context-aware-learnings.md`
- **Pattern**: ~130 lines always-on context; file is structured as a methodology reference (pipeline steps, announcement formats, gate details) rather than a short behavioral rule
- **Possible classifications**: Extract methodology details to skill-reference + keep short behavioral rule in guideline vs leave as-is
- **Why LOW**: Restructuring is blocked — session-start hard gate fires before the first tool call. If details were in a skill-reference, they'd only load during skill invocation, missing the session-start gate entirely. File cannot be shortened without breaking the search protocol. Flag for monitoring: if file grows significantly, reconsider whether the index-based loading section could reference a separate detail file loaded via @-ref.
- **Curate command**: n/a — structural constraint, not a content issue
