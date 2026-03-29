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

Create run directory: `tmp/sweep-reviews/$(date +%Y-%m-%d-%H%M)` with a `pr-<N>/` subdirectory per eligible PR.

**Artifact structure:**
```
<RUN_DIR>/
├── manifest.json
├── let-it-rip.sh
├── directives.md       # optional — global instructions from directors (read by all sessions)
└── pr-<N>/
    ├── prompt.txt      # input to claude -p
    ├── directives.md   # optional — per-PR instructions from directors (read by this session)
    ├── output.log      # stdout+stderr (written by let-it-rip.sh)
    ├── status.md       # watermark + milestone (written by claude -p)
    ├── result.md       # append-only review rounds (written by claude -p)
    └── learnings.md    # append-only observations (written by claude -p)
```

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

Each prompt tells the `claude -p` session to:

1. **Read directives.** Read `${RUN_DIR}/directives.md` and `${PR_DIR}/directives.md` if they exist. These are instructions from the directors (operator + orchestrating agent) — incorporate them into this review pass. Directives may override skip logic (e.g., "review even if watermark matches"), add focus areas, or provide context not visible in the PR itself.

2. **Read existing watermark.** If `status.md` exists, read `last_reviewed_sha` and `last_comment_id`. If it doesn't exist, this is the first run — proceed to step 4.

3. **Compare against current PR state.** Fetch the PR's current HEAD SHA and latest comment ID via `gh`. Compare against watermark values:
   - HEAD SHA differs OR latest comment ID differs → new review needed, proceed to step 4
   - Both match AND no directives → no changes since last review, set `milestone: skipped` in `status.md` and exit
   - Both match BUT directives present → directives override skip, proceed to step 4

4. **Update `status.md`** with `milestone: started` and current timestamp.

5. **Invoke team review.** Skill tool: `skill="git:team-review-request"`, `args="<N>"`. Update `status.md` milestone to `reviewing`, then `posted` after the review is posted.

6. **Append to `result.md`.** Add a new dated section (append, do not overwrite):

   ```markdown
   ## Review — <ISO timestamp>

   **Trigger**: <first run | N new commits (old_sha → new_sha) | N new comments | both>

   | Field | Value |
   |-------|-------|
   | Status | success / skipped / error |
   | Mode | first-review / re-review |
   | Personas | <list> |
   | Findings | <count> |
   | Inline Comments | <count> |
   | Review URL | <url or N/A> |
   | Reviewed SHA | <HEAD SHA> |
   | Last Comment ID | <latest comment ID> |
   | Error | <none or message> |
   ```

   On the very first run, also prepend a file header before the first section:

   ```markdown
   # PR #<N> — <title>
   ```

7. **Append to `learnings.md`.** Add a dated section with surprising patterns, architectural observations, recurring issues, or skill performance notes. Write "No learnings from this review." if nothing notable.

8. **Update `status.md` watermark.** Write final status:

   ```yaml
   milestone: done  # or errored / skipped
   pr: <N>
   last_reviewed_sha: <HEAD SHA at time of review>
   last_comment_id: <latest comment ID at time of review>
   updated_at: <ISO timestamp>
   ```

Error handling: always write all artifacts before exiting, even on failure. On error, still update `status.md` watermark with `milestone: errored` so the next run retries.

#### let-it-rip.sh

Read `@~/.claude/skill-references/parallel-claude-runner-template.sh` and generate `let-it-rip.sh` by filling placeholders:
- `{{MODE}}` → `review`
- `{{RUN_DIR}}` → absolute path to run directory
- `{{CONCURRENCY}}` → from parsed arguments
- `{{PRS}}` → space-separated eligible PR numbers
- `{{TIMESTAMP}}` → current timestamp
- Remove `{{#BRANCHES}}...{{/BRANCHES}}` and `{{#WORKTREES}}...{{/WORKTREES}}` blocks (review mode doesn't use worktrees)

### Phase 7: Announce

```
Artifacts written to <RUN_DIR>/

  manifest.json    — <M> eligible, <K> skipped
  let-it-rip.sh    — concurrency: <CONCURRENCY>
  pr-<N>/          — <M> PR directories with prompts

To launch:        bash <RUN_DIR>/let-it-rip.sh
Re-run (loop):    bash <RUN_DIR>/let-it-rip.sh  (same command — sessions with no changes since last review exit cleanly)
Progress:         "Check progress on <RUN_DIR>"
Retro:            "Retro on <RUN_DIR>"
```

## Post-Execution: Progress Check

Read all `pr-*/status.md` files, present:

| PR | Milestone | Started |
|----|-----------|---------|
| #47 | reviewing | 2m ago |
| #46 | posted | 1m ago |

## Post-Execution: Retro

Read `manifest.json`, all `pr-*/result.md`, and all `pr-*/learnings.md`. Note that `result.md` and `learnings.md` are append-only — each run adds a dated section. Show the latest round per PR plus a round count:

| PR | Title | Rounds | Latest Mode | Personas | Findings | Status |
|----|-------|--------|-------------|----------|----------|--------|
| #47 | Add auth | 2 | Re-review | security, java | 2 | Posted |
| #46 | Fix race | 1 | First | go, security | 5 | Posted |

Include: skipped PRs from assessment, stacked PR relationships, aggregated learnings grouped by theme, and summary line.

## Important Notes

- **Concurrency depth.** Default 3 x up to 3 reviewer subagents = 9 concurrent API sessions. Lower if hitting rate limits.
- **No auto-approve.** Reviews post as COMMENT. Operator decides the verdict.
- **Rerunnable.** `let-it-rip.sh` is the loop target — run it repeatedly after address passes. The pre-flight state check skips merged/closed PRs. Each `claude -p` session reads the watermark from `status.md` (last reviewed SHA + last comment ID) and compares against current PR state — if nothing changed, it skips; if the PR moved, it performs a new review and appends a dated section to `result.md` and `learnings.md`.
- **Stacked PRs.** Reviewed independently against their base branch. No ordering needed.
- **Rate limits.** Detected per-session via log grep. `.rate-limited` sentinel signals the summary. Running sessions are not killed.
- **Crash recovery.** Missing result files (hard crash) → retro reports as "unknown/crashed" by diffing manifest against actual results.
- **Cleanup.** Run directories persist for retro. Remove manually: `rm -rf tmp/sweep-reviews/<timestamp>/`
