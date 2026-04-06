---
description: "Design sketch for a /sweep-status skill — reads sweep artifacts, computes monitoring table, evaluates convergence. Building block for automated director dispatch."
status: draft
---

# `/sweep-status` — Design Sketch

Discrete skill that reads sweep run artifacts and returns structured director state. Useful standalone for monitoring and as a building block for notification-driven director dispatch.

## Inputs

- `RUN_DIR` (required) — path to a sweep run directory (review or address)
- `--format=table|yaml|both` (default: both)

## What It Does

1. Read `manifest.json` for eligible/skipped PR list and mode
2. Read all `pr-*/status.md` — extract milestone, pr_state, mergeable, watermarks, updated_at
3. Read all `pr-*/result.md` — extract latest section's findings, inline comments, auto-implemented, escalated counts
4. Compute monitoring table (full or delta from previous `director-state.md`)
5. Evaluate convergence rules (from playbook):
   - Review: all-skip for 30m → converged
   - Address: all PRs terminal → converged; CONFLICTING on any open PR → not converged
6. Detect actionable conditions:
   - Summary-only findings (findings > 0, inline_comments == 0) → flag for director directive
   - CONFLICTING PRs → flag for conflict resolution directive
   - Errored sessions → flag for investigation
7. Write `director-state.md` to RUN_DIR
8. Return structured output

## Output

```yaml
cycle: <N>
review_cycles: <N>
address_cycles: <N>
convergence:
  review: converged | not-converged | auto-cancelled
  address: converged | not-converged
context_tokens_approx: <from task notifications if available>
last_updated: <ISO timestamp>
actions_needed:
  - type: summary-finding-directive
    pr: 52
    detail: "findings=1, inline_comments=0 in latest review"
  - type: conflict-resolution-directive
    pr: 50
    detail: "mergeable=CONFLICTING"
monitoring:
  - pr: 52
    state: OPEN
    mergeable: MERGEABLE
    review_milestone: done
    address_milestone: done
    runner_state: completed
    attempt: 1/2
    directives: --
```

## Director Dispatch Integration (future)

With `/sweep-status` as a primitive, the director loop becomes:

```
loop:
  launch review runner (background)
    <- notification: done
  /sweep-status review-run-dir
  write any directives from actions_needed
  if review not converged:
    launch address runner/agent (background)
      <- notification: done
    /sweep-status address-run-dir
    write any directives from actions_needed
  check both convergence states
  if both converged: exit loop
```

The director doesn't poll or sleep — it reacts to completion notifications and uses `/sweep-status` to decide the next action. Each `/sweep-status` call is cheap (reads local files, no API calls except for convergence clock checks).

## Open Questions

- Should `/sweep-status` read both review AND address run dirs in one call, or stay single-mode?
- Should it write directives directly, or just flag actions for the director to write? (Leaning toward flag-only — directors should decide whether to act on each flag.)
- How to surface context token usage? Task notifications include token counts, but the director would need to track cumulative usage across cycles.
