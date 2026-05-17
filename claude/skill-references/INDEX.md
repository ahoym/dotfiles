# Skill References — Quick Index

Helpers, templates, and reference docs under `~/.claude/skill-references/`. **Check this first before writing non-trivial Bash** (loops, `gh -q '<format>'` quoted formats, multi-step pipes) — there's likely a helper that runs allowlist-free via `Bash(bash ~/.claude/skill-references/**)`.

## Three Shapes

| Shape | Path glob | Invoke |
|-------|-----------|--------|
| Executable wrapper | `*.sh` (top-level, **not** ending in `-template.sh`) | `bash <path> <args>` |
| Template | `*-template.sh` (top-level) | Consumed by `fill-template.sh`, not run directly |
| Platform command stub | `{github,gitlab}/commands/*.sh` | 1–3 lines with `<N>`, `{owner}/{repo}` placeholders. Inlined into `claude -p` prompts via `fill-template.sh`. Don't `bash` them — read the file, run the underlying CLI directly. |

## Executable Wrappers

| Helper | Usage | What it does |
|--------|-------|--------------|
| `director-bootstrap.sh` | `bash <path> <timestamp>` | Scaffold director session dir (`session.json`, `decisions.md`). Errors if exists. |
| `init-sweep-pr-dir.sh` | `bash <path> <run_dir> <pr_numbers...>` | Scaffold PR sweep run dir (`pr-<N>/` + `sweep-pr-preflight.md`). |
| `fill-template.sh` | `bash <path> <template> <data-dir> > out` | Substitute `{KEY}` / `{{KEY}}` / `{@file}` / `{{#KEY}}...{{/KEY}}` from `<data-dir>/metadata.json`. Pure string subst, no AI. |
| `sweep-prs-generate-runner.sh` | `bash <path> <RUN_DIR>` | Generate per-PR `prompt.txt` + `let-it-rip.sh` for review/address. Reads `<RUN_DIR>/metadata.json`. |
| `work-items-generate-runner.sh` | `bash <path> <RUN_DIR>` | Same for `sweep:work-items` (issue dirs + worktree setup). |
| `sweep-status-summary.sh` | `bash <path> <RUN_DIR> [--logs N\|--retro]` | Per-item status+state table. `--logs N` tails each `output.log` (storm-diagnosis path). `--retro` also dumps `results.md` + `learnings.md`. |
| `sweep-status.sh` | `bash <path> <run-dir>` | Older variant — pr-only, no log tailing. Prefer `sweep-status-summary.sh`. |
| `sweep-results.sh` | `bash <path> <run-dir>` | Dump `results.md` + `learnings.md` per item. Subset of `--retro`. |
| `audit-permissions.sh` | `bash <path> <run-dir>` | Scan `raw.jsonl` for permission denials, suggest patterns to add to `settings.json`. |
| `permission-analyzer.sh` | `bash <path>` (env: `SESSIONS_LIMIT`, `MIN_COUNT`) | Rank read-only Bash/MCP candidates for allowlist promotion across recent transcripts. |
| `gh-issues-fetch-state.sh` | `bash <path> <N> [<N> ...]` | Fetch state + updatedAt + latest-comment metadata for GH issues. JSON output, `===issue-<N>===` separators. |
| `stream-monitor.sh` | (piped) `... \| claude -p ... \| stream-monitor.sh <PR_DIR> \| tee raw.jsonl` | Pass-through filter; writes `live.md` events as side effect. Used by runners, rarely by hand. |
| `vp-agent-template.sh` | `bash <path> [TASK] [RUN_DIR_BASE]` | Multi-tier VP→Director→Worker launcher (research/exploration, not sweep). Note: `-template` suffix is a misnomer — this is a direct-run launcher, not a `fill-template.sh` input. |
| `copy-ref.sh` | `bash <path> <filename> <dest>` | Copy a file from `~/.claude/skill-references/` to a destination — bypasses Bash tool sandbox restriction on `cp` with out-of-project sources. |
| `build-keyword-index.sh` | `bash <path>` | Rebuild `claude/learnings/.keyword-index.json` via mechanical extraction. Writes staging output to `tmp/claude-artifacts/keyword-index/keyword-index.json`; inspect, then `cp` over the canonical file. |
| `orchestrator/kill-sessions.sh` | `bash <path> <run_dir> [--runners]` | Kill running `claude -p` sessions in a sweep run dir (via `session.pid`). `--runners` also kills `let-it-rip.sh` runner processes. |
| `orchestrator/session-liveness.sh` | `bash <path> <run_dir\|session_dir>` | Show alive/dead state for sessions in a run/session dir + tail of each `live.md`. |
| `orchestrator/sweep-dashboard.sh` | `bash <path> <run_dir> [<run_dir2> ...]` | Cross-run worker state dashboard (state.md / status.md / live.md per item, plus per-run summary counts). |
| `implementer/diff-line-lookup.sh` | `bash <path> <pr/mr_number> [search_token]` | Map diff `+` lines to `file:line: content` for inline-comment line-number verification. Auto-detects `gh` vs `glab`. |

## Templates

| Template | Filled by | Output |
|----------|-----------|--------|
| `parallel-claude-runner-template.sh` | `sweep-prs-generate-runner.sh` | `<RUN_DIR>/let-it-rip.sh` for review/address |
| `work-items-runner-template.sh` | `work-items-generate-runner.sh` | `<RUN_DIR>/let-it-rip.sh` for work-items |

## Platform Command Stubs by Purpose

`{github,gitlab}/commands/*.sh` — ~35 stubs each, GitHub/GitLab parity except where noted. They're command-text templates.

| Category | Stubs |
|----------|-------|
| PR fetch | `fetch-pr-watermark`, `fetch-pr-base-branch`, `fetch-pr-branches`, `consolidated-fetch`, `check-pr-mergeable` |
| PR list | `list-open-prs`, `list-prs-by-branch`, `list-prs-by-issue-ref` |
| Review fetch | `fetch-review-comments`, `fetch-review-commits`, `fetch-review-details`, `fetch-review-diff`, `fetch-review-files`, `batch-fetch-reviews`, `check-existing-review`, `count-total-reviews`, `find-approved-reviewers` |
| Review post | `create-review`, `post-code-review`, `post-review-comments`, `update-review` |
| Inline comments | `fetch-inline-comments`, `fetch-recent-inline-comments`, `fetch-latest-inline-comment-id`, `reply-to-inline-comment` |
| Top-level comments | `post-top-level-comment`, `post-issue-comment`, `react-to-comment` |
| Activity / checkout | `fetch-activity-signals`, `checkout-review` |
| Issue ops | `fetch-issue`, `fetch-issue-comments`, `fetch-issue-with-comments`, `check-issue-state`, `list-open-issues`, `link-sub-issue` (gh-only), `unlink-sub-issue` (gh-only), `create-milestone` (gh-only) |
| Platform check | `verify-platform-access` |

When no executable wrapper covers your need, fall back to plain CLI under the platform's allowlist (`Bash(gh *)`, `Bash(glab *)`) and parse JSON via separate `jq` — not inline `gh -q '<format>'` (quoted format strings prompt for permission).

## Reference Docs (.md)

Read by skills via `@`/Skill tool, not invoked directly. Listed here so cross-refs from learnings/playbooks resolve at a glance.

| File | Domain |
|------|--------|
| `director-playbook.md` | Director orchestration (eager-loaded by /director Phase 1) |
| `director-decision-matrix.md` | Escalation tiers, routine vs judgment (eager-loaded by /director) |
| `sweep-scaffold.md` | Shared scaffold for sweep:*-prs / sweep:work-items |
| `sweep-pr-preflight.md` | Copied into PR sweep run dirs |
| `sweep-agent-preflight.md` | Copied into work-items run dirs |
| `artifact-contract.md` | Manifest schema + run-dir structure for director-managed skills |
| `agent-prompting.md` | Patterns for writing `claude -p` prompts |
| `subagent-patterns.md` | Subagent orchestration recipes |
| `decision-matrix.md` | Generic decision matrix (non-director) |
| `code-quality-checklist.md` | Code review checklist |
| `corpus-cross-reference.md` | Cross-ref helpers for learning corpus |
| `exploration-report-shape.md` | Output shape for `/explore-repo` |
| `persona-auto-detect.md` | Persona matching heuristics |
| `platform-detection.md` | GitHub vs GitLab detection |
| `request-interaction-base.md` | Base for `git:*` request skills |
| `review-comment-classification.md` | Reviewer comment classification (drives reactions) |

## Cross-Refs

- `~/.claude/learnings/claude-code/sweep-sessions.md` → "Template Scripts Fail `bash -n` Validation" — full executable-vs-stub distinction.
- `~/.claude/learnings/claude-code/multi-agent/director/observability.md` → "Use `sweep-status-summary.sh`" — three-mode flag table.
- `~/.claude/learnings/claude-code/multi-agent/director/failure-modes.md` → "Compound-Mode Storm" + "30-Second Exit Diagnosis" — when to reach for `--logs N`.
