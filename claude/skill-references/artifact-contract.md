---
description: "Standard artifact contract for director-managed skills. Any skill producing this structure gets full director integration: stream monitoring, live.md observability, directives, kill + retry."
---

# Artifact Contract

Skills that produce this structure can be launched and monitored by `/director`.

## Directory Structure

```
<RUN_DIR>/
├── manifest.json           # What to run, metadata
├── let-it-rip.sh           # Generated runner script
├── directives.md           # Global directives from director (optional, append-only)
└── item-<id>/
    ├── prompt.txt          # Input piped to claude -p
    ├── directives.md       # Per-item directives (optional, append-only)
    ├── session.pid          # Written by runner (sh -c/exec pattern)
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

## Director-Written Files

### directives.md
Append-only dated sections. Written by the director between cycles. Sessions read directives before the watermark check — directives override skip logic.

```markdown
## <ISO timestamp>
<instructions for the session>
```

### live.md
Written by `stream-monitor.sh` (not the session). Append-only typed entries. See `director-playbook.md` § "live.md Entry Types" for the full format.

## Compatibility Check

A skill is director-compatible if it:
1. Generates `manifest.json` with `items[].id` and `items[].label`
2. Generates `item-<id>/prompt.txt` for each item
3. Generates a runner script (`let-it-rip.sh`)
4. Prompt instructs sessions to write `status.md` and `result.md`

Skills using the `Agent` tool directly for parallelism are **not** director-compatible — they bypass the `claude -p` pipeline and get no `live.md` observability, no directive channel, and no kill + retry.
