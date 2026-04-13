---
description: "Shared scaffold for sweep:*-prs skills: artifact structure, watermark logic, result/learnings patterns, let-it-rip generation, pre-flight checks, announce/progress/retro formats, and common important notes."
---

# Sweep Scaffold

Shared patterns consumed by `sweep:address-prs`, `sweep:review-prs`, and `sweep:work-items`. Each skill reads selectively — not all sections apply to every mode.

## Artifact Structure

```
<RUN_DIR>/
├── manifest.json
├── let-it-rip.sh
├── repo-summary.txt    # work-items only — shared repo context
├── preflight.md        # work-items only — copy of sweep-agent-preflight.md
├── sweep-pr-preflight.md  # address/review — copy of sweep-pr-preflight.md
├── directives.md       # optional — global instructions from directors (read by all sessions)
└── pr-<N>/ or issue-<N>/
    ├── metadata.json   # template data — keys for {KEY} substitution
    ├── body.txt        # work-items only — issue body for {@body.txt} inclusion
    ├── comments.txt    # work-items only — formatted comments for {@comments.txt}
    ├── prompt.txt      # assembled by fill-template.sh (input to claude -p)
    ├── directives.md   # optional — per-item instructions from directors
    ├── output.log      # stdout+stderr (written by let-it-rip.sh)
    ├── status.md       # watermark + milestone (written by claude -p)
    ├── results.md       # append-only rounds (written by claude -p)
    └── learnings.md    # append-only observations (written by claude -p)
```

## Prompt Assembly via fill-template.sh

Prompts are assembled by `~/.claude/skill-references/fill-template.sh` (see script header for syntax). Assessment agents write `metadata.json` + data files to the item directory, then call `bash fill-template.sh <template> <item-dir> > <item-dir>/prompt.txt`. Each skill's SKILL.md specifies its metadata schema and data files.

## Prompt Watermark & Skip Logic (steps 1-4)

Each `prompt.txt` begins with these shared steps before mode-specific work:

1. **Read directives.** Read `${RUN_DIR}/directives.md` and `${PR_DIR}/directives.md` if they exist. These are instructions from the directors (operator + orchestrating agent) — incorporate them into this pass. Directives may override skip logic (e.g., "process even if watermark matches"), add focus areas, or provide context not visible in the PR itself.

2. **Read existing watermark.** If `status.md` exists, read `last_<mode>_sha` and `last_comment_id`. If it doesn't exist, this is the first run — proceed to step 4.

3. **Compare against current PR state.** Fetch the PR's current HEAD SHA, state, mergeable status, and latest comment IDs (both inline review comments AND top-level PR comments) using platform-command scripts:
   - Inline: use `fetch-latest-inline-comment-id.sh` (replace `<N>` with PR number, `{owner}/{repo}` with repo)
   - Top-level + state: use `fetch-pr-watermark.sh` (replace `<N>` with PR number) — parse JSON to extract `latest_commit` (first 7 chars of last commit oid), `state`, `mergeStateStatus`, `mergeable`, and `latest_top_level_comment_id`
   - Use the MAX of inline and top-level comment IDs as the effective `last_comment_id` for watermark comparison. Top-level comments include operator directives that inline-only checks miss.

   **State check (earliest exit):** If state is MERGED or CLOSED, set `milestone: skipped`, `pr_state: <state>` in `status.md` and exit immediately.

   Compare against watermark values:
   - HEAD SHA differs OR latest comment ID differs → new work needed, proceed to step 4
   - Both match AND no directives → no changes since last pass, set `milestone: skipped` in `status.md` and exit
   - Both match BUT directives present → directives override skip, proceed to step 4

4. **Update `status.md`** with `milestone: started` and current timestamp.

## Result & Learnings Append Pattern

### results.md

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

**Learnings provenance (mandatory):** List loaded files with honest influence: `- <path> — <what it changed, or "not relevant">`. "Confirmed patterns" / "verified approach" is not influence. No loads → "No learnings loaded this pass."

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

Write `<RUN_DIR>/metadata.json` with runner config, then assemble via `fill-template.sh`:

```bash
bash ~/.claude/skill-references/fill-template.sh \
  ~/.claude/skill-references/parallel-claude-runner-template.sh <RUN_DIR> \
  > <RUN_DIR>/let-it-rip.sh
chmod +x <RUN_DIR>/let-it-rip.sh
```

**Do NOT read the runner template** — `fill-template.sh` handles all substitution. The skill only writes data files.

#### Runner metadata.json schema

```json
{
  "MODE": "review",
  "MODE_LABEL": "Review",
  "MODEL": "<model>",
  "RUN_DIR": "<absolute path>",
  "CONCURRENCY": "3",
  "ITEMS": "80 81 82",
  "TIMESTAMP": "<YYYY-MM-DD-HHMM>",
  "ENTITY_PREFIX": "pr",
  "ENTITY_LABEL": "PR",
  "STATE_FIELD": "pr_state",
  "STATE_CHECK_CMD": "gh pr view",
  "TERMINAL_STATES": "MERGED CLOSED",
  "BRANCHES": "",
  "WORKTREES": "",
  "PROJECT_ROOT": ""
}
```

**`MODEL` selection — based on runner role:** orchestrator runners that delegate to subagents (e.g., `sweep:review-prs` → `git:team-review-request`) → `claude-sonnet-4-6`. Leaf runners doing actual work (reading diffs, editing files, pushing commits — e.g., `sweep:address-prs`, `sweep:work-items`) → `claude-opus-4-6`. `[1m]` variant only when context demands it.

**Block conditionals:** `BRANCHES` and `WORKTREES` control `{{#BRANCHES}}...{{/BRANCHES}}` and `{{#WORKTREES}}...{{/WORKTREES}}` blocks in the template. Non-empty → block kept; empty → block stripped. Review mode sets both to empty. Address mode sets both to a truthy value (e.g., `"true"`).

**Entity type keys:** `ENTITY_PREFIX` controls directory naming (`pr-<N>` vs `issue-<N>`). `ENTITY_LABEL` controls log labels. `STATE_FIELD` controls the `status.md` field name for cached state. `STATE_CHECK_CMD` controls the API pre-flight command. `TERMINAL_STATES` is a space-separated list of states that trigger pre-flight skip. Every sweep skill must provide all 5 keys — there are no defaults.

**Address mode data files** (written to `<RUN_DIR>/` alongside metadata.json):
- `branch-cases.txt` — case-statement body for `branch_for()` (e.g., `80) echo "feat/auth" ;;`)
- `worktree-cases.txt` — case-statement body for `worktree_for()` (e.g., `80) echo "/path/to/wt" ;;`)
- `new-worktree-items.txt` — space-separated entity numbers needing new worktrees (empty if all reused)

These are included via `{@file}` references in the template. Review mode doesn't need them — the block conditional strips the enclosing section.

### Pre-flight State Check

The generated script has a two-tier pre-flight before launching each session:

1. **Local status.md check (free).** Read `STATE_FIELD` from the entity's existing `status.md`. If the value is in `TERMINAL_STATES`, skip immediately — no API call, no process overhead. This eliminates the biggest efficiency problem on rerun cycles.
2. **API fallback (1 API call).** If no `status.md` exists or the state field is not terminal, use `STATE_CHECK_CMD` to check current state. This covers first runs and entities whose state changed externally. The API fallback also writes the state field to `status.md` so subsequent cycles use the local check.

Address mode: the same state check MUST also be included in the worktree setup loop (`setup_worktrees`), before fetching or creating worktrees.

## Announce Format

```
Artifacts written to <RUN_DIR>/

  manifest.json    — <M> eligible, <K> skipped
  let-it-rip.sh    — concurrency: <CONCURRENCY>
  <ENTITY_PREFIX>-<N>/  — <M> item directories with prompts

To launch:        bash <RUN_DIR>/let-it-rip.sh
Re-run (loop):    bash <RUN_DIR>/let-it-rip.sh  (same command — sessions with no changes exit cleanly)
Progress:         "Check progress on <RUN_DIR>"
Retro:            "Retro on <RUN_DIR>"
```

## Progress Check

Read all `<ENTITY_PREFIX>-*/status.md` files, present:

| PR | Milestone | Started |
|----|-----------|---------|
| #47 | processing | 2m ago |
| #46 | pushing | 1m ago |

## Retro

Read `manifest.json`, all `<ENTITY_PREFIX>-*/results.md`, and all `<ENTITY_PREFIX>-*/learnings.md`. Note that `results.md` and `learnings.md` are append-only — each run adds a dated section. Show the latest round per PR plus a round count. Include: skipped PRs, aggregated learnings by theme, and summary line.

## Convergence

Convergence is a director-layer concern — individual sessions do not decide convergence. See `director-playbook.md` for convergence rules, monitoring table format, and directive patterns.

## Shared Important Notes

- **Rerunnable.** `let-it-rip.sh` is the loop target — run it repeatedly as conversations evolve. The pre-flight state check skips merged/closed PRs. Each `claude -p` session reads the watermark from `status.md` and compares against current PR state — if nothing changed, it skips; if new activity exists, it performs a new pass and appends a dated section to `results.md` and `learnings.md`.
- **Rate limits.** Detected per-session via log grep. `.rate-limited` sentinel signals the summary.
- **Crash recovery.** Missing result files → retro reports as "unknown/crashed" by diffing manifest against actual results.
- **Cleanup.** Run directories persist for retro. Remove manually: `rm -rf tmp/claude-artifacts/sweep-<mode>/<timestamp>/`
- **Prompt templates must be self-contained.** `claude -p` agents can't read other templates at runtime. When trimming, compress prose but keep structural templates (markdown formats, YAML schemas, comment formats) inline. Duplication across templates is the cost of agent isolation.
- **Rerun trace before shipping new templates.** Mentally walk through: (1) first run — does the agent post/act correctly? (2) immediate rerun, no changes — does the watermark skip? (3) rerun after the agent posted — does the agent's own comment trigger a false "new activity"? If any step is unclear, the watermark or skip logic has a gap.
