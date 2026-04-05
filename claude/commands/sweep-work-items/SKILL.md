---
name: sweep-work-items
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

Each `claude -p` session checks its watermark before working — if nothing changed since the last run, the session exits cleanly. Implementers create branches + PRs in worktrees. Clarifiers post targeted questions as issue comments.

## Usage

- `/sweep-work-items` — all open issues (up to 30)
- `/sweep-work-items #12 #15 #20` — specific issues
- `/sweep-work-items --label=bug` — filter by label
- `/sweep-work-items --max=10` — cap number of issues
- `/sweep-work-items --concurrency=3` — max parallel agents (default 5)
- Flags combine: `/sweep-work-items --label=bug --max=5 --concurrency=3`

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
"Read(~/**/tmp/sweep-work-items/**)",
"Write(~/**/tmp/sweep-work-items/**)",
"Edit(~/**/tmp/sweep-work-items/**)"
```

If missing, report with `BLOCKED:` prefix listing each missing pattern. Do not continue until resolved.

## Reference Files

- @~/.claude/skill-references/platform-detection.md — GitHub vs GitLab detection
- `~/.claude/skill-references/{github,gitlab}/issue-operations.md` — Issue fetch, comment commands
- `~/.claude/skill-references/{github,gitlab}/pr-management.md` — PR creation (for implementer context)
- `~/.claude/skill-references/parallel-claude-runner-template.sh` — Bash template for let-it-rip.sh generation
- `~/.claude/skill-references/sweep-scaffold.md` — Shared artifact structure, watermark logic, result/learnings patterns
- `implementer-prompt.md` — Read when generating implementer prompts
- `clarifier-prompt.md` — Read when generating clarifier prompts

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

**c. Sweeper already commented, no human reply.** Scan comments for the Sweeper footnote (`Role:.*Sweeper`). If found, check if any non-Sweeper comment was posted after it. If no reply: mark as `SKIP(Awaiting reply)`.

**d. Sweeper commented AND human replied.** Both a Sweeper comment and a subsequent non-Sweeper comment exist → **eligible** for re-assessment.

### Phase 4: Repo Summary

Build compressed repository context (~150 lines) that every agent receives:

1. Read `README.md` (if exists, first 80 lines)
2. Read `CLAUDE.md` or `.claude/CLAUDE.md` (if exists)
3. Run `ls` at project root
4. Detect: primary language, framework, build system, test command, entry points
5. Check for `docs/learnings/SYSTEM_OVERVIEW.md` — read if present

Assemble into `REPO_SUMMARY`.

### Phase 5: Decide & Generate Artifacts

For each eligible work item, apply the implement-vs-clarify decision:

> **Decision rule:** Can you identify all three from the issue body + comments + repo summary?
> (a) Specific file targets that need changing
> (b) The expected behavior change
> (c) A way to verify the change worked
>
> If all three: **implement**. If any is missing: **clarify**.

Create run directory: `tmp/sweep-work-items/<YYYY-MM-DD-HHMM>` with an `issue-<N>/` subdirectory per eligible issue. Compute the timestamp in a separate Bash call first (`date +%Y-%m-%d-%H%M`), then use the literal value in `mkdir`.

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

#### issue-\<N\>/prompt.txt

Read the appropriate prompt template (`implementer-prompt.md` or `clarifier-prompt.md`). Each template includes watermark/skip logic, learnings search, permission pre-flight, role-specific work instructions, and artifact writing steps.

Fill template placeholders:
- `{ISSUE_NUMBER}`, `{ISSUE_TITLE}`, `{ISSUE_BODY}`, `{ISSUE_COMMENTS}`, `{ISSUE_URL}` — from the work item
- `{ISSUE_LABELS}` — comma-separated label names
- `{REPO_SUMMARY}` — from Phase 4
- `{OWNER_REPO}` — from git remote
- `{DEFAULT_BRANCH}` — from `git symbolic-ref refs/remotes/origin/HEAD` or default to `main`
- `{RUN_DIR}` — absolute path to run directory
- `{ISSUE_DIR}` — absolute path to `issue-<N>/` directory
- `{MODEL_NAME}` — the model currently running
- `{PERSONA_NAME}` — active persona name, or "none"
- `{ISSUE_UPDATED_AT}` — issue's `updatedAt` timestamp
- `{LAST_COMMENT_ID}` — ID of the latest comment, or "none"

Write the filled prompt to `issue-<N>/prompt.txt`.

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
Assessed N issues. M eligible (I implement, C clarify), K skipped:

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
- **Error states**: `milestone: errored` items are NOT converged — director may write retry directives
- **Single-pass default**: work items are typically one-shot. Rerun only triggers if the issue was updated (new comments, edits) since the last pass.

## Important Notes

- **Assessment only.** This skill generates artifacts and exits. It does not launch agents or wait for results.
- **Agents are independent.** Each `claude -p` session operates alone. Parallel implementers may create conflicting PRs — the operator resolves manually.
- **`Relates to` not `Closes`.** PRs reference issues with `Relates to #{N}`, never `Closes` or `Fixes`. The operator decides when to close.
- **Footnote identity.** Clarifier comments end with `Role: Sweeper` footnote for re-run skip detection.
- **Worktrees are preserved.** Implementer worktrees persist after the sweep for follow-up work. Clean up with `git worktree remove` after PRs merge.
- See **Shared Important Notes** in `sweep-scaffold.md` for rerunnable, rate limits, crash recovery, and cleanup.
