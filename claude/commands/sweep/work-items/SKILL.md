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
"Read(~/.claude/commands/**)", "Read(~/.claude/learnings/**)",
"Read(~/.claude/learnings-private/**)", "Read(~/.claude/skill-references/**)",
"Read(~/.claude/learnings-team/**)",
"Read(~/**/tmp/claude-artifacts/**)",
"Write(~/**/tmp/claude-artifacts/**)",
"Edit(~/**/tmp/claude-artifacts/**)"
```

If missing, report with `BLOCKED:` prefix listing each missing pattern. Do not continue until resolved.

## Reference Files

- @~/.claude/skill-references/platform-detection.md — GitHub vs GitLab detection
- `~/.claude/skill-references/{github,gitlab}/issue-operations.md` — Issue fetch, comment commands
- `~/.claude/skill-references/{github,gitlab}/pr-management.md` — PR creation (for implementer context)
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

### Phase 2: Platform Detection & Issue Fetch

1. Follow `platform-detection.md` to determine GitHub vs GitLab. Read the matching `issue-operations.md` cluster.

2. Fetch work items:
   - Specific numbers: `gh issue view <N> --json number,title,body,labels,assignees,comments,url,updatedAt`
   - Label filter: `gh issue list --state open --label <LABEL> --json number,title,body,labels,assignees,updatedAt --limit <MAX>`
   - No filters: `gh issue list --state open --json number,title,body,labels,assignees,updatedAt --limit <MAX>`

3. For items fetched via list (no comments included), fetch comments per issue: `gh api repos/{owner}/{repo}/issues/<N>/comments --paginate`

4. Store each item as: `{number, title, body, comments[], url, labels[], updatedAt}`

### Phase 3: Skip Detection

For each work item, check these conditions (in order):

**a. Issue closed.** If state is closed, mark as `SKIP(Closed)`.

**b. Existing PR linked.** Check for open PRs with branch matching `sweep/<id>-*`:
```bash
gh pr list --state open --json headRefName,number,url
```
Filter client-side. If match found: mark as `SKIP(PR exists (#N))`.

**c. Prior run already processed this state (hard gate).** Check `tmp/claude-artifacts/sweep-work-items/*/issue-<N>/status.md` across all prior run directories (most recent first). If `milestone: done` AND both `last_comment_id` and `last_sweep_updated_at` match the current issue's latest comment ID and `updatedAt` → `SKIP(Already processed)`. Both must match — a comment ID match alone misses body/label edits that change `updatedAt`, and a timestamp match alone misses issues where `updatedAt` hasn't propagated yet. This runs before comment thread analysis so an already-processed human reply can't be misread as new input.

**d. Sweeper commented, no human reply.** Find the most recent Sweeper comment (`\*Role:\*.*Sweeper` — anchored to markdown italic formatting `*Role:*` to avoid false positives on prose containing "Sweeper"). If no non-Sweeper comment after it:
   - If the comment contains `Role:.*Sweeper-Implement`, check for a linked merged PR (`gh pr list --state merged --json headRefName,number` filtered for `sweep/<issue-id>-*`). If found → **eligible**, force **clarify-confirm** (the implemented phase is done; agent should plan the next phase). If no merged PR found → `SKIP(Awaiting reply)`.
   - Otherwise → `SKIP(Awaiting reply)`.

**e. Sweeper commented (any `\*Role:\*.*Sweeper` variant), human replied.** → **eligible**, force **clarify-confirm**. The agent must acknowledge the operator's reply and confirm understanding before implementation. This applies regardless of whether the reply is approval, corrections, or answers to open questions — the confirm step demonstrates understanding, not just permission.

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
> | Sweeper commented, operator replied (rule e) | **clarify-confirm** or **implement** | Default **clarify-confirm**. Promote to **implement** only when the operator's last reply is pure approval AND the sweeper's preceding comment already acknowledged a prior operator reply (i.e., the sweeper has demonstrated understanding at least once in the thread) |
>
> The implement gate is about conversation maturity: has the sweeper shown it understands the operator's intent? The clarify-confirm agent naturally checks implementability (file targets, behavior, verification) as part of its plan — if those aren't clear, it asks more questions, which keeps the cycle in clarify-confirm. The assessment skill doesn't need to re-check them.

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
    {"number": 12, "title": "...", "role": "implement", "url": "...", "labels": ["bug"]},
    {"number": 8, "title": "...", "role": "clarify", "url": "...", "labels": ["enhancement"]}
  ],
  "skipped": [
    {"number": 15, "reason": "PR exists (#42)"},
    {"number": 7, "reason": "Awaiting reply"}
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
       "DEFAULT_BRANCH": "<main or master>",
       "MODEL_NAME": "<model>",
       "PERSONA_NAME": "<persona or none>",
       "RUN_DIR": "<absolute path>",
       "ISSUE_DIR": "<absolute path>",
       "ISSUE_UPDATED_AT": "<timestamp>",
       "LAST_COMMENT_ID": "<id or none>"
     }
     ```
   - `body.txt` — issue body text
   - `comments.txt` — formatted comment thread

3. **Assemble prompt:**
   ```bash
   bash ~/.claude/skill-references/fill-template.sh <template-path> <RUN_DIR>/issue-<N> > <RUN_DIR>/issue-<N>/prompt.txt
   ```
   Where `<template-path>` is `implementer-prompt.md`, `clarifier-prompt.md`, or `confirmer-prompt.md` (relative to this skill's directory).

#### let-it-rip.sh

Generate a runner script adapted for work items. Read `~/.claude/skill-references/parallel-claude-runner-template.sh` as a starting reference, then generate with these adaptations:

- **Directory naming**: `issue-<N>` instead of `pr-<N>`
- **Config section**: `ISSUES=(<numbers>)` instead of `PRS`, `IMPLEMENT_ISSUES=(<numbers>)` for worktree tracking
- **Worktree setup**: Only for issues in `IMPLEMENT_ISSUES`. Create worktrees under `<RUN_DIR>/worktrees/issue-<N>/` from default branch (implementers start fresh).
- **Pre-flight state check**:
  1. Local `status.md` check — skip if `issue_state: closed` or `pr_opened: true` or `comment_posted: true`
  2. API fallback — `gh issue view <N> --json state -q '.state'`, skip if closed
- **Working directory**: For implementers, `cd` into the worktree before launching `claude -p`. For clarifiers, stay in project root.
- **Cleanup**: Worktree cleanup on EXIT trap (only for worktrees created by this run).

The runner MUST use `stream-monitor.sh` for `live.md` observability (same pattern as PR sweeps).

### Phase 6: Present Summary & Announce

```
Assessed N issues. M eligible (I implement, C clarify, F confirm), K skipped:

| # | Title | Role | Skip Reason |
|---|-------|------|-------------|
| 12 | Fix login redirect | Implement | -- |
| 8 | Add dark mode | Clarify | -- |
| 15 | Refactor auth | Skip | PR exists (#42) |
| 7 | Update deps | Skip | Awaiting reply |
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
- **Agents are independent.** Each `claude -p` session operates alone. Parallel implementers may create conflicting PRs — the operator resolves manually.

- **`Relates to` not `Closes`.** PRs reference issues with `Relates to #{N}`, never `Closes` or `Fixes`. The operator decides when to close.
- **Footnote identity.** `Role: Sweeper` (clarifier) and `Role: Sweeper-Confirm` (confirmer) — used by skip detection to determine conversation stage.
- **Worktrees are preserved.** Implementer worktrees persist after the sweep for follow-up work. Clean up with `git worktree remove` after PRs merge.
- See **Shared Important Notes** in `sweep-scaffold.md` for rerunnable, rate limits, crash recovery, and cleanup.
