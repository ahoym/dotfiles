---
name: sweep-review-prs
description: "Assess open PRs and generate a parallel review script — produces manifest.json and let-it-rip.sh for team-review-request execution."
argument-hint: "[#47 #46] [--max=20] [--concurrency=3] [--include-drafts]"
---

## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Current branch: !`git branch --show-current 2>/dev/null`
- Remote: !`git remote get-url origin 2>/dev/null`

# Sweep Review PRs

Assess open PRs, then generate `let-it-rip.sh` — a bash script that launches parallel `claude -p` sessions, each invoking `/git:team-review-request`.

1. **Assessment** (this skill, run once) — produces manifest + let-it-rip.sh + per-PR prompts
2. **Execution** (rerunnable) — operator runs `bash let-it-rip.sh` from terminal, repeatedly if needed

`let-it-rip.sh` is the loop target, not this skill. Each `claude -p` session invokes `team-review-request`, which has re-review and quick-exit detection built in — if no changes since the last review, the session exits cleanly with `status=skipped`.

## Usage

- `/sweep-review-prs` — all open PRs (up to 20)
- `/sweep-review-prs #47 #46` — specific PRs
- `/sweep-review-prs --max=10 --concurrency=2 --include-drafts`

## Prerequisites (hard gate)

`claude -p` sessions are top-level and cannot prompt for permissions. All patterns below must exist in `~/.claude/settings.json` `permissions.allow`. **Stop immediately if any are missing.**

```json
"Bash(gh pr view:*)", "Bash(gh pr diff:*)", "Bash(gh pr list:*)",
"Bash(gh api:*)", "Bash(gh pr review:*)",
"Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)", "Bash(mkdir:*)",
"Read(~/.claude/commands/**)", "Read(~/.claude/learnings/**)",
"Read(~/.claude/learnings-private/**)", "Read(~/.claude/skill-references/**)",
"Read(~/.claude/commands/set-persona/**)",
"Read(~/**/tmp/sweep-reviews/**)",
"Write(~/**/tmp/change-request-replies/**)", "Write(~/**/tmp/sweep-reviews/**)",
"Edit(~/**/tmp/sweep-reviews/**)"
```

If missing, report with `BLOCKED:` prefix listing each missing pattern. Do not continue until resolved.

## Reference Files

- @~/.claude/skill-references/platform-detection.md — GitHub vs GitLab detection
- `~/.claude/skill-references/{github,gitlab}/pr-management.md` — PR fetch commands
- `~/.claude/skill-references/parallel-claude-runner-template.sh` — Bash template for let-it-rip.sh generation
- `~/.claude/skill-references/sweep-scaffold.md` — Shared artifact structure, watermark logic, result/learnings patterns, announce/progress/retro formats

## Instructions

### Phase 0: Verify Prerequisites

Read `~/.claude/settings.json`, check every required pattern is present (exact string match). Also verify **Write/Edit parity**: every `Write(...)` pattern in the prerequisites that targets files the `claude -p` session will update (not just create) must have a matching `Edit(...)` pattern. Stop if any missing.

### Phase 1: Parse Arguments

- **PR numbers**: regex `#(\d+)` → `PR_NUMBERS[]`
- **`--max=<N>`** → `MAX_PRS` (default 20)
- **`--concurrency=<N>`** → `CONCURRENCY` (default 3)
- **`--include-drafts`** → `INCLUDE_DRAFTS` (default false)

### Phase 2: Platform Detection & PR Fetch

Follow `platform-detection.md`. Then fetch open PRs:
- Specific numbers: `gh pr view <N> --json number,title,headRefName,baseRefName,url,state,isDraft,reviews,comments`
- All open: `gh pr list --state open --json number,title,headRefName,baseRefName,url,isDraft --limit <MAX_PRS>`, then fetch `reviews,comments` per PR separately

### Phase 3: Filter and Skip Detection

For each PR:

**a.** `isDraft && !INCLUDE_DRAFTS` → `SKIP(Draft)`

**b.** Scan reviews for `Role:.*Team-Reviewer`. If found, store `LAST_REVIEW_TS`. Check for activity since:
- Commits after `LAST_REVIEW_TS`
- Non-self reviews or comments after `LAST_REVIEW_TS`

No activity → `SKIP(Reviewed, no activity since <ts>)`
New activity → `RE-REVIEW` (eligible)

**c.** No prior team review → `FIRST-REVIEW` (eligible)

### Phase 4: Stacked PR Detection

Check if any PR's `baseRefName` matches another's `headRefName`. Record `stacked_on` / `stacked_by` in manifest. All stacked PRs are still reviewed independently.

### Phase 5: Present Summary

```
Assessed N PRs. M eligible, K skipped:

| # | Title | Mode | Stack | Skip Reason |
|---|-------|------|-------|-------------|
| 47 | Add auth middleware | First review | -- | -- |
| 46 | Fix race condition | Re-review | -- | -- |
| 45 | Update deps | Skip | -- | No activity since review |
| 43 | Auth tokens | First review | -> #47 | -- |

Generate let-it-rip.sh for M PRs (concurrency: CONCURRENCY)?
```

Wait for confirmation. Operator may exclude PRs before proceeding.

### Phase 6: Generate Artifacts

Create run directory: `tmp/sweep-reviews/$(date +%Y-%m-%d-%H%M)` with a `pr-<N>/` subdirectory per eligible PR. Follow **Artifact Structure** in `sweep-scaffold.md`.

#### manifest.json

```json
{
  "created_at": "<ISO>",
  "run_dir": "<RUN_DIR>",
  "concurrency": <N>,
  "owner_repo": "<owner/repo>",
  "eligible": [
    {"number": 47, "title": "...", "mode": "first-review", "url": "...", "stacked_on": null, "stacked_by": [43]}
  ],
  "skipped": [
    {"number": 45, "reason": "Reviewed, no activity since 2026-03-27T10:00:00Z"}
  ]
}
```

#### pr-\<N\>/prompt.txt

Follow **Prompt Watermark & Skip Logic** (steps 1-4) from `sweep-scaffold.md`, using `last_reviewed_sha` as the watermark key. Then continue with review-specific steps:

5. **Invoke team review.** Skill tool: `skill="git:team-review-request"`, `args="<N>"`. Update `status.md` milestone to `reviewing`, then `posted` after the review is posted.

6. **Append to `result.md`.** Follow **Result & Learnings Append Pattern** in `sweep-scaffold.md`. Mode-specific fields:

   | Field | Value |
   |-------|-------|
   | Mode | first-review / re-review |
   | Personas | `<list>` |
   | Findings | `<count>` |
   | Inline Comments | `<count>` |
   | Review URL | `<url or N/A>` |

7. **Append to `learnings.md`** and **update `status.md` watermark** per scaffold.

#### let-it-rip.sh

Follow **let-it-rip.sh Generation** in `sweep-scaffold.md` with `{{MODE}}` → `review`. Remove `{{#BRANCHES}}...{{/BRANCHES}}` and `{{#WORKTREES}}...{{/WORKTREES}}` blocks (review mode doesn't use worktrees).

### Phase 7: Announce, Progress Check, Retro

Follow the corresponding sections in `sweep-scaffold.md`. Retro table includes stacked PR relationships.

## Important Notes

- **Concurrency depth.** Default 3 x up to 3 reviewer subagents = 9 concurrent API sessions. Lower if hitting rate limits.
- **No auto-approve.** Reviews post as COMMENT. Operator decides the verdict.
- **Stacked PRs.** Reviewed independently against their base branch. No ordering needed.
- See **Shared Important Notes** in `sweep-scaffold.md` for rerunnable, rate limits, crash recovery, and cleanup.
