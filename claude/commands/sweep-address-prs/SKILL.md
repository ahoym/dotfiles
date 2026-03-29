---
name: sweep-address-prs
description: "Assess open PRs with unaddressed review comments and generate a parallel addressing script — produces manifest.json and let-it-rip.sh for address-request-comments execution."
argument-hint: "[#47 #46] [--max=20] [--concurrency=3] [--resolve-conflicts]"
---

## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Current branch: !`git branch --show-current 2>/dev/null`
- Remote: !`git remote get-url origin 2>/dev/null`

# Sweep Address PRs

Assess open PRs for unaddressed review comments, then generate `let-it-rip.sh` — a bash script that launches parallel `claude -p` sessions in isolated worktrees, each invoking `/git:address-request-comments`.

1. **Assessment** (this skill, run once) — produces manifest + let-it-rip.sh + per-PR prompts
2. **Execution** (rerunnable) — operator runs `bash let-it-rip.sh` from terminal, repeatedly if needed

`let-it-rip.sh` is the loop target, not this skill. Each `claude -p` session invokes `address-request-comments`, which has its own quiet no-op detection — if no new comments exist since the last addressing pass, the session exits cleanly with `status=skipped`. Run the same script after each review cycle until all conversations converge.

## Usage

- `/sweep-address-prs` — all open PRs with unaddressed comments (up to 20)
- `/sweep-address-prs #47 #46` — specific PRs
- `/sweep-address-prs --max=10 --concurrency=2`
- `/sweep-address-prs --resolve-conflicts` — also resolve merge conflicts with base branch before addressing

## Prerequisites (hard gate)

`claude -p` sessions are top-level and cannot prompt for permissions. All patterns below must exist in `~/.claude/settings.json` `permissions.allow`. **Stop immediately if any are missing.**

```json
"Bash(gh pr view:*)", "Bash(gh pr diff:*)", "Bash(gh pr list:*)",
"Bash(gh api:*)", "Bash(gh pr review:*)", "Bash(gh pr comment:*)",
"Bash(git add:*)", "Bash(git branch:*)", "Bash(git checkout:*)",
"Bash(git commit:*)", "Bash(git diff:*)", "Bash(git log:*)",
"Bash(git fetch:*)", "Bash(git merge:*)", "Bash(git push:*)",
"Bash(git rebase:*)", "Bash(git status:*)",
"Bash(mkdir:*)",
"Read(~/.claude/commands/**)", "Read(~/.claude/learnings/**)",
"Read(~/.claude/learnings-private/**)", "Read(~/.claude/skill-references/**)",
"Read(~/**/tmp/sweep-address/**)",
"Write(~/**/tmp/change-request-replies/**)", "Write(~/**/tmp/sweep-address/**)",
"Edit(~/**/tmp/sweep-address/**)"
```

If missing, report with `BLOCKED:` prefix listing each missing pattern. Do not continue until resolved.

## Reference Files

- @~/.claude/skill-references/platform-detection.md — GitHub vs GitLab detection
- `~/.claude/skill-references/{github,gitlab}/pr-management.md` — PR fetch commands
- `~/.claude/skill-references/parallel-claude-runner-template.sh` — Bash template for let-it-rip.sh generation

## Instructions

### Phase 0: Verify Prerequisites

Read `~/.claude/settings.json`, check every required pattern is present (exact string match). Stop if any missing.

### Phase 1: Parse Arguments

- **PR numbers**: regex `#(\d+)` → `PR_NUMBERS[]`
- **`--max=<N>`** → `MAX_PRS` (default 20)
- **`--concurrency=<N>`** → `CONCURRENCY` (default 3)
- **`--resolve-conflicts`** → `RESOLVE_CONFLICTS` (default false) — resolve merge conflicts with base branch before addressing comments

### Phase 2: Platform Detection & PR Fetch

Follow `platform-detection.md`. Then fetch open PRs:
- Specific numbers: `gh pr view <N> --json number,title,headRefName,baseRefName,url,state,isDraft,mergeable,reviews,comments`
- All open: `gh pr list --state open --json number,title,headRefName,baseRefName,url,isDraft,mergeable --limit <MAX_PRS>`, then fetch `reviews,comments` per PR separately

For each PR, also fetch inline review comments:
`gh api repos/{owner}/{repo}/pulls/<N>/comments --paginate`

### Phase 3: Filter, Skip Detection, Worktree & Persona Discovery

**Worktree discovery:** Run `git worktree list` and build a map of branch → existing worktree path. For each eligible PR, check if a worktree already exists for its `headRefName` branch. If so, record the path for reuse — the address session will `cd` into it directly instead of creating a new worktree. Only PRs without an existing worktree need new worktree creation.

**Persona detection:** For each eligible PR, determine the best persona from available personas (glob `~/.claude/commands/set-persona/*.md`, excluding `SKILL.md`). Match based on:
1. PR title and branch name keywords (e.g., `claude-config`, `react`, `java`, `xrpl`)
2. Changed file paths from `gh pr diff --stat` (e.g., files under `claude/` → `claude-config-expert`, files under `src/components/` → `react-frontend`)
3. Review comment content domains

If no persona matches confidently, leave as `none` — the address session will proceed without a persona lens. Record the detected persona per PR for the summary and prompt generation.

For each PR:

**a.** No review comments at all → `SKIP(No comments)`

**b.** Check for `Role:.*Addresser` in comment replies. If found, store `LAST_ADDRESS_TS`. Check for new non-self comments since:
- New inline review comments after `LAST_ADDRESS_TS` not matching `Role:.*Addresser`
- New top-level comments after `LAST_ADDRESS_TS` not matching `Role:.*Addresser`

No new comments → `SKIP(Addressed, no new comments since <ts>)`
New comments → `NEEDS-ADDRESSING` (eligible)

**c.** No prior Addresser activity but review comments exist → `NEEDS-ADDRESSING` (eligible)

**d.** Draft PRs → `SKIP(Draft)` (drafts are unlikely to have actionable review comments)

**e.** If `RESOLVE_CONFLICTS` is true, check `mergeable` field from the PR fetch. Record `has_conflicts: true` for PRs where `mergeable == "CONFLICTING"`. This is informational during assessment — conflict resolution happens in the `claude -p` session, not here.

### Phase 4: Present Summary

```
Assessed N PRs. M eligible, K skipped:

| # | Title | Mode | Persona | Conflicts | Worktree | Skip Reason |
|---|-------|------|---------|-----------|----------|-------------|
| 47 | Add auth middleware | New comments | java-backend | yes | reuse: .claude/worktrees/agent-abc123 | -- |
| 46 | Fix race condition | First pass | react-frontend | no | new | -- |
| 45 | Update deps | Skip | -- | -- | -- | Addressed, no new comments |
| 43 | Auth tokens | Skip | -- | -- | -- | No comments |

Generate let-it-rip.sh for M PRs (concurrency: CONCURRENCY)?
```

The **Conflicts** column only appears when `--resolve-conflicts` is passed. When absent, omit the column entirely.

Wait for confirmation. Operator may exclude PRs before proceeding.

### Phase 5: Generate Artifacts

Create run directory: `tmp/sweep-address/$(date +%Y-%m-%d-%H%M)` with a `pr-<N>/` subdirectory per eligible PR.

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
    ├── result.md       # append-only addressing rounds (written by claude -p)
    └── learnings.md    # append-only observations (written by claude -p)
```

#### manifest.json

```json
{
  "created_at": "<ISO>",
  "run_dir": "<RUN_DIR>",
  "concurrency": <N>,
  "resolve_conflicts": true,
  "owner_repo": "<owner/repo>",
  "eligible": [
    {"number": 47, "title": "...", "mode": "new-comments", "url": "...", "branch": "feat/auth", "base": "main", "has_conflicts": true, "worktree": "/path/to/existing/worktree", "worktree_reused": true, "persona": "java-backend"},
    {"number": 46, "title": "...", "mode": "first-pass", "url": "...", "branch": "fix/race", "base": "main", "has_conflicts": false, "worktree": "<RUN_DIR>/worktrees/pr-46", "worktree_reused": false, "persona": "react-frontend"}
  ],
  "skipped": [
    {"number": 45, "reason": "Addressed, no new comments since 2026-03-27T10:00:00Z"}
  ]
}
```

The `resolve_conflicts`, `base`, and `has_conflicts` fields are only present when `--resolve-conflicts` is passed. `has_conflicts` reflects the assessment-time `mergeable` state — the session checks again at runtime since the state may change.

#### pr-\<N\>/prompt.txt

Each prompt tells the `claude -p` session to:

1. **Read directives.** Read `${RUN_DIR}/directives.md` and `${PR_DIR}/directives.md` if they exist. These are instructions from the directors (operator + orchestrating agent) — incorporate them into this addressing pass. Directives may override skip logic (e.g., "address even if watermark matches"), add focus areas, or provide context not visible in the PR itself.

2. **Read existing watermark.** If `status.md` exists, read `last_addressed_sha` and `last_comment_id`. If it doesn't exist, this is the first run — proceed to step 4.

3. **Compare against current PR state.** Fetch the PR's current HEAD SHA and latest review comment ID via `gh`. Compare against watermark values:
   - HEAD SHA differs OR latest comment ID differs → new addressing needed, proceed to step 4
   - Both match AND no directives → no changes since last pass, set `milestone: skipped` in `status.md` and exit
   - Both match BUT directives present → directives override skip, proceed to step 4

4. **Update `status.md`** with `milestone: started` and current timestamp.

5. **`cd` into the worktree directory** (passed as a variable in the prompt — either a reused existing worktree path or `<RUN_DIR>/worktrees/pr-<N>` for newly created ones).

6. **Resolve conflicts (conditional).** Only when `resolve_conflicts` is true in manifest. Invoke Skill tool: `skill="git:resolve-conflicts"`, `args="<base-branch>"` where `<base-branch>` is the PR's `baseRefName`. Update `status.md` milestone to `resolving-conflicts`. If resolve-conflicts reports no conflicts, proceed. If it resolves conflicts successfully, it will push the result — update milestone to `conflicts-resolved` and proceed. If it fails, update milestone to `conflict-resolution-failed`, append error to `result.md`, and exit.

7. **Activate persona.** If a persona was detected, invoke Skill tool: `skill="set-persona"`, `args="<persona-name>"` to activate the domain lens before addressing.

8. **Invoke address skill.** Skill tool: `skill="git:address-request-comments"`, `args="<N>"`. Update `status.md` milestone to `addressing`, then `pushing`, then `done`.

9. **Append to `result.md`.** Add a new dated section (append, do not overwrite):

   ```markdown
   ## Address — <ISO timestamp>

   **Trigger**: <first run | N new comments since last pass | new commits (old_sha → new_sha) | both | directive>

   | Field | Value |
   |-------|-------|
   | Status | success / skipped / error |
   | Conflicts resolved | yes / no / n/a |
   | Auto-implemented | <count> |
   | Escalated | <count> |
   | Commits | <count> |
   | Addressed SHA | <HEAD SHA> |
   | Last Comment ID | <latest comment ID> |
   | Error | <none or message> |
   ```

   On the very first run, also prepend a file header before the first section:

   ```markdown
   # PR #<N> — <title>
   ```

10. **Append to `learnings.md`.** Add a dated section with patterns discovered, code quality observations, review interaction notes. Write "No learnings from this pass." if nothing notable.

11. **Update `status.md` watermark.** Write final status:

    ```yaml
    milestone: done  # or errored / skipped
    pr: <N>
    last_addressed_sha: <HEAD SHA at time of addressing>
    last_comment_id: <latest comment ID at time of addressing>
    updated_at: <ISO timestamp>
    ```

Error handling: always write all artifacts before exiting, even on failure. On error, still update `status.md` watermark with `milestone: errored` so the next run retries.

#### let-it-rip.sh

Read `@~/.claude/skill-references/parallel-claude-runner-template.sh` and generate `let-it-rip.sh` by filling placeholders:
- `{{MODE}}` → `address`
- `{{RUN_DIR}}` → absolute path to run directory
- `{{CONCURRENCY}}` → from parsed arguments
- `{{PRS}}` → space-separated eligible PR numbers
- `{{TIMESTAMP}}` → current timestamp
- `{{PROJECT_ROOT}}` → absolute path to repo root
- `{{BRANCH_CASES}}` → case statements mapping PR numbers to branch names (e.g., `48) echo "feat/auth" ;;`)
- `{{WORKTREE_CASES}}` → case statements mapping PR numbers to worktree paths (reused or new)
- `{{NEW_WORKTREE_PRS}}` → space-separated PR numbers that need new worktrees (empty if all reused)
- Keep `{{#BRANCHES}}...{{/BRANCHES}}` and `{{#WORKTREES}}...{{/WORKTREES}}` blocks (address mode uses worktrees)

### Phase 6: Announce

```
Artifacts written to <RUN_DIR>/

  manifest.json    — <M> eligible, <K> skipped
  let-it-rip.sh    — concurrency: <CONCURRENCY>
  pr-<N>/          — <M> PR directories with prompts

To launch:        bash <RUN_DIR>/let-it-rip.sh
Re-run (loop):    bash <RUN_DIR>/let-it-rip.sh  (same command — sessions with no new comments exit cleanly)
Progress:         "Check progress on <RUN_DIR>"
Retro:            "Retro on <RUN_DIR>"
```

## Post-Execution: Progress Check

Read all `pr-*/status.md` files, present:

| PR | Milestone | Started |
|----|-----------|---------|
| #47 | addressing | 2m ago |
| #46 | pushing | 1m ago |

## Post-Execution: Retro

Read `manifest.json`, all `pr-*/result.md`, and all `pr-*/learnings.md`. Note that `result.md` and `learnings.md` are append-only — each run adds a dated section. Show the latest round per PR plus a round count:

| PR | Title | Rounds | Latest Status | Auto-implemented | Escalated | Commits |
|----|-------|--------|---------------|------------------|-----------|---------|
| #47 | Add auth | 2 | success | 1 | 0 | 1 |
| #46 | Fix race | 1 | success | 2 | 0 | 1 |

Include: skipped PRs, aggregated learnings by theme, and summary line.

## Important Notes

- **Concurrency depth.** Default 3. Each session works in its own worktree — no conflicts.
- **Worktree reuse.** During assessment, `git worktree list` is checked for existing worktrees on each PR's branch. If found (e.g., from a prior review sweep), the address session reuses that worktree — no creation or cleanup needed. Only PRs without an existing worktree get new ones created under `<RUN_DIR>/worktrees/`. New worktrees are cleaned up after completion (or on Ctrl+C via trap); reused worktrees are left untouched.
- **Rerunnable.** `let-it-rip.sh` is the loop target — run it repeatedly as review conversations evolve. New worktree setup is idempotent (existing ones pull latest). Each `claude -p` session reads the watermark from `status.md` (last addressed SHA + last comment ID) and compares against current PR state — if nothing changed, it skips; if new activity exists, it performs a new pass and appends a dated section to `result.md` and `learnings.md`.
- **Escalation.** `address-request-comments` auto-implements suggestions it agrees with and escalates disagreements. The retro surfaces escalated items for operator review.
- **Rate limits.** Detected per-session via log grep. `.rate-limited` sentinel signals the summary.
- **Crash recovery.** Missing result files → retro reports as "unknown/crashed" by diffing manifest against actual results.
- **Cleanup.** Run directories persist for retro. Remove manually: `rm -rf tmp/sweep-address/<timestamp>/`
