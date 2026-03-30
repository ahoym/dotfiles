---
description: "Shared scaffold for sweep-*-prs skills: artifact structure, watermark logic, result/learnings patterns, let-it-rip generation, pre-flight checks, announce/progress/retro formats, and common important notes."
---

# Sweep Scaffold

Shared patterns consumed by `sweep-address-prs` and `sweep-review-prs`. Each skill reads selectively — not all sections apply to every mode.

## Artifact Structure

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
    ├── result.md       # append-only rounds (written by claude -p)
    └── learnings.md    # append-only observations (written by claude -p)
```

## Prompt Watermark & Skip Logic (steps 1-4)

Each `prompt.txt` begins with these shared steps before mode-specific work:

1. **Read directives.** Read `${RUN_DIR}/directives.md` and `${PR_DIR}/directives.md` if they exist. These are instructions from the directors (operator + orchestrating agent) — incorporate them into this pass. Directives may override skip logic (e.g., "process even if watermark matches"), add focus areas, or provide context not visible in the PR itself.

2. **Read existing watermark.** If `status.md` exists, read `last_<mode>_sha` and `last_comment_id`. If it doesn't exist, this is the first run — proceed to step 4.

3. **Compare against current PR state.** Fetch the PR's current HEAD SHA, state, mergeable status, and latest comment IDs (both inline review comments AND top-level PR comments) via `gh`:
   - Inline: `gh api repos/{owner}/{repo}/pulls/<N>/comments --jq '.[-1].id // empty'`
   - Top-level + state: `gh pr view <N> --json commits,state,mergeStateStatus,mergeable,comments --jq '{latest_commit: .commits[-1].oid[0:7], state, mergeStateStatus, mergeable, latest_top_level_comment_id: (.comments[-1].id // null)}'`
   - Use the MAX of inline and top-level comment IDs as the effective `last_comment_id` for watermark comparison. Top-level comments include operator directives that inline-only checks miss.

   **State check (earliest exit):** If state is MERGED or CLOSED, set `milestone: skipped`, `pr_state: <state>` in `status.md` and exit immediately.

   Compare against watermark values:
   - HEAD SHA differs OR latest comment ID differs → new work needed, proceed to step 4
   - Both match AND no directives → no changes since last pass, set `milestone: skipped` in `status.md` and exit
   - Both match BUT directives present → directives override skip, proceed to step 4

4. **Update `status.md`** with `milestone: started` and current timestamp.

## Result & Learnings Append Pattern

### result.md

Append a new dated section after each run (do not overwrite). On the very first run, prepend a file header:

```markdown
# PR #<N> — <title>
```

Each section:

```markdown
## <Mode Label> — <ISO timestamp>

**Trigger**: <first run | N new comments since last pass | new commits (old_sha → new_sha) | both | directive>

| Field | Value |
|-------|-------|
| Status | success / skipped / error |
<MODE-SPECIFIC FIELDS>
| <Mode> SHA | <HEAD SHA> |
| Last Comment ID | <latest comment ID> |
| Error | <none or message> |
```

Skills define their own mode-specific fields (e.g., Address adds Conflicts resolved/Auto-implemented/Escalated/Commits; Review adds Mode/Personas/Findings/Inline Comments/Review URL).

### learnings.md

Append a dated section with observations. Write "No learnings from this pass." if nothing notable.

### status.md Watermark

Write final status after each run:

```yaml
milestone: done  # or errored / skipped
pr: <N>
pr_state: <OPEN / MERGED / CLOSED>
mergeable: <MERGEABLE / CONFLICTING / UNKNOWN>
last_<mode>_sha: <HEAD SHA at time of processing>
last_comment_id: <MAX of inline and top-level comment IDs at time of processing>
updated_at: <ISO timestamp>
```

Error handling: always write all artifacts before exiting, even on failure. On error, still update `status.md` watermark with `milestone: errored` so the next run retries.

## let-it-rip.sh Generation

Read `@~/.claude/skill-references/parallel-claude-runner-template.sh` and fill placeholders:
- `{{MODE}}` → skill-specific mode string
- `{{RUN_DIR}}` → absolute path to run directory
- `{{CONCURRENCY}}` → from parsed arguments
- `{{PRS}}` → space-separated eligible PR numbers
- `{{TIMESTAMP}}` → current timestamp

Address mode additionally fills `{{PROJECT_ROOT}}`, `{{BRANCH_CASES}}`, `{{WORKTREE_CASES}}`, `{{NEW_WORKTREE_PRS}}` and keeps `{{#BRANCHES}}...{{/BRANCHES}}` and `{{#WORKTREES}}...{{/WORKTREES}}` blocks. Review mode removes those blocks.

### Pre-flight State Check

The generated script MUST include a **pre-flight state check** in the PR loop, before launching each session:
```bash
pr_state=$(gh pr view "$pr" --json state --jq '.state' 2>/dev/null)
if [ "$pr_state" = "MERGED" ] || [ "$pr_state" = "CLOSED" ]; then
    echo "[PR #${pr}] SKIPPED — ${pr_state} (no session launched)"
    continue
fi
```
This avoids launching `claude -p` sessions for terminal-state PRs — saves process overhead and API cost on rerun cycles where PRs have been merged between runs.

Address mode: the same state check MUST also be included in the worktree setup loop (`setup_worktrees`), before fetching or creating worktrees.

## Announce Format

```
Artifacts written to <RUN_DIR>/

  manifest.json    — <M> eligible, <K> skipped
  let-it-rip.sh    — concurrency: <CONCURRENCY>
  pr-<N>/          — <M> PR directories with prompts

To launch:        bash <RUN_DIR>/let-it-rip.sh
Re-run (loop):    bash <RUN_DIR>/let-it-rip.sh  (same command — sessions with no changes exit cleanly)
Progress:         "Check progress on <RUN_DIR>"
Retro:            "Retro on <RUN_DIR>"
```

## Progress Check

Read all `pr-*/status.md` files, present:

| PR | Milestone | Started |
|----|-----------|---------|
| #47 | processing | 2m ago |
| #46 | pushing | 1m ago |

## Retro

Read `manifest.json`, all `pr-*/result.md`, and all `pr-*/learnings.md`. Note that `result.md` and `learnings.md` are append-only — each run adds a dated section. Show the latest round per PR plus a round count. Include: skipped PRs, aggregated learnings by theme, and summary line.

## Shared Important Notes

- **Rerunnable.** `let-it-rip.sh` is the loop target — run it repeatedly as conversations evolve. The pre-flight state check skips merged/closed PRs. Each `claude -p` session reads the watermark from `status.md` and compares against current PR state — if nothing changed, it skips; if new activity exists, it performs a new pass and appends a dated section to `result.md` and `learnings.md`.
- **Rate limits.** Detected per-session via log grep. `.rate-limited` sentinel signals the summary.
- **Crash recovery.** Missing result files → retro reports as "unknown/crashed" by diffing manifest against actual results.
- **Cleanup.** Run directories persist for retro. Remove manually: `rm -rf tmp/sweep-<mode>/<timestamp>/`
