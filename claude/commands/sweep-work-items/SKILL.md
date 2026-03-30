---
name: sweep-work-items
description: "Process open work items in parallel — implement clear ones, clarify vague ones. Creates PRs and posts comments."
argument-hint: "[#12 #15] [--label=bug] [--max=10] [--concurrency=5]"
---

## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Current branch: !`git branch --show-current 2>/dev/null`
- HEAD: !`git rev-parse --short HEAD 2>/dev/null`
- Remote: !`git remote get-url origin 2>/dev/null`

# Sweep Work Items

Process open work items (GitHub Issues for v1) using parallel agents. Each agent either implements the work item (branch + PR in an isolated worktree) or posts clarifying questions on the issue.

The main agent acts as orchestrator — it reads issues, decides implement vs clarify, spawns agents in waves, and collects results into a summary table.

## Usage

- `/sweep-work-items` — process all open issues (up to 30)
- `/sweep-work-items #12 #15 #20` — process specific issues
- `/sweep-work-items --label=bug` — filter by label (repeat for multiple: `--label=bug --label=enhancement`)
- `/sweep-work-items --max=10` — cap number of issues to process
- `/sweep-work-items --concurrency=3` — max parallel agents (default 5)
- Flags combine: `/sweep-work-items --label=bug --max=5 --concurrency=3`

## Reference Files (conditional — read only when needed)

- @~/.claude/skill-references/platform-detection.md — Platform detection (GitHub vs GitLab)
- `~/.claude/skill-references/{github,gitlab}/issue-operations.md` — Issue fetch, comment, link check commands
- `~/.claude/skill-references/{github,gitlab}/pr-management.md` — PR creation (for implementer context)
- `implementer-prompt.md` — Read when spawning implementer agents
- `clarifier-prompt.md` — Read when spawning clarifier agents
- `~/.claude/skill-references/agent-prompting.md` — Completion report format reference

## Prerequisites

Background agents cannot prompt for permissions. The following patterns must be allowed in **project-level** `.claude/settings.local.json`. Global `~/.claude/settings.json` patterns are not sufficient — worktree agents inherit the project-level settings, not global.

```json
"permissions": {
  "allow": [
    "Bash(gh issue list:*)",
    "Bash(gh issue view:*)",
    "Bash(gh issue comment:*)",
    "Bash(gh pr list:*)",
    "Bash(gh pr create:*)",
    "Bash(gh api:*)",
    "Bash(git add:*)",
    "Bash(git branch:*)",
    "Bash(git commit:*)",
    "Bash(git push:*)",
    "Bash(git status:*)",
    "Bash(git diff:*)",
    "Bash(git log:*)",
    "Write(~/**/tmp/claude-artifacts/**)"
  ]
}
```

Before launching agents, read `.claude/settings.local.json` and check each required pattern against the `permissions.allow` array. List any missing patterns explicitly and ask the operator to add them before proceeding. Do not rely on global settings — they are not inherited by worktree agents.

## Instructions

### Phase 1: Parse Arguments

Parse `$ARGUMENTS` to extract:
- **Issue numbers**: regex `#(\d+)` — store as `ISSUE_NUMBERS[]`
- **Labels**: `--label=<value>` — store as `LABELS[]`
- **Max**: `--max=<N>` — store as `MAX_ISSUES` (default 30)
- **Concurrency**: `--concurrency=<N>` — store as `CONCURRENCY` (default 5)

### Phase 2: Platform Detection & Issue Fetch

1. Follow `@~/.claude/skill-references/platform-detection.md` to determine GitHub vs GitLab. Read the matching `issue-operations.md` cluster.

2. Fetch work items using commands from `issue-operations.md`:
   - If specific numbers given: fetch each with `gh issue view <N> --json number,title,body,labels,assignees,comments,url`
   - If label filter: `gh issue list --state open --label <LABEL> --json number,title,body,labels,assignees --limit <MAX>`
   - If no filters: `gh issue list --state open --json number,title,body,labels,assignees --limit <MAX>`

3. For items fetched via `gh issue list` (which doesn't include comments), fetch comments separately for each: `gh api repos/{owner}/{repo}/issues/<N>/comments --paginate`

4. Store each item as: `{id, title, body, comments[], url, labels[]}`

### Phase 3: Skip Detection

For each work item, check these conditions (in order):

**a. Existing PR linked.** Check for open PRs with branch matching `sweep/<id>-*`:
```bash
gh pr list --state open --json headRefName,number,url
```
Filter client-side. If match found: mark item as `SKIP(PR exists (#N))`.

**b. Sweeper already commented, no human reply.** Fetch issue comments and scan for the Sweeper footnote (`Role:.*Sweeper` in body). If found, check if any non-Sweeper comment was posted after it. If no operator reply since: mark as `SKIP(Awaiting reply)`.

**c. Sweeper commented AND human replied.** If both a Sweeper comment and a subsequent non-Sweeper comment exist, the item is **eligible** for re-assessment — the operator's reply may provide enough detail to implement.

Present a skip summary before proceeding:
```
Fetched N issues. M eligible, K skipped:
- #15: Skip — PR exists (#42)
- #7: Skip — Awaiting reply (asked 2d ago)
- #3: Re-assess — operator replied to previous questions
```

### Phase 4: Repo Summary

Build a compressed repository context (target ~150 lines) that every agent receives. This avoids N agents independently scanning the repo structure.

1. Read `README.md` (if exists, first 80 lines)
2. Read `CLAUDE.md` or `.claude/CLAUDE.md` (if exists)
3. Run `ls` at project root to capture top-level structure
4. Detect: primary language, framework, build system, test command, entry points
5. Check for existing `docs/learnings/SYSTEM_OVERVIEW.md` — if present, read it (rich context source)

Assemble findings into `REPO_SUMMARY` — a concise text block agents can use as their starting map for code exploration.

### Phase 5: Decide & Dispatch

For each eligible work item, make the implement-vs-clarify decision:

> **Decision rule:** Can you identify all three from the issue body + comments + repo summary?
> (a) Specific file targets that need changing
> (b) The expected behavior change
> (c) A way to verify the change worked
>
> If all three: **implement**. If any is missing: **clarify**.

Process items in waves of `CONCURRENCY` (default 5).

Bootstrap the temp directory before launching any agents:
```bash
mkdir -p tmp/sweep-work-items
```

**For each wave:**

1. Categorize remaining eligible items as implement or clarify.

2. Read the appropriate prompt template:
   - Implementers: read @implementer-prompt.md
   - Clarifiers: read @clarifier-prompt.md

3. For each item, construct the agent prompt by filling template placeholders:
   - `ISSUE_NUMBER`, `ISSUE_TITLE`, `ISSUE_BODY`, `ISSUE_COMMENTS`, `ISSUE_URL` — from the work item
   - `REPO_SUMMARY` — from Phase 4
   - `OWNER_REPO` — from git remote (e.g., `owner/repo`)
   - `DEFAULT_BRANCH` — from `git symbolic-ref refs/remotes/origin/HEAD` or default to `main`
   - `MODEL_NAME` — the model you are currently running (e.g., "Claude Opus 4.6")
   - `PERSONA_NAME` — active persona name, or "none" if no persona is set

4. Launch agents:
   - **Implementers**: `Agent` tool with `isolation: "worktree"` and `run_in_background: true`
   - **Clarifiers**: `Agent` tool with `run_in_background: true` (no isolation — no code changes)
   - Launch all agents in the wave in a **single message** with multiple tool calls for maximum parallelism

5. Wait for wave completion via auto-notifications. **Do not** poll or call TaskOutput with block:true — the system sends notifications automatically when background agents complete.

6. As each agent completes, parse its completion report and update the tracking state:
   - Extract PR URL from implementer reports
   - Extract comment status from clarifier reports
   - Note any failures

7. After the wave completes, launch the next wave with remaining items.

### Phase 6: Results Summary

After all waves complete, print a summary table:

```
## Sweep Results

| # | Issue | Decision | Result |
|---|-------|----------|--------|
| 12 | Fix login redirect | Implement | PR #45 |
| 8 | Add dark mode | Clarify | Commented (3 questions) |
| 15 | Refactor auth | Skip | PR exists (#42) |
| 7 | Update deps | Skip | Awaiting reply |
| 3 | Vague perf issue | Clarify | Commented (2 questions) |
| 21 | Fix typo in docs | Implement | PR #46 |
| 9 | Add search | Implement | Failed (test failures) |

**Summary:** 7 items processed — 3 implemented, 2 clarified, 2 skipped, 0 failed
```

If any agents failed, include their error context in the table's Result column.

## Important Notes

- **Agents are independent.** Each agent operates as if it's the only one working on the repo. They don't know about each other, even though the orchestrator does. This means parallel implementers may create PRs that conflict — the operator resolves conflicts manually.
- **`Relates to` not `Closes`.** PRs reference their issue with `Relates to #{N}` or `Relates to <URL>`, never `Closes` or `Fixes`. The operator decides when to close the issue after reviewing the PR.
- **Footnote identity.** All comments posted by clarifier agents end with the standard footnote using `Role: Sweeper`. This enables re-run skip detection and distinguishes sweep comments from operator comments.
- **One-shot operation.** This skill runs once per invocation. If clarifying questions are posted, re-run the skill later after the operator or issue author has responded — the skip detection in Phase 3 will pick up the replies and re-assess.
- **Partial failure is normal.** If some agents fail (API errors, test failures, permission issues), the sweep continues with remaining agents. Failed items appear in the summary table with error context.
- **Temp files.** All ephemeral files (comment bodies, PR bodies) are written to `tmp/claude-artifacts/sweep-work-items/`. This directory can be cleaned up after the sweep.
- **Worktrees are preserved.** Implementer worktrees at `.claude/worktrees/agent-*` remain after the sweep so follow-up work (e.g., addressing PR review comments) can be done directly in them. Clean up with `git worktree remove` after PRs merge.
