# Stream Monitor: Python Rewrite

## Problem

`stream-monitor.sh` calls `jq` as a separate process for every JSON event (~3-5 forks per event). At ~25ms per event, a 200-event session adds ~5 seconds of overhead. Workable but noticeably slow.

## Benchmark Results (2026-04-01)

Tested with 13 and 65 events on macOS (darwin 25.4.0):

| Approach | 13 events | 65 events | Per-event cost |
|----------|-----------|-----------|---------------|
| Per-line jq (current) | 351ms | 1,673ms | ~25ms |
| Single jq | 9ms | 13ms | ~0.2ms |
| Python | 561ms | 60ms | ~0.5ms |

- **Per-line jq**: fork+exec overhead dominates. 3-5 jq processes per event.
- **Single jq**: one long-lived process, fastest at parsing. Cannot do file writes — requires tee + process substitution to route output, adding complexity.
- **Python**: 500ms interpreter startup amortized at scale. Native JSON parsing + file I/O in one process. Simplest upgrade path.

## Recommendation

Rewrite `stream-monitor.sh` as `stream-monitor.py`. Python is:
- 100x faster than per-line jq at scale
- Slightly slower than single jq at parsing (~0.5ms vs ~0.2ms) but can do file writes natively
- Simpler than single jq (no tee/process-substitution needed)
- Available on macOS by default (`python3`)

Skip the single-jq middle ground — it's faster at parsing but the complexity of routing output via tee negates the simplicity advantage.

## Implementation Notes

- Keep the same interface: reads JSON from stdin, passes through to stdout, writes `live.md` as side effect
- Use `sys.stdout.write(line); sys.stdout.flush()` for unbuffered passthrough
- `json.loads()` for parsing, native file open/append for `live.md`
- Same PID resolution: read `session.pid` with brief retry
- Same escalation detection: `is_error` field for errors, specific message patterns for permission denials
- Runner template: change `stream-monitor.sh` reference to `stream-monitor.py` (with fallback check)
- Keep `stream-monitor.sh` as a fallback if python3 isn't available (unlikely on macOS but defensive)

## Trigger

Not urgent. Current approach works. Rewrite when:
- Sessions regularly exceed 200 events
- The 5-second overhead becomes noticeable in director monitoring loops
- Or when touching stream-monitor for another reason (good opportunity to rewrite)
