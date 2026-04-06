---
description: "Standard artifact contract for director-managed skills. Any skill producing this structure gets full director integration: stream monitoring, live.md observability, directives, kill + retry."
---

# Artifact Contract

Skills that produce this structure can be launched and monitored by `/director`.

## Directory Structure

```
<RUN_DIR>/
├── manifest.json           # What to run, metadata
├── manifest-updates.json   # Optional, JSONL -- incremental additions/closures
├── let-it-rip.sh           # Generated runner script
├── directives.md           # Global directives from director (optional, append-only)
└── item-<id>/
    ├── prompt.txt          # Input piped to claude -p
    ├── directives.md       # Per-item directives (optional, append-only)
    ├── session.pid          # Written by runner (sh -c/exec pattern)
    ├── state.md            # Written by runner -- process lifecycle state
    ├── status.md           # Written by session at end (watermark, milestone)
    ├── result.md           # Written by session at end (append-only)
    ├── learnings.md        # Written by session at end (append-only, optional)
    ├── live.md             # Written by stream-monitor.sh during session
    └── raw.jsonl           # Written by tee during session (debug only)
```

## manifest.json

```json
{
  "created_at": "<ISO timestamp>",
  "run_dir": "<absolute path>",
  "concurrency": 3,
  "source_skill": "/sweep-review-prs",
  "items": [
    {
      "id": "52",
      "label": "#52 — Director sweep improvements",
      "metadata": { }
    }
  ],
  "skipped": [
    { "id": "49", "label": "#49 — Old PR", "reason": "MERGED" }
  ]
}
```

**Generic fields** (required by runner and director):
- `id` — unique key, used for directory naming (`item-<id>/`)
- `label` — human-readable, shown in monitoring table

**`metadata`** — skill-specific, opaque to runner and monitor. Examples:
- Sweep review: `{ "mode": "first-review", "url": "...", "stacked_on": null }`
- Sweep address: `{ "branch": "...", "base": "main", "has_conflicts": false, "worktree": "..." }`
- Work items: `{ "decision": "implement", "issue_url": "...", "branch": "sweep/53-..." }`

## let-it-rip.sh

Generated from a runner template. Must:
1. Process items in parallel via `xargs -P $CONCURRENCY`
2. Pre-flight skip: check `status.md` for terminal state before launching
3. Pipe through stream-monitor.sh when available:
   ```bash
   cat "${item_dir}/prompt.txt" \
     | sh -c "echo \$\$ > ${item_dir}/session.pid; exec claude -p --verbose --output-format stream-json" \
     | stream-monitor.sh "$item_dir" \
     | tee "$item_dir/raw.jsonl" > "$log_file"
   ```
4. Fall back to plain `claude -p` if stream-monitor.sh is missing

## prompt.txt

The full prompt piped to `claude -p`. The generating skill fills this from its prompt template with per-item placeholders. Must instruct the session to write `status.md` and `result.md` at completion.

## Session-Written Files

### status.md
Written by the `claude -p` session at end. Minimum fields:
```yaml
milestone: done | skipped | errored
```
Skills add domain-specific fields (watermarks, PR state, mergeable status).

### result.md
Append-only — each run adds a dated section. Contains the session's findings, actions, or completion report.

### learnings.md
Optional, append-only. Patterns, gotchas, or observations from the session.

## Runner-Written Files

### state.md
Written by the runner (bash) to track process lifecycle. One file per item, overwritten on each state transition.

```yaml
state: running | completed | errored | timed-out | retrying | rate-limited
attempt: 1
max_attempts: 2
updated_at: <ISO timestamp>
```

Optional fields (included when relevant):
- `started_at` -- ISO timestamp of current attempt start
- `idle_seconds` -- seconds since last `live.md` update (on timeout)
- `exit_reason` -- what caused failure (error, timeout)
- `duration_seconds` -- wall-clock time for completed attempts
- `escalation` -- `needs-director` when runner exhausts retries
- `previous_exit` -- exit status from prior attempt (on retry)

The runner owns this file exclusively. The director reads it but never writes it.

## Director-Written Files

### directives.md
Append-only dated sections. Written by the director between cycles. Sessions read directives before the watermark check — directives override skip logic.

```markdown
## <ISO timestamp>
<instructions for the session>
```

### manifest-updates.json

Optional JSONL file (one JSON object per line) for incremental manifest changes. Written by the director between runner launches. Consumed by the runner on relaunch, not mid-run.

**Actions:**

`add` -- queue a new item for processing:
```json
{"action": "add", "id": "55", "label": "#55 -- New PR"}
```
The item's `prompt.txt` must already exist in `item-<id>/`. The runner skips items without `prompt.txt`.

`close` -- mark an item as terminal so the runner skips it:
```json
{"action": "close", "id": "49", "reason": "MERGED"}
```
The runner writes a terminal `status.md` for the item on consumption.

### live.md
Written by `stream-monitor.sh` (not the session). Append-only typed entries. See `director-playbook.md` § "live.md Entry Types" for the full format.

## Compatibility Check

A skill is director-compatible if it:
1. Generates `manifest.json` with `items[].id` and `items[].label`
2. Generates `item-<id>/prompt.txt` for each item
3. Generates a runner script (`let-it-rip.sh`)
4. Prompt instructs sessions to write `status.md` and `result.md`
5. Runner writes `state.md` for process lifecycle monitoring (handled by the standard runner template)

Skills using the `Agent` tool directly for parallelism are **not** director-compatible — they bypass the `claude -p` pipeline and get no `live.md` observability, no directive channel, no `state.md` lifecycle tracking, and no kill + retry.
