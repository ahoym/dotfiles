---
name: work-items
description: "Assess open work items and generate a parallel execution script — produces manifest.json and let-it-rip.sh for implement/clarify execution."
argument-hint: "[#12 #15] [--label=bug] [--max=10] [--concurrency=5]"
---

## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Current branch: !`git branch --show-current 2>/dev/null`
- HEAD: !`git rev-parse --short HEAD 2>/dev/null`
- Remote: !`git remote get-url origin 2>/dev/null`

# Sweep Work Items

Assess open work items (GitHub Issues / GitLab Issues), then generate `let-it-rip.sh` — a bash script that launches parallel `claude -p` sessions, each implementing or clarifying a work item.

1. **Assessment** (this skill, run once) — produces manifest + let-it-rip.sh + per-issue prompts
2. **Execution** (rerunnable) — operator runs `bash let-it-rip.sh` from terminal, repeatedly if needed

Each `claude -p` session checks its watermark before working — if nothing changed since the last run, the session exits cleanly.

**Lifecycle:** clarify → confirm → implement. Every issue starts at clarify. Implementation requires passing through the confirm gate — no exceptions.

## Usage

- `/sweep:work-items` — all open issues (up to 30)
- `/sweep:work-items #12 #15 #20` — specific issues
- `/sweep:work-items --label=bug` — filter by label
- `/sweep:work-items --max=10` — cap number of issues
- `/sweep:work-items --concurrency=3` — max parallel agents (default 5)
- Flags combine: `/sweep:work-items --label=bug --max=5 --concurrency=3`

## Prerequisites (hard gate)

`claude -p` sessions are top-level and cannot prompt for permissions. All patterns below must exist in `~/.claude/settings.json` `permissions.allow`. **Stop immediately if any are missing.**

> **Why global settings only?** Worktree agents don't have access to project-level `.claude/settings.local.json` (it's typically gitignored and not present in fresh worktree checkouts). Global settings are the only reliable permission source for `claude -p` sessions.

Detect platform first (see Phase 2), then check the matching CLI patterns:

**GitHub patterns:**
```json
"Bash(gh issue list:*)", "Bash(gh issue view:*)", "Bash(gh issue comment:*)",
"Bash(gh pr list:*)", "Bash(gh pr create:*)", "Bash(gh api:*)"
```

**GitLab patterns:**
```json
"Bash(glab api:*)", "Bash(glab mr create:*)", "Bash(glab mr list:*)"
```

**Shared patterns (both platforms):**
```json
"Bash(git add:*)", "Bash(git branch:*)", "Bash(git commit:*)",
"Bash(git push:*)", "Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)",
"Bash(git checkout:*)", "Bash(git fetch:*)", "Bash(mkdir:*)",
"Bash(jq *)",
"Bash(cp ~/.claude/skill-references/**)",
"Bash(bash ~/.claude/skill-references/**)",
"Read(~/.claude/commands/**)", "Read(~/.claude/learnings*/**)",
"Read(~/.claude/learnings-providers.json)", "Read(~/.claude/skill-references/**)",
"Read(~/**/tmp/claude-artifacts/**)",
"Write(~/**/tmp/claude-artifacts/**)",
"Edit(~/**/tmp/claude-artifacts/**)"
```

If missing, report with `BLOCKED:` prefix listing each missing pattern. Do not continue until resolved.

## Reference Files

- `~/.claude/skill-references/parallel-claude-runner-template.sh` — Bash template for let-it-rip.sh generation
- `~/.claude/skill-references/fill-template.sh` — Bash assembly for prompt generation (replaces LLM string substitution)
- @~/.claude/skill-references/sweep-scaffold.md — Shared artifact structure, watermark logic, result/learnings patterns
- `~/.claude/skill-references/sweep-agent-preflight.md` — Shared preflight steps (1-5 + Work Item + Repo Context) for all agent prompts
- `implementer-prompt.md` — Read when generating implementer prompts
- `clarifier-prompt.md` — Read when generating clarifier prompts
- `confirmer-prompt.md` — Read when generating clarify-confirm prompts (understanding + plan before implementation)

## Instructions

### Phase 0: Verify Prerequisites

Read `~/.claude/settings.json`, check every required pattern is present (exact string match). Also verify **Write/Edit parity**: every `Write(...)` pattern must have a matching `Edit(...)`. Stop if any are missing.

### Phase 1: Parse Arguments

Parse `$ARGUMENTS` to extract:
- **Issue numbers**: regex `#(\d+)` → `ISSUE_NUMBERS[]`
- **Labels**: `--label=<value>` → `LABELS[]`
- **Max**: `--max=<N>` → `MAX_ISSUES` (default 30)
- **Concurrency**: `--concurrency=<N>` → `CONCURRENCY` (default 5)

### Phase 2: Issue Fetch

1. Fetch work items — platform-specific commands are inlined below via `!` preprocessing:
   - Specific numbers (includes comments):
     ```
     !`cat ~/.claude/platform-commands/fetch-issue.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
     ```
     Add `updatedAt` to the `--json` fields.
   - All open (with optional label filter):
     ```
     !`cat ~/.claude/platform-commands/list-open-issues.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
     ```

3. For items fetched via list (no comments included), fetch comments per issue:
   ```
   !`cat ~/.claude/platform-commands/fetch-issue-comments.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
   ```

4. Store each item as: `{number, title, body, comments[], url, labels[], updatedAt}`

### Phase 3: Skip Detection

For each work item, check these conditions (in order):

**a. Issue closed.** If state is closed, mark as `SKIP(Closed)`.

**a2. Blocked by unresolved dependencies.** Parse the issue body for dependency declarations. Look for lines matching `Blocked by:` (case-insensitive) and extract all `#(\d+)` references. Also check `## Dependencies` sections — extract `#(\d+)` from any line within that section.

For each referenced blocker issue, determine its resolution state:

```
# Check issue state
!`cat ~/.claude/platform-commands/check-issue-state.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
# Check for PRs linked to the blocker (sweep branches + body references)
!`cat ~/.claude/platform-commands/list-prs-by-branch.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
!`cat ~/.claude/platform-commands/list-prs-by-issue-ref.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
```

Filter PR results: for the `#<N>` search, confirm the PR body actually references the blocker issue (avoid false positives from substring matches — e.g., `#9` matching `#99`). Check for `Relates to #<N>`, `Fixes #<N>`, `Closes #<N>`, or `Blocked by:.*#<N>` patterns.

A blocker is **resolved** if any of these are true:
- The blocker issue is `CLOSED`
- The blocker has a **merged** PR (code is on main)
- The blocker has an **open** PR (code exists on a branch)

A blocker is **unresolved** only when the issue is open AND has no PR (no code exists anywhere to build on).

If **any** blocker is unresolved, mark as `SKIP(Blocked by #N, #M (no PR))` — list all unresolved blockers in the reason.

If all blockers are resolved, the dependency gate passes. Additionally, **determine the base branch**:
- If every blocker's code is on main (issue closed or PR merged) → base branch is `default_branch`
- If exactly **one** blocker has an open (unmerged) PR → base branch is that PR's `headRefName`
- If **multiple** blockers have open PRs on **different** branches → base branch is `default_branch` and mark with `⚠️ diamond dependency` in the summary. Stacking is only safe on a single linear chain. The operator should merge at least one blocker before the dependent can stack cleanly.

Record as `base_branch` in the item's metadata for Phase 5 worktree setup.

**Batch optimization:** collect all unique blocker numbers across all issues and fetch their states + PRs in one pass before evaluating individual items. Cache results to avoid redundant API calls when multiple issues share blockers.

**b. Existing PR linked.** Check for open PRs with branch matching `sweep/<id>-*`:
```
!`cat ~/.claude/platform-commands/list-open-prs.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
```
Filter client-side. If match found: mark as `SKIP(PR exists (#N))`.

**c. Prior run already processed this state (hard gate).** Check `tmp/claude-artifacts/sweep-work-items/*/issue-<N>/status.md` across all prior run directories (most recent first). If `milestone: done` AND both `last_comment_id` and `last_sweep_updated_at` match the current issue's latest comment ID and `updatedAt` → `SKIP(Already processed)`. Both must match — a comment ID match alone misses body/label edits that change `updatedAt`, and a timestamp match alone misses issues where `updatedAt` hasn't propagated yet. This runs before comment thread analysis so an already-processed human reply can't be misread as new input.

**d. Sweeper commented, no human reply.** Find the most recent Sweeper comment (`\*Role:\*.*Sweeper` or `\*Role:\*.*Sweeper-Confirm` — anchored to markdown italic formatting `*Role:*` to avoid false positives on prose containing "Sweeper"). If no non-Sweeper comment after it → read the comment content to determine if it's asking questions or purely informational. Comments with explicit questions, `### Questions` sections, or requests for confirmation ("Does this plan match your intent?") → `SKIP(Awaiting reply)`. Informational comments (retroactive confirmations, implementation status updates, process notes) → **eligible**, apply normal decision in Phase 5.

**e. Sweeper asked questions (`\*Role:\*.*Sweeper`, NOT `Sweeper-Confirm`), human replied.** → **eligible**, force **clarify-confirm**.

**f. Sweeper confirmed (`\*Role:\*.*Sweeper-Confirm`), human replied.** → **eligible**, apply normal decision in Phase 5.

### Phase 4: Repo Summary

Build compressed repository context (~150 lines) that every agent receives:

1. Read `README.md` (if exists, first 80 lines)
2. Read `CLAUDE.md` or `.claude/CLAUDE.md` (if exists)
3. Run `ls` at project root
4. Detect: primary language, framework, build system, test command, entry points
5. Check for `docs/learnings/SYSTEM_OVERVIEW.md` — read if present

Assemble into `REPO_SUMMARY`.

### Phase 5: Decide & Generate Artifacts

For each eligible work item, determine the role based on its conversation stage:

> | Conversation stage | Role | Rule |
> |---|---|---|
> | No prior Sweeper comment | **clarify** | Always — agent posts questions/analysis first |
> | Sweeper asked questions, operator replied (rule e) | **clarify-confirm** | Always — agent posts understanding + plan |
> | Sweeper confirmed, operator replied (rule f) | **implement** or **clarify** | Apply decision rule below |
>
> **Decision rule (stage 3 only):** Can you identify all three? (a) Specific file targets (b) Expected behavior change (c) Verification method. All three → **implement**. Any missing → **clarify** (restart cycle).

Create run directory: `tmp/claude-artifacts/sweep-work-items/<YYYY-MM-DD-HHMM>` with an `issue-<N>/` subdirectory per eligible issue. Compute the timestamp in a separate Bash call first (`date +%Y-%m-%d-%H%M`), then use the literal value in `mkdir`.

#### manifest.json

```json
{
  "created_at": "<ISO>",
  "run_dir": "<RUN_DIR>",
  "concurrency": <N>,
  "owner_repo": "<owner/repo>",
  "default_branch": "<main or master>",
  "repo_summary_lines": <N>,
  "eligible": [
    {"number": 12, "title": "...", "role": "implement", "url": "...", "labels": ["bug"], "base_branch": "main"},
    {"number": 8, "title": "...", "role": "clarify", "url": "...", "labels": ["enhancement"], "base_branch": "sweep/7-auth-refactor"}
  ],
  "skipped": [
    {"number": 15, "reason": "PR exists (#42)"},
    {"number": 7, "reason": "Awaiting reply"},
    {"number": 10, "reason": "Blocked by #8, #9 (no PR)"}
  ]
}
```

#### Data files & prompt assembly

Write data files for template assembly, then call `fill-template.sh`:

1. **Run-level files** (write once, shared by all issues):
   - `<RUN_DIR>/preflight.md` — copy `~/.claude/skill-references/sweep-agent-preflight.md`
   - `<RUN_DIR>/repo-summary.txt` — from Phase 4

2. **Per-issue files** in `issue-<N>/`:
   - `metadata.json`:
     ```json
     {
       "ISSUE_NUMBER": "<number>",
       "ISSUE_TITLE": "<title>",
       "ISSUE_URL": "<url>",
       "ISSUE_LABELS": "<comma-separated>",
       "OWNER_REPO": "<owner/repo>",
       "BASE_BRANCH": "<default branch or dependency PR branch>",
       "MODEL_NAME": "<model>",
       "PERSONA_NAME": "<persona or none>",
       "RUN_DIR": "<absolute path>",
       "ISSUE_DIR": "<absolute path>",
       "ISSUE_UPDATED_AT": "<timestamp>",
       "LAST_COMMENT_ID": "<id or none>",
       "POST_ISSUE_COMMENT_CMD": "<literal command — see below>",
       "FETCH_ISSUE_WITH_COMMENTS_CMD": "<literal command — see below>",
       "CHECK_ISSUE_STATE_CMD": "<literal command — see below>"
     }
     ```

     **Platform command injection:** The following keys inject literal platform commands into runtime templates via `fill-template.sh`. The SKILL.md `!cat`-inlines the script content at load time; the agent writes the literal command string as a metadata.json value:

     - `POST_ISSUE_COMMENT_CMD` — literal value of:
       ```
       !`cat ~/.claude/platform-commands/post-issue-comment.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
       ```
     - `FETCH_ISSUE_WITH_COMMENTS_CMD` — literal value of:
       ```
       !`cat ~/.claude/platform-commands/fetch-issue-with-comments.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
       ```
     - `CHECK_ISSUE_STATE_CMD` — literal value of:
       ```
       !`cat ~/.claude/platform-commands/check-issue-state.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
       ```
   - `body.txt` — issue body text
   - `comments.txt` — formatted comment thread

3. **Assemble prompt:**
   ```bash
   bash ~/.claude/skill-references/fill-template.sh <template-path> <RUN_DIR>/issue-<N> > <RUN_DIR>/issue-<N>/prompt.txt
   ```
   Where `<template-path>` is `implementer-prompt.md`, `clarifier-prompt.md`, or `confirmer-prompt.md` (relative to this skill's directory).

#### let-it-rip.sh

Generate a runner script adapted for work items. Follow **let-it-rip.sh Generation** in `sweep-scaffold.md` — write `<RUN_DIR>/metadata.json` and assemble via `fill-template.sh`. Do NOT read the runner template directly. Work-item-specific metadata overrides and adaptations:

- **Model selection**: `MODEL` → `claude-opus-4-6` for implement runs (leaf doing actual coding work). Clarify and confirm runs may use `claude-sonnet-4-6` (lighter, comment-driven). When mixing modes in one runner, default to opus.
- **Entity type keys**: Set in `metadata.json` per the sweep-scaffold.md schema. Issue-specific values:
  ```json
  {"ENTITY_PREFIX": "issue", "ENTITY_LABEL": "Issue", "STATE_FIELD": "issue_state",
   "STATE_CHECK_CMD": "gh issue view", "TERMINAL_STATES": "CLOSED"}
  ```
- **Config arrays**: `IMPLEMENT_ISSUES=(<numbers>)` — issues that get worktrees vs in-place clarifiers. Write this array to the runner script so the worktree setup section knows which issues need checkouts.
- **Worktree setup**: Only for issues in `IMPLEMENT_ISSUES`. Create worktrees under `<RUN_DIR>/worktrees/issue-<N>/` from the issue's `BASE_BRANCH` (read from `metadata.json`). When `BASE_BRANCH` is the default branch, the implementer starts fresh. When it's a dependency's PR branch, the implementer stacks on top of that branch's work. **For non-default base branches:** run `git fetch origin <BASE_BRANCH>` before `git worktree add` — the dependency's branch likely only exists on the remote.
- **PR target for stacked branches**: When `BASE_BRANCH` is not the default branch, the implementer's PR must target `BASE_BRANCH` (not main). The `BASE_BRANCH` value is available in `metadata.json` and must be passed through to the implementer prompt so `gh pr create --base <BASE_BRANCH>` is used.
- **Pre-flight state check**:
  1. Local `status.md` check — skip if `issue_state: CLOSED` (terminal entity state only — role convergence signals like `comment_posted` and `pr_opened` are the session's responsibility, not the runner's)
  2. API fallback — `gh issue view <N> --json state -q '.state'`, skip if closed
- **Working directory**: For implementers, `cd` into the worktree before launching `claude -p`. For clarifiers, stay in project root.
- **Cleanup**: Worktree cleanup on EXIT trap (only for worktrees created by this run).

The runner MUST use `stream-monitor.sh` for `live.md` observability (same pattern as PR sweeps).

### Phase 6: Present Summary & Announce

```
Assessed N issues. M eligible (I implement, C clarify, F confirm), K skipped:

| # | Title | Role | Base | Skip Reason |
|---|-------|------|------|-------------|
| 12 | Fix login redirect | Implement | main | -- |
| 8 | Add dark mode | Implement | sweep/7-auth | stacked on #7 |
| 3 | Update nav | Clarify | -- | -- |
| 15 | Refactor auth | Skip | -- | PR exists (#42) |
| 10 | New endpoint | Skip | -- | Blocked by #8, #9 (no PR) |
| 7 | Update deps | Skip | -- | Awaiting reply |
```

Then announce artifacts (follow Announce Format from `sweep-scaffold.md`, substituting `issue-<N>` for `pr-<N>`):

```
Artifacts written to <RUN_DIR>/

  manifest.json    — M eligible (I implement, C clarify), K skipped
  let-it-rip.sh    — concurrency: CONCURRENCY
  issue-<N>/       — M issue directories with prompts

To launch:        bash <RUN_DIR>/let-it-rip.sh
Re-run (loop):    bash <RUN_DIR>/let-it-rip.sh  (sessions with no changes exit cleanly)
Progress:         "Check progress on <RUN_DIR>"
Retro:            "Retro on <RUN_DIR>"
```

Proceed directly to artifact generation after the summary ��� do not wait for confirmation.

## Convergence (director-layer)

Convergence is a director concern, not this skill's. Summary for directors:

- **Implementers**: converged when `pr_opened: true` in `status.md` (PR created, job done)
- **Clarifiers**: converged when `comment_posted: true` in `status.md` (questions posted, awaiting human reply)
- **Confirmers**: converged when `confirmation_posted: true` in `status.md`
- **Error states**: `milestone: errored` items are NOT converged — director may write retry directives
- **Single-pass default**: work items are typically one-shot. Rerun only triggers if the issue was updated (new comments, edits) since the last pass.

## Important Notes

- **Assessment only.** This skill generates artifacts and exits. It does not launch agents or wait for results.
- **Agents are independent but dependency-aware.** Each `claude -p` session operates alone, but the assessment phase respects `Blocked by:` declarations — issues with unresolved blockers (no PR, no merged code) are skipped. When a blocker has an open PR, the dependent issue stacks on that branch. Parallel implementers on unrelated issues may still create conflicting PRs — the operator resolves manually.

- **`Relates to` not `Closes`.** PRs reference issues with `Relates to #{N}`, never `Closes` or `Fixes`. The operator decides when to close.
- **Footnote identity.** `Role: Sweeper` (clarifier) and `Role: Sweeper-Confirm` (confirmer) — used by skip detection to determine conversation stage.
- **Worktrees are preserved.** Implementer worktrees persist after the sweep for follow-up work. Clean up with `git worktree remove` after PRs merge.
- See **Shared Important Notes** in `sweep-scaffold.md` for rerunnable, rate limits, crash recovery, and cleanup.
