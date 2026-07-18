---
name: work-items
description: "Assess open work items (GitHub Issues, GitLab Issues, or Jira tickets) and generate a parallel execution script — produces manifest.json and let-it-rip.sh for implement/clarify execution."
argument-hint: "[#12 #15 | PROJ-101 PROJ-102 | --epic=PROJ-100] [--label=bug] [--source=jira|github|gitlab] [--max=10] [--concurrency=5]"
---

## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Current branch: !`git branch --show-current 2>/dev/null`
- HEAD: !`git rev-parse --short HEAD 2>/dev/null`
- Remote: !`git remote get-url origin 2>/dev/null`

# Sweep Work Items

Assess open work items, then generate `let-it-rip.sh` — a bash script that launches parallel `claude -p` sessions, each implementing or clarifying a work item.

Supported sources:
- **GitHub Issues** (default when args are `#N` and remote is `github.com`)
- **GitLab Issues** (default when args are `#N` and remote is GitLab)
- **Jira** (when args are Jira keys like `PROJ-101` or `--epic=PROJ-XXX`)

1. **Assessment** (this skill, run once) — produces manifest + let-it-rip.sh + per-item prompts
2. **Execution** (rerunnable) — operator runs `bash let-it-rip.sh`, repeatedly if needed

Each `claude -p` session checks its watermark before working — if nothing changed since the last run, the session exits cleanly.

**Lifecycle:** clarify → confirm → implement. Every item starts at clarify. Implementation requires passing through the confirm gate — no exceptions.

## Usage

| Form | Effect |
|---|---|
| `/sweep:work-items` | All open issues (GH/GL, up to 30) |
| `/sweep:work-items #12 #15 #20` | Specific GH/GL issues |
| `/sweep:work-items PROJ-101 PROJ-102` | Specific Jira tickets |
| `/sweep:work-items --epic=PROJ-100` | All children of a Jira epic |
| `/sweep:work-items --label=bug` | Filter by label (works on all sources) |
| `/sweep:work-items --jql='project=PROJ AND status=Open'` | Arbitrary JQL (Jira only) |
| `/sweep:work-items --source=jira` | Override source detection |
| `/sweep:work-items --no-claim` | Jira: skip implement-time assign + sprint mutation |
| `/sweep:work-items --max=10` / `--concurrency=3` | Caps |

Flags combine.

## Source detection

Phase 1 resolves source by argument shape:

| Signal | Source |
|---|---|
| Any arg matches `[A-Z]+-\d+` (Jira key) or `--epic=[A-Z]+-\d+` | `jira` |
| Args contain `#\d+` AND remote contains `github.com` | `github` |
| Args contain `#\d+` AND remote is GitLab | `gitlab` |
| No item-specific args, remote determines `github` or `gitlab` | `github` or `gitlab` |
| `--source=<jira\|github\|gitlab>` | overrides detection |

**Mixed-source unsupported.** A single invocation must be all one source. If detection finds both Jira keys and `#N`-style args, error with `BLOCKED: mixed sources detected — split into separate invocations`.

## Platform contract

Per-source behaviour lives in `platform-<source>.md` (`platform-github.md`, `platform-gitlab.md`, `platform-jira.md`). Each platform file follows the same core contract below — read the matching file once Phase 1 resolves the source. `platform-jira.md` adds one extra section (§ 10 Implement-time ticket mutation), shifting Branch naming to § 11 there.

| § | Section | Used in |
|---|---|---|
| 1 | Detection signals | Phase 1 (this file) |
| 2 | Fetch single item | Phase 2 |
| 3 | Fetch list | Phase 2 |
| 4 | Fetch comments | Phase 2 |
| 5 | State mapping (→ `OPEN` / `CLOSED`) | Phase 3a |
| 6 | Blocked-by detection | Phase 3a2 |
| 7 | Linked-PR detection | Phase 3b |
| 8 | Comment posting (`POST_ISSUE_COMMENT_CMD`) | Phase 5 |
| 9 | Watermark fields | Phase 3c |
| 10 | Implement-time ticket mutation — **platform-jira.md only** | Phase 5 |
| 10 / 11 | Branch naming (`sweep/<id-or-key>-<slug>`) — § 10 in github/gitlab, § 11 in jira | Phase 5 |

Plus a "Permissions" appendix listing the `~/.claude/settings.json` patterns required when that source is in use.

**Blocked-by shared parse rule (github + gitlab).** Both git-host sources extract blocker refs from the issue body/description identically — `platform-github.md` § 6 and `platform-gitlab.md` § 6 point here rather than restating it:
- Lines matching `^Blocked by:` (case-insensitive) → extract `#(\d+)` from each
- Inside `## Dependencies` / `## Blocked by` headed sections → extract `#(\d+)` from any line

Each platform's § 6 then adds only its own blocker-resolution commands (GitLab additionally prefers typed `is_blocked_by` REST links). `platform-jira.md` § 6 does not use this rule — Jira resolves blockers via typed issue links (`jira-issue-mapping.md` § Blocked-by detection).

**Adding a new source** (Linear, Asana, etc.) means adding `platform-<name>.md` answering all core sections plus permissions — no surgery on this SKILL.md beyond the source-detection table.

## Prerequisites (hard gate)

`claude -p` sessions are top-level and cannot prompt for permissions. All patterns required by the resolved source must exist in `~/.claude/settings.json` `permissions.allow`. **Stop immediately if any are missing.**

> **Why global settings only?** Worktree agents don't have access to project-level `.claude/settings.local.json` (it's typically gitignored and not present in fresh worktree checkouts). Global settings are the only reliable permission source for `claude -p` sessions.

**Source-agnostic patterns (always required):**

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

**Source-specific patterns:** see `platform-<source>.md` § Permissions.

If missing, report with `BLOCKED:` prefix listing each missing pattern. Do not continue until resolved.

## Reference Files

- `~/.claude/skill-references/work-items-generate-runner.sh` — **Recommended entrypoint.** One bash call: assembles preflight + body/comments + per-issue prompts + runner. Inputs: `manifest.json`, `metadata.json`, `repo-summary.txt`, per-issue `metadata.json`. Auto-extracts `IMPLEMENT_ISSUES` from manifest and computes `PROJECT_ROOT`.
- `~/.claude/skill-references/work-items-runner-template.sh` — Work-items-specific runner template (issue-<N>/ dirs, parameterized `{{FETCH_ITEM_STATE_CMD}}` state check, `IMPLEMENT_ISSUES` array, conditional worktree setup, per-issue cwd). Used by work-items-generate-runner.sh.
- `~/.claude/skill-references/parallel-claude-runner-template.sh` — Generic PR-centric template (used by `sweep:address-prs` / `sweep:review-prs`). Do NOT use directly for work-items — it lacks issue semantics + worktree-from-main setup.
- `~/.claude/skill-references/fill-template.sh` — Bash assembly for prompt generation (replaces LLM string substitution)
- @~/.claude/skill-references/sweep-scaffold.md — Shared artifact structure, watermark logic, result/learnings patterns, **progress-check script**
- `~/.claude/skill-references/sweep-agent-preflight.md` — Shared preflight steps (1-5 + Work Item + Repo Context) for all agent prompts
- `platform-<source>.md` — per-source command set + contract
- `implementer-prompt.md` — Read when generating implementer prompts
- `clarifier-prompt.md` — Read when generating clarifier prompts
- `confirmer-prompt.md` — Read when generating clarify-confirm prompts (understanding + plan before implementation)

## Instructions

### Phase 0: Verify Prerequisites

Read `~/.claude/settings.json`, check the source-agnostic patterns above. After Phase 1 resolves source, also check the patterns in `platform-<source>.md` § Permissions. Also verify **Write/Edit parity**: every `Write(...)` pattern must have a matching `Edit(...)`. Stop if any are missing.

### Phase 1: Parse Arguments + Resolve Source

Parse `$ARGUMENTS` to extract:
- **Jira keys**: regex `[A-Z]+-\d+` → `JIRA_KEYS[]`
- **Issue numbers**: regex `#?(\d+)` → `ISSUE_NUMBERS[]` (accepts both `#12 #15` and bare comma/space-separated `12,15` or `12 15`)
- **Epic**: `--epic=([A-Z]+-\d+)` → `EPIC_KEY`
- **JQL**: `--jql=<value>` → `JQL` (Jira only)
- **Labels**: `--label=<value>` → `LABELS[]`
- **Source override**: `--source=<jira|github|gitlab>` → `SOURCE_OVERRIDE`
- **Max**: `--max=<N>` → `MAX_ISSUES` (default 30)
- **Concurrency**: `--concurrency=<N>` → `CONCURRENCY` (default 5)
- **DoR-ready bypass**: `--dor-ready=KEY1,KEY2,...` → `DOR_READY_KEYS[]`. Caller (typically `/sweep:epic-advance`) certifies that listed tickets passed DoR (concrete AC + slice design + no blocking ambiguity). Affects the conversation-stage rule in Phase 5 — see that section.
- **No-claim opt-out**: `--no-claim` → `NO_CLAIM=true` (default false). Jira only — suppresses the implement-time assign + sprint mutation in Phase 5.

Resolve source per the table above. Read `platform-<source>.md` once resolved — all subsequent phases reference it.

### Phase 2: Item Fetch

Fetch work items using commands from `platform-<source>.md`:

1. **Specific items** (Jira keys or issue numbers): use § 2 (Fetch single).
2. **Epic-children** (Jira `--epic=`): use § 3 with `parent = <EPIC>` JQL.
3. **All open** (no item args): use § 3 with optional label filter.
4. **Comments** for items fetched via list (no comments embedded): use § 4 per item.

Store each item as: `{id, title, body, comments[], url, labels[], updatedAt}`. The `id` field is the bare issue number for GH/GL or the full Jira key (e.g., `PROJ-101`) — branch naming uses this verbatim.

### Phase 3: Skip Detection

For each item, check these conditions in order:

**a. Item closed.** Use § 5 (State mapping) — if normalized state is `CLOSED`, mark as `SKIP(Closed)`.

**a2. Blocked by unresolved dependencies.** Use § 6 (Blocked-by detection). For each blocker, determine resolution per § 6's rules. A blocker is **unresolved** only when its issue is open AND has no PR. If any blocker is unresolved, mark as `SKIP(Blocked by ...)` — list all unresolved blockers in the skip reason.

If all blockers are resolved, the dependency gate passes. **Determine the base branch:**
- All blockers' code on main (issue closed or PR merged) → base = `default_branch`
- Exactly one blocker has an open PR → base = that PR's `headRefName`
- Multiple blockers have open PRs on different branches → base = `default_branch` and mark `⚠️ diamond dependency` in the summary. Stacking is only safe on a single linear chain. Operator should merge at least one blocker before the dependent can stack cleanly.

Record as `base_branch` in the item's metadata for Phase 5 worktree setup.

**Batch optimization:** collect all unique blocker IDs across all items and fetch their states + PRs in one pass before evaluating individual items. Cache results to avoid redundant API calls when multiple items share blockers.

**b. Existing PR linked.** Use § 7 (Linked-PR detection). Search by branch pattern `sweep/<id-or-key>-*`. If match found, mark as `SKIP(PR exists (#N))`.

**c. Prior run already processed this state (hard gate).** Check `tmp/claude-artifacts/sweep-work-items/*/issue-<id-or-key>/status.md` across all prior run directories (most recent first). Per § 9 (Watermark fields), if `milestone: done` AND `last_comment_id` AND `last_sweep_updated_at` all match the current item state → `SKIP(Already processed)`. Both watermark fields must match — comment-ID alone misses body/label edits; timestamp alone misses propagation lag. This runs before comment thread analysis so an already-processed human reply can't be misread as new input.

**d. Sweeper commented, no human reply.** Find the most recent Sweeper comment (`\*Role:\*.*Sweeper` or `\*Role:\*.*Sweeper-Confirm` — anchored to markdown italic formatting `*Role:*` to avoid false positives on prose containing "Sweeper"). If no non-Sweeper comment after it: read the comment to determine if it asks questions or is informational. Comments with explicit questions, `### Questions` sections, or requests for confirmation ("Does this plan match your intent?") → `SKIP(Awaiting reply)`. Informational comments (retroactive confirmations, implementation status updates, process notes) → **eligible**, normal Phase 5 decision.

**e. Sweeper asked questions (`\*Role:\*.*Sweeper`, NOT `Sweeper-Confirm`), human replied.** → **eligible**, force `clarify-confirm`.

**f. Sweeper confirmed (`\*Role:\*.*Sweeper-Confirm`), human replied.** → **eligible**, normal Phase 5 decision.

### Phase 4: Repo Summary

Build compressed repository context (~150 lines) every agent receives:

1. Read `README.md` (if exists, first 80 lines)
2. Read `CLAUDE.md` or `.claude/CLAUDE.md` (if exists)
3. Run `ls` at project root
4. Detect: primary language, framework, build system, test command, entry points
5. Check for `docs/learnings/SYSTEM_OVERVIEW.md` — read if present

Assemble into `REPO_SUMMARY`.

### Phase 5: Decide & Generate Artifacts

For each eligible work item, determine the role from conversation stage:

| Conversation stage | Role | Rule |
|---|---|---|
| No prior Sweeper comment, key NOT in `DOR_READY_KEYS` | **clarify** | Always — agent posts questions/analysis first |
| No prior Sweeper comment, key IN `DOR_READY_KEYS` | **implement** or **clarify** | Apply the decision rule below directly. Caller (epic-advance DoR) has already vetted scope; skip the always-clarify gate. If the rule fails (false positive), fall back to **clarify**. |
| Sweeper asked questions, operator replied (rule e) | **clarify-confirm** | Always — agent posts understanding + plan |
| Sweeper confirmed, operator replied (rule f) | **implement** or **clarify** | Decision rule below |
| Sweeper-Confirm posted, no operator reply, but operator explicitly invoked sweep on this issue | **implement** or **clarify** | Treat invocation as implicit approval — apply decision rule below |

**Decision rule:** Can you identify all three? (a) Specific file targets (b) Expected behavior change (c) Verification method. All three → **implement**. Any missing → **clarify** (restart cycle). Applies to stage 3 (Sweeper-confirm followed by operator reply) and to the DoR-ready bypass.

**Implement-time ticket mutation** (Jira only): for each item where `role == "implement"` AND `source == "jira"` AND `--no-claim` was not passed, mutate the ticket per `platform-jira.md` § 10 — set assignee to the current user and add to the active sprint on the ticket's board. Resolve `currentUser.accountId`, `boardId`, `sprintCustomFieldId`, and `activeSprintId` once per run and cache. Mutation failures log a soft warning and never block the sweep — implementation proceeds even if assign/sprint mutation errors. Skip for items already assigned to someone other than the current user (don't steal in-progress work).

Create run directory: `tmp/claude-artifacts/sweep-work-items/<YYYY-MM-DD-HHMM>` with an `issue-<id-or-key>/` subdirectory per eligible item. Compute the timestamp in a separate Bash call first (`date +%Y-%m-%d-%H%M`), then use the literal value in `mkdir`.

#### manifest.json

```json
{
  "created_at": "<ISO>",
  "run_dir": "<RUN_DIR>",
  "concurrency": <N>,
  "source": "<jira|github|gitlab>",
  "owner_repo": "<owner/repo>",
  "default_branch": "<main or master>",
  "repo_summary_lines": <N>,
  "eligible": [
    {"number": "12", "title": "...", "role": "implement", "url": "...", "labels": ["bug"], "base_branch": "main"},
    {"number": "PROJ-101", "title": "...", "role": "clarify", "url": "...", "labels": ["backend"], "base_branch": "main"}
  ],
  "skipped": [
    {"number": "15", "reason": "PR exists (#42)"},
    {"number": "PROJ-109", "reason": "Blocked by PROJ-107, PROJ-108 (no PR)"}
  ]
}
```

`number` is bare issue number (GH/GL) or full Jira key — same field name, different shape per source. The field is named `number` (not `id`) because `work-items-generate-runner.sh` reads `.eligible[].number`.

#### Data files & prompt assembly

1. **Run-level files** (write once, shared by all items):
   - `<RUN_DIR>/preflight.md` — copy `~/.claude/skill-references/sweep-agent-preflight.md`
   - `<RUN_DIR>/repo-summary.txt` — from Phase 4

2. **Per-item files** in `issue-<id-or-key>/`:
   - `metadata.json`:
     ```json
     {
       "ISSUE_NUMBER": "<bare number or full Jira key>",
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
       "SOURCE": "<jira|github|gitlab>",
       "POST_ISSUE_COMMENT_CMD": "<from platform-<source>.md § 8>",
       "FETCH_ISSUE_WITH_COMMENTS_CMD": "<from platform-<source>.md § 2 + § 4>",
       "CHECK_ISSUE_STATE_CMD": "<fetch command from platform-<source>.md § 2, state normalized per § 5>"
     }
     ```

     The `*_CMD` fields are literal command strings (not invocations) — emitted into the agent's runtime prompt for it to execute.

     Key names keep the `ISSUE_` prefix for every source — the prompt templates and `sweep-agent-preflight.md` consume exactly these placeholders. For Jira, `ISSUE_NUMBER` carries the full key (`PROJ-101`).

   - `body.txt` — item body text
   - `comments.txt` — formatted comment thread

3. **Assemble prompt:**
   ```bash
   bash ~/.claude/skill-references/fill-template.sh <template-path> <RUN_DIR>/issue-<id-or-key> > <RUN_DIR>/issue-<id-or-key>/prompt.txt
   ```
   `<template-path>` is `implementer-prompt.md`, `clarifier-prompt.md`, or `confirmer-prompt.md` (relative to this skill's directory).

#### let-it-rip.sh

**Preferred path — use the consolidated generator.** After writing `manifest.json`, `<RUN_DIR>/metadata.json`, `repo-summary.txt`, and per-issue `issue-<N>/metadata.json`, run:

```bash
bash ~/.claude/skill-references/work-items-generate-runner.sh <RUN_DIR>
```

This fetches body/comments via `gh`, assembles each prompt via `fill-template.sh` (picking the right template per role), auto-wires `IMPLEMENT_ISSUES` + `PROJECT_ROOT`, and assembles `let-it-rip.sh` from the **work-items-native** template (`~/.claude/skill-references/work-items-runner-template.sh`). The work-items template — not the generic `parallel-claude-runner-template.sh` — handles implementer-mode specifics: `git worktree add -b sweep/<N>-impl <wt> <base>` (creates new branch from base), `cd` into the worktree before launching `claude -p`, and skips worktree setup when `IMPLEMENT_ISSUES` is empty.

**Do not** hand-assemble via the generic `parallel-claude-runner-template.sh` for implement mode — it requires existing branches, doesn't `cd`, and won't work for fresh sweep branches.

Work-item-specific metadata overrides and adaptations (written into `metadata.json` before invoking the generator):

- **Model selection**: `MODEL` → `claude-opus-4-7` for implement runs (leaf doing actual coding work). Clarify and confirm runs may use `claude-sonnet-4-6` (lighter, comment-driven). When mixing modes in one runner, default to opus.
- **Entity type keys**: Set in `metadata.json` per the sweep-scaffold.md schema. Issue-specific values:
  ```json
  {"ENTITY_PREFIX": "issue", "ENTITY_LABEL": "Issue", "STATE_FIELD": "issue_state",
   "TERMINAL_STATES": "CLOSED"}
  ```
  `FETCH_ITEM_STATE_CMD` — the runner-level state-check command, substituted into `work-items-runner-template.sh` as `{{FETCH_ITEM_STATE_CMD}}` (referencing `$pr_num`). Set it here from platform detection, or let `work-items-generate-runner.sh` default it from the manifest `source`: GitHub/GitLab per the sweep-scaffold.md forms (`gh issue view ...` / `glab api ... | jq ... | tr ...`); Jira has no shell equivalent (MCP-only) → empty, so the runner falls through to the in-session check.
- **Config arrays**: `IMPLEMENT_ISSUES=(<numbers>)` — issues that get worktrees vs in-place clarifiers. Write this array to the runner script so the worktree setup section knows which issues need checkouts.
- **Worktree setup**: Only for issues in `IMPLEMENT_ISSUES`. Create worktrees under `<RUN_DIR>/worktrees/issue-<N>/` from the issue's `BASE_BRANCH` (read from `metadata.json`). When `BASE_BRANCH` is the default branch, the implementer starts fresh. When it's a dependency's PR branch, the implementer stacks on top of that branch's work. **For non-default base branches:** run `git fetch origin <BASE_BRANCH>` before `git worktree add` — the dependency's branch likely only exists on the remote.
- **PR target for stacked branches**: When `BASE_BRANCH` is not the default branch, the implementer's PR must target `BASE_BRANCH` (not main). The `BASE_BRANCH` value is available in `metadata.json` and must be passed through to the implementer prompt so `gh pr create --base <BASE_BRANCH>` is used.
- **Pre-flight state check**:
  1. Local `status.md` check — skip if `issue_state: CLOSED` (terminal entity state only — role convergence signals like `comment_posted` and `pr_opened` are the session's responsibility, not the runner's)
  2. API fallback — `FETCH_ITEM_STATE_CMD` (e.g., `gh issue view <N> --json state -q '.state'` for GitHub, `glab api projects/:id/issues/$pr_num | jq -r .state | tr ...` for GitLab), skip if closed
  3. **Per-source parameterization.** `work-items-runner-template.sh` substitutes `{{FETCH_ITEM_STATE_CMD}}` (supplied by `work-items-generate-runner.sh` from the sweep-scaffold per-source definition) and dry-run-validates it before launch, so GitHub and GitLab sweeps run their native state command and skip closed items at the runner level. Jira has no shell state command (MCP-only) → its `FETCH_ITEM_STATE_CMD` is empty and the runner falls through to launch; the in-session preflight (`CHECK_ISSUE_STATE_CMD`, per-source) still exits closed items early.
- **Working directory**: For implementers, `cd` into the worktree before launching `claude -p`. For clarifiers, stay in project root.
- **Cleanup**: Worktree cleanup on EXIT trap (only for worktrees created by this run).

The runner MUST use `stream-monitor.sh` for `live.md` observability (same pattern as PR sweeps).

### Phase 6: Present Summary & Announce

```
Source: <jira|github|gitlab>
Assessed N items. M eligible (I implement, C clarify, F confirm), K skipped:

| ID | Title | Role | Base | Skip Reason |
|---|---|---|---|---|
| 12 | Fix login redirect | Implement | main | -- |
| PROJ-101 | Add vendor export endpoint | Implement | main | -- |
| 8 | Add dark mode | Implement | sweep/7-auth | stacked on #7 |
| 3 | Update nav | Clarify | -- | -- |
| 15 | Refactor auth | Skip | -- | PR exists (#42) |
| PROJ-109 | New endpoint | Skip | -- | Blocked by PROJ-107 (no PR) |
| 7 | Update deps | Skip | -- | Awaiting reply |
```

Then announce artifacts (Announce Format from `sweep-scaffold.md`, substituting `issue-<id-or-key>` for `pr-<N>`):

```
Artifacts written to <RUN_DIR>/

  manifest.json    — M eligible (I implement, C clarify), K skipped
  let-it-rip.sh    — concurrency: CONCURRENCY
  issue-<id-or-key>/  — M item directories with prompts

To launch:        bash <RUN_DIR>/let-it-rip.sh
Re-run (loop):    bash <RUN_DIR>/let-it-rip.sh  (sessions with no changes exit cleanly)
Progress:         "Check progress on <RUN_DIR>"
Retro:            "Retro on <RUN_DIR>"
```

Proceed directly to artifact generation after the summary — do not wait for confirmation.

### Phase 7: Auto-Launch Runner

Follow **Auto-Launch** in `sweep-scaffold.md`. Use the relative path `bash tmp/claude-artifacts/sweep-work-items/<TIMESTAMP>/let-it-rip.sh` so the existing `Bash(bash tmp/claude-artifacts/**)` permission matches. Skip if `0 eligible` or `--no-launch` was passed.

## Convergence (director-layer)

Convergence is a director concern, not this skill's. Summary for directors:

- **Implementers**: converged when `pr_opened: true` in `status.md` (PR created, job done)
- **Clarifiers**: converged when `comment_posted: true` in `status.md` (questions posted, awaiting human reply)
- **Confirmers**: converged when `confirmation_posted: true` in `status.md`
- **Error states**: `milestone: errored` items are NOT converged — director may write retry directives
- **Single-pass default**: work items are typically one-shot. Rerun only triggers if the item was updated (new comments, edits) since the last pass.

## Important Notes

- **Assessment only.** This skill generates artifacts and exits. It does not launch agents or wait for results.
- **Agents are independent but dependency-aware.** Each `claude -p` session operates alone, but the assessment phase respects `Blocked by:` declarations — items with unresolved blockers (no PR, no merged code) are skipped. When a blocker has an open PR, the dependent item stacks on that branch. Parallel implementers on unrelated items may still create conflicting PRs — the operator resolves manually.
- **`Relates to` not `Closes`.** PRs reference items with `Relates to #{N}` / `Relates to PROJ-XXX`, never `Closes` or `Fixes`. The operator decides when to close.
- **Footnote identity.** `Role: Sweeper` (clarifier) and `Role: Sweeper-Confirm` (confirmer) — used by skip detection to determine conversation stage.
- **Worktrees are preserved.** Implementer worktrees persist after the sweep for follow-up work. Clean up with `git worktree remove` after PRs/MRs merge.
- See **Shared Important Notes** in `sweep-scaffold.md` for rerunnable, rate limits, crash recovery, and cleanup.

## Out of scope (today)

- **Wave-aware execution.** Items currently run in flat parallel (`xargs -P CONCURRENCY`). Multi-wave plans with stacked branches and diamond merges remain in `/director` Custom mode. See `~/.claude/learnings/claude-code/multi-agent/parallel-plans.md` for the agent-merges-secondary-parent pattern.
- **Plan-shape input.** No `--plan=path/to/plan.md` consumption. The skill derives shape from item dependencies; planning-doc-driven shape is a future direction.
- **Multi-repo.** Items are scoped to one repo. Multi-repo orchestration uses `/director` Custom mode.
