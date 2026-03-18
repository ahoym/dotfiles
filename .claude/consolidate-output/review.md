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
- **Status**: RESOLVED (keep as-is — different purposes, drift caught by future deep dives)

## [L-2] github/commands.md — fetch-review-data.md index description omits consolidated variants

- **Iter**: 19
- **Content Type**: DEEP_DIVE
- **File**: `.claude/skill-references/github/commands.md`
- **Pattern**: Index table — fetch-review-data.md description
- **Possible classifications**:
  1. KEEP as-is — "Fetch Activity Signals" and "Fetch Review Details with Reviews" are consolidation variants of existing operations, not separate command categories; the index description is a summary, not exhaustive
  2. UPDATE — add the consolidated variants to the description so skills referencing the index can see the full API surface: "Fetch Review Details, Diff, Files Changed, Commits, Fetch Activity Signals (consolidated)"
- **Why LOW**: Whether index descriptions should list all section names (complete) or just the core command categories (summary) is a style decision. The omission is not operationally breaking — skills read the cluster files directly per the index description.
- **Curate command**: `/learnings:curate skill-references/github/commands.md`
- **Status**: RESOLVED (keep as-is — index descriptions are summaries)

## [L-3] gitlab/commands.md — fetch-review-data.md index description omits "Fetch Activity Signals (consolidated)"

- **Iter**: 24
- **Content Type**: DEEP_DIVE
- **File**: `.claude/skill-references/gitlab/commands.md`
- **Pattern**: Index table — fetch-review-data.md description
- **Possible classifications**:
  1. KEEP as-is — "Fetch Activity Signals" is a consolidation variant of "Fetch Review Details" (same glab command), not a separate command category; the index description is a summary, not exhaustive
  2. UPDATE — add the consolidated variant to the description so skills referencing the index can see the full API surface: "Fetch Review Details, Diff, Files Changed, Commits, Fetch Activity Signals (consolidated)"
- **Why LOW**: Same style decision as [L-2] for github/commands.md — whether index descriptions should list all section names or just core categories. The omission is not operationally breaking — skills read cluster files directly per the index navigation guidance.
- **Curate command**: `/learnings:curate skill-references/gitlab/commands.md`
- **Status**: RESOLVED (keep as-is — consistent with L-2)

## [L-4] gitlab/comment-interaction.md — Missing "Edit Inline Comment" section vs github counterpart

- **Iter**: 25
- **Content Type**: DEEP_DIVE
- **File**: `.claude/skill-references/gitlab/comment-interaction.md`
- **Pattern**: Missing section — "Edit Inline Comment"
- **Possible classifications**:
  1. KEEP as-is — GitLab notes endpoint for editing is `PATCH /projects/:id/merge_requests/:iid/notes/:note_id`, which is a straightforward path with no gotcha to document. GitHub had a specific endpoint path trap (`pulls/comments/<id>` vs `pulls/<num>/comments/<id>`). Omission is intentional because there's no non-obvious behavior worth warning about.
  2. ADD section — coverage gap. If consumers ever need to edit inline comments, the template is missing. Add `PATCH` template for completeness.
- **Why LOW**: Cannot determine without knowing whether any current or anticipated consumer needs comment editing. No current consumer (`extractor-prompt.md`) uses it. The simplicity of the GitLab endpoint makes the omission less risky than the GitHub version's gotcha, but it's still a potential coverage gap.
- **Curate command**: `/learnings:curate skill-references/gitlab/comment-interaction.md`
- **Status**: RESOLVED (keep as-is — no consumer needs it, no gotcha to document)

## [L-5] address-request-edge-cases.md — Step number mismatch for when to load the file

- **Iter**: 32
- **Content Type**: DEEP_DIVE
- **File**: `.claude/commands/git/address-request-comments/address-request-edge-cases.md`
- **Pattern**: File header — "Read this file when processing comments (step 6+)"
- **Possible classifications**:
  1. KEEP as-is — "step 6+" is close enough; the file is read before composing replies and that's the intent
  2. UPDATE — change to "step 5+" to match SKILL.md Important Notes reference ("Read when processing comments (step 5+)"). Step 5 is "Form independent assessment" where edge-cases guidance is directly needed.
- **Why LOW**: The discrepancy is between step 5 (SKILL.md Important Notes) and step 6 (edge-cases.md header). Not operationally breaking — the file covers assessment, categorization, and reply guidance spanning steps 5-7.
- **Curate command**: `/learnings:curate commands/git/address-request-comments/address-request-edge-cases.md`
- **Status**: RESOLVED (updated to "step 5+" — applied)

## [L-6] address-request-edge-cases.md — `git add -A` in Keep Reviews Focused bash example

- **Iter**: 32
- **Content Type**: DEEP_DIVE
- **File**: `.claude/commands/git/address-request-comments/address-request-edge-cases.md`
- **Pattern**: Keep Reviews Focused — bash code block (`git add -A && git commit`)
- **Possible classifications**:
  1. KEEP as-is — code block is illustrative; agents understand `git add -A` is one approach
  2. UPDATE — replace with `git add <paths>` pattern to follow project conventions (avoids risk of accidentally staging secrets/binaries)
- **Why LOW**: Style concern in an example code block for an unusual edge-case workflow. Not operationally breaking. Whether agents follow illustrative code blocks prescriptively is uncertain.
- **Curate command**: `/learnings:curate commands/git/address-request-comments/address-request-edge-cases.md`
- **Status**: RESOLVED (updated `git add -A` to `git add <paths>` — applied)

## [L-7] rebase-patterns.md — Pattern 3 (Commit Extraction Workflow) may be out of scope

- **Iter**: 33
- **Content Type**: DEEP_DIVE
- **File**: `.claude/commands/git/cascade-rebase/rebase-patterns.md`
- **Pattern**: Commit Extraction Workflow — moves a commit from a base branch to a standalone branch via `git reset --hard` on main + force-push
- **Possible classifications**:
  1. KEEP as-is — file is labeled "Common rebase patterns and troubleshooting"; commit extraction does use `--onto` and is a rebase pattern; content is correct
  2. MOVE to `git-patterns.md` learnings — commit extraction is a different workflow from cascade rebase; involves resetting main (destructive); broader audience than cascade-rebase users
- **Why LOW**: Content is correct and loosely fits the reference file's scope ("common rebase patterns"). Not operationally breaking. Moving would require verifying git-patterns.md content.
- **Curate command**: `/learnings:curate commands/git/cascade-rebase/rebase-patterns.md`
- **Status**: RESOLVED (keep as-is — content correct, uses --onto)

## [MAX-DEEP-DIVES] Deep dive phase hit 30-invocation limit

- **Iter**: 33
- **Details**: 30 deep dives completed (all listed candidates in Deep Dive Status table). 52 candidates remain for the next run — they carry over with naturally increasing staleness.
- **Remaining candidates**:
  - Tier 2 (unreviewed skills): ~20 files (git:*, learnings:*, ralph:*, parallel-plan:*, standalone)
  - Tier 3 (unreviewed learnings): 7 files (claude-code-hooks.md, java-infosec-gotchas.md, java-observability-gotchas.md, spring-boot-gotchas.md, postgresql-query-patterns.md + others)
  - Tier 4 (stale skills/skill-refs/personas): 12 files
  - Tier 5 (stale learnings): 11 files
- **Action needed**: Next consolidation run will pick up with fresh candidacy assessment. Staleness scores increase naturally — highest-priority files will float to the top.

