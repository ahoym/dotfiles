---
name: address-prs
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

- `/sweep:address-prs` — all open PRs with unaddressed comments (up to 20)
- `/sweep:address-prs #47 #46` — specific PRs
- `/sweep:address-prs --max=10 --concurrency=2`
- `/sweep:address-prs --resolve-conflicts` — also resolve merge conflicts with base branch before addressing

## Prerequisites (hard gate)

`claude -p` sessions are top-level and cannot prompt for permissions. All patterns below must exist in `~/.claude/settings.json` `permissions.allow`. **Stop immediately if any are missing.**

Detect platform first (see Phase 2), then check the matching CLI patterns:

**GitHub patterns:**
```json
"Bash(gh pr view:*)", "Bash(gh pr diff:*)", "Bash(gh pr list:*)",
"Bash(gh api:*)", "Bash(gh pr review:*)", "Bash(gh pr comment:*)"
```

**GitLab patterns:**
```json
"Bash(glab mr view:*)", "Bash(glab mr diff:*)", "Bash(glab mr list:*)",
"Bash(glab api:*)", "Bash(glab mr note:*)", "Bash(glab mr update:*)"
```

**Shared patterns (both platforms):**
```json
"Bash(git add:*)", "Bash(git branch:*)", "Bash(git checkout:*)",
"Bash(git commit:*)", "Bash(git diff:*)", "Bash(git log:*)",
"Bash(git fetch:*)", "Bash(git merge:*)", "Bash(git push:*)",
"Bash(git rebase:*)", "Bash(git status:*)",
"Bash(mkdir:*)", "Bash(jq *)",
"Bash(cp ~/.claude/skill-references/**)",
"Bash(bash ~/.claude/skill-references/**)",
"Read(~/.claude/commands/**)", "Read(~/.claude/learnings*/**)",
"Read(~/.claude/learnings-providers.json)", "Read(~/.claude/skill-references/**)",
"Read(~/**/tmp/claude-artifacts/**)",
"Read(tmp/claude-artifacts/**)",
"Write(~/**/tmp/claude-artifacts/**)",
"Edit(~/**/tmp/claude-artifacts/**)"
```

If missing, report with `BLOCKED:` prefix listing each missing pattern. Do not continue until resolved.

## Reference Files

- @~/.claude/skill-references/platform-detection.md — GitHub vs GitLab detection
- `~/.claude/skill-references/{github,gitlab}/pr-management.md` — PR fetch commands
- `~/.claude/skill-references/parallel-claude-runner-template.sh` — Bash template for let-it-rip.sh generation
- `~/.claude/skill-references/fill-template.sh` — Bash assembly for prompt generation (replaces LLM string substitution)
- @~/.claude/skill-references/sweep-scaffold.md — Shared artifact structure, watermark logic, result/learnings patterns, announce/progress/retro formats
- `addresser-prompt.md` — Prompt template for address agents (assembled by fill-template.sh)

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

**Persona detection:** List available personas via `ls ~/.claude/commands/set-persona/*.md` (do NOT use the Glob tool — it fails to resolve symlinked `~/.claude/` paths). Exclude `SKILL.md`. If the listing returns zero files, **warn the operator**: "⚠ No persona files found at `~/.claude/commands/set-persona/` — check path resolution. Proceeding without personas." For each eligible PR, match the best persona based on:
1. PR title and branch name keywords (e.g., `claude-config`, `react`, `java`, `xrpl`)
2. Changed file paths from `gh pr diff --stat` (e.g., files under `claude/` → `claude-config-expert`, files under `src/components/` → `react-frontend`)
3. Review comment content domains

If no persona matches confidently, leave as `none`. Record the detected persona per PR for the summary and prompt generation.

**Explicit selection bypasses skip filtering** — all specified PRs are eligible (still detect mode for prompt generation). Exception: `SKIP(No comments)` applies even with explicit selection unless in compound mode.

When no specific PRs are given (all-open mode), apply skip filtering per PR:

**a.** No review comments at all → `SKIP(No comments)`. Exception: in compound mode (review+address via director), generate artifacts anyway — the review will post comments before the address runner launches.

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

Generating let-it-rip.sh for M PRs (concurrency: CONCURRENCY)...
```

The **Conflicts** column only appears when `--resolve-conflicts` is passed. When absent, omit the column entirely.

Proceed directly to artifact generation — do not wait for confirmation.

### Phase 5: Generate Artifacts

Create run directory: `tmp/claude-artifacts/sweep-address/<YYYY-MM-DD-HHMM>` with a `pr-<N>/` subdirectory per eligible PR. Compute the timestamp in a separate Bash call first (`date +%Y-%m-%d-%H%M`), then use the literal value in `mkdir` — `$()` subshells in Bash commands break permission pattern matching. Follow **Artifact Structure** in `sweep-scaffold.md`.

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

#### Data files & prompt assembly

Write data files for template assembly, then call `fill-template.sh`:

1. **Per-PR files** in `pr-<N>/`:
   - `metadata.json`:
     ```json
     {
       "PR_NUMBER": "<number>",
       "PR_TITLE": "<title>",
       "PR_URL": "<url>",
       "OWNER_REPO": "<owner/repo>",
       "BRANCH": "<head branch>",
       "BASE": "<base branch>",
       "MODE": "first-pass or new-comments",
       "RESOLVE_CONFLICTS": "true or false",
       "HAS_CONFLICTS": "true or false",
       "WORKTREE_PATH": "<absolute path to worktree>",
       "PERSONA_INSTRUCTION": "<persona activation text — see below>",
       "RUN_DIR": "<absolute path>",
       "PR_DIR": "<absolute path>",
       "LAST_SHA_FIELD": "last_addressed_sha"
     }
     ```

   **`PERSONA_INSTRUCTION` value:**
   - If persona detected: `Read ~/.claude/commands/set-persona/<name>.md and adopt its priorities, tradeoffs, and domain focus.`
   - If none: `No persona was detected during assessment. If a directive specifies a persona, read that persona file. Otherwise proceed without a persona lens.`

2. **Copy shared preflight** to run directory (for `{@../sweep-pr-preflight.md}` inclusion):
   ```bash
   cp ~/.claude/skill-references/sweep-pr-preflight.md <RUN_DIR>/sweep-pr-preflight.md
   ```

3. **Assemble prompt:**
   ```bash
   bash ~/.claude/skill-references/fill-template.sh addresser-prompt.md <RUN_DIR>/pr-<N> > <RUN_DIR>/pr-<N>/prompt.txt
   ```

#### let-it-rip.sh

Follow **let-it-rip.sh Generation** in `sweep-scaffold.md` with `{{MODE}}` → `address` and `{{MODEL}}` → `claude-opus-4-6` (this runner is a leaf — it reads diffs, edits files, runs git, and pushes commits itself). Additionally fill `{{PROJECT_ROOT}}`, `{{BRANCH_CASES}}`, `{{WORKTREE_CASES}}`, `{{NEW_WORKTREE_PRS}}` and keep `{{#BRANCHES}}...{{/BRANCHES}}` and `{{#WORKTREES}}...{{/WORKTREES}}` blocks.

The worktree setup loop (`setup_worktrees`) must also include the pre-flight state check from the scaffold, before fetching or creating worktrees. Without it, the script fails on `git fetch` for merged branches before the launch loop's skip ever fires.

### Phase 6: Announce, Progress Check, Retro

Follow the corresponding sections in `sweep-scaffold.md`. Mode-specific retro table columns:

| PR | Title | Rounds | Latest Status | Auto-implemented | Escalated | Commits |
|----|-------|--------|---------------|------------------|-----------|---------|

## Important Notes

- **Self-filter by Role tag, not username.** The authenticated glab/gh username may match the team-review poster (operator runs both review and address). Self-filter must use `Role:.*Addresser` in the structured footnote, not the username. Comments with `Role:.*Reviewer` or `Role:.*Team-Reviewer` from the same username are reviewer comments that must be addressed.
- **Concurrency depth.** Default 3. Each session works in its own worktree — no conflicts.
- **Worktree reuse.** During assessment, `git worktree list` is checked for existing worktrees on each PR's branch. If found, the address session reuses that worktree — no creation or cleanup needed. Only PRs without an existing worktree get new ones under `<RUN_DIR>/worktrees/`. New worktrees are cleaned up after completion (or on Ctrl+C via trap); reused worktrees are left untouched.
- **Escalation.** `address-request-comments` auto-implements suggestions it agrees with and escalates disagreements. The retro surfaces escalated items for operator review.
- **Conflict monitoring (director responsibility).** When running address sweeps in a loop, the director should read `mergeable` from review `status.md` files each cycle. If CONFLICTING on an open PR, write a directive to `<ADDRESS_RUN_DIR>/pr-<N>/directives.md` instructing the session to resolve conflicts before addressing. Directive format:
  ```markdown
  ## <ISO timestamp>
  PR has merge conflicts with base branch. Invoke `/git:resolve-conflicts <base-branch>` before addressing comments.
  ```
  This catches conflicts that develop between cycles (e.g., main advancing after a PR was last addressed). The address session reads directives in step 1 and acts on them.
- See **Shared Important Notes** in `sweep-scaffold.md` for rerunnable, rate limits, crash recovery, and cleanup.
