Fault tolerance patterns for distributed and batch-processing systems.
- **Keywords:** dedup, retry, idempotency, circuit breaker, stale cache, scheduler decoupling, domain exceptions
- **Related:** ~/.claude/learnings/financial/applications.md, ~/.claude/learnings/aws/messaging.md

---

### Mark items as processed before processing to prevent reprocessing loops

In reconciliation or batch-processing services, add the item ID to the dedup set (e.g., processedTransactionIds) before attempting processing. If processing throws an exception with the original order (add after processing), the ID is never recorded and the item retries infinitely. Marking first means failed items won't auto-retry, which is the safer default -- failed items should be investigated, not silently retried in a loop.

- **Takeaway**: Dedup-set-add before process, not after. Accept that failures won't auto-retry -- that's a feature, not a bug.

### Use domain-specific exceptions instead of RuntimeException for integration failures

Rethrowing integration errors as generic `RuntimeException` loses error context and prevents targeted error handling upstream. Create specific exception types (e.g., `OtcPostTradeException`) that preserve the original stack trace and enable callers to handle different failure modes differently.

- **Takeaway**: Integration failure exceptions should be domain-typed. Generic RuntimeException is a lost opportunity for error discrimination.

### Scheduler-decoupled maker/checker for vendor submissions

In approval workflows that trigger external vendor calls, decouple the human approval action from the vendor submission. The approve endpoint transitions to APPROVED; a scheduler picks up APPROVED items and submits to the vendor. If the vendor is down at approval time, the item stays APPROVED and the scheduler retries on the next tick — no explicit retry logic needed in the approval path.

- **Takeaway**: Approval + vendor call in the same request couples human action to vendor availability. Scheduler decoupling gives you retry-for-free and keeps the approval response fast.

### Stale validation caches cause silent data loss — choose correctness over performance

A validation filter with frozen reference data (loaded once at startup) caused silent transaction drops in production. No errors, no exceptions — the system appeared healthy but was rejecting valid transactions against stale data. This is worse than a crash because monitoring shows green while business operations fail silently.

The fix: fresh DB lookup per call (correctness) over O(1) stale lookup (performance). Caching with TTL was deferred as a follow-up. In financial/transactional systems, correctness is non-negotiable; performance is optimizable.

- **Takeaway**: Any filter/validator using cached reference data needs drop-rate metrics. Silent drops are worse than crashes. When correctness and performance conflict, ship correctness first.

## Cross-Refs

- `~/.claude/learnings/financial/applications.md` — fee calculation invariants, zero-divisor guards, two-layer idempotency, and "fail loudly" error handling (complements the system-level resilience patterns here)

### Smart fallback for destructive/consumable API endpoints

When integrating with an API where calls are destructive (data marked as consumed on read), implement a dual-endpoint smart fallback: call both the live/intraday endpoint AND a stable/archival endpoint on every poll, then merge and deduplicate results by a stable key (e.g., trade ID). This prevents data loss when a network error occurs after a destructive read but before results are processed — the archival endpoint provides recovery without a retry storm. The deduplication step ensures the caller receives a clean, non-redundant result set regardless of which endpoints returned data.

### Wrap each source independently in multi-source data merges

When calling multiple data sources and merging results, wrap each source call in independent try-catch so failure of one source doesn't suppress the other. Return partial results rather than throwing when any single endpoint fails. This is especially important when one source is a fallback for the other — a thrown exception from the primary endpoint should not prevent the fallback from running.

### Per-item batch loops abort on the first unhandled error — order decides what's skipped

When looping over N items with a per-item fetch/process call, an unhandled exception on item k aborts the whole loop and silently skips k+1..N. Which items get skipped is an artifact of iteration order — e.g. an alphabetical sweep that crashes on `UVXY` silently skips `VX`. Wrap each iteration in try/except to skip-and-continue (logging the skipped item loudly) when partial completion beats all-or-nothing, or make the loop order-independent so a failure can't shadow unrelated items.

### Silent fallback to stale state is worse than crashing (financial code)

In financial/trading systems, a backwards-compat fallback that reads potentially-stale state without logging is a high-severity blind spot during migration windows — monitoring stays green while the algo decides on wrong monetary state (cash, positions, DCA counters). Always log a distinctively-prefixed warning on fallback entry:

```python
logger.warning("LIMITS_FALLBACK: %s not found, falling back to %s", primary, legacy)
```

A unique prefix (`LIMITS_FALLBACK`, `ACCOUNTING_FALLBACK`) makes ops dashboards alertable on it. Prefer a loud fail over a silent succeed whenever the fallback could read stale state — incident diagnosis is far easier with explicit traces than with "system was healthy until balances diverged."

### Capture the vendor error body before `raise_for_status` discards it

`httpx`'s `Response.raise_for_status()` raises `HTTPStatusError` carrying only the status line + URL — the response *body* is dropped. Vendors put the actual reason there (`{"Message": "Invalid trade action."}`), so a 4xx reaches logs as a bare `400 Bad Request` with no cause. Wrap it: `if response.is_error: logger.error(..., response.text)` then `raise_for_status()`. Also: a 4xx short-circuits any `data["Errors"]`-envelope parsing that only runs on a 200, so the logged body is the only signal.

## Symmetric Failure Handling Across Sibling Helpers

When extracting code into sibling helper functions (e.g., `_close_leg` and `_open_leg`, or `_pre_commit` and `_post_commit`), failure-handling must be symmetric. Asymmetry — open leg wraps persistence in `try/except` + CRITICAL log + re-raise, but close leg doesn't — hides risk: the same failure mode exists on both sides, but only one is guarded. **Review heuristic:** when reviewing extracted helpers, scan the diff for failure handling and confirm both siblings have the same pattern. If one has a guard the other doesn't, either both need it or neither does.

## Classify the access pattern before claiming a shared-resource concurrency risk

A shared file/resource touched by multiple processes is not automatically a steady-state hazard. Classify the access pattern first:

- **Load-once-at-startup + write-through cache** — read once at boot, held in memory thereafter, written only as a side effect (e.g. a refreshed OAuth token). The on-disk copy is consumed *only at next restart*, so a corrupt/interleaved write has **restart-only blast radius**, not running-process risk. The fix targets the restart boundary (atomic write), not the hot path.
- **Read-on-hot-path** — re-read every operation; a torn write corrupts live behavior. Genuinely steady-state; needs locking/atomicity now.

Don't escalate a write-through-cache race to "trading-correctness risk." Name *when* the bad state is actually consumed — that sizing changes both severity and the fix.

## Reconciling cached state against an authoritative source: authority vs overlay

When local cached state (a config/limits file) can drift from an authoritative source (the broker/DB), pick the reconciliation policy by blast radius:

- **Source-authority** — held state = exactly what the source reports; drop local entries the source omits. Self-heals *any* desync (an unknown/unwanted position surfaces, gets diffed against target, and is corrected), but a transient empty/errored-but-successful read reads as "nothing there" → can trigger a wrong action (re-open a still-open leg, double-expose).
- **Conservative overlay** — the source adds/overrides entries it reports, but a local entry the source is *silent* on is kept. No glitch-driven wrong action, but leaves a residual gap (a genuine source-side removal the cache still claims).

Source-authority fits when the source read is highly reliable and stale-cache action is the worse failure (it caused the incident). Overlay fits when a transient bad read is likelier than genuine drift. Log every disagreement with a unique prefix so the divergence is alertable either way.

## A fail-open control must hold-last-safe on a stale input while engaged

A circuit-breaker / de-risk control that reads an input each tick and de-risks on a threshold breach must not pass the raw target through on a stale/missing/non-finite input — that *un-does* an in-force de-risk exactly when the feed is likeliest to fail (broker/feed stress correlates with market stress). While **already engaged**: (1) **hold the last safe state** (re-emit the clamp), don't pass through; (2) **still advance any time-based reclaim clock** so an outage can't silently lengthen the sit-out; (3) **defer the un-safe action** (reclaim/re-risk) to a tick with a valid input — re-risking on an unknown mark is unsafe, and a time-out re-baseline needs a real value. With nothing engaged there's no safe state to hold → pass through + alert. Name it honestly: pass-through is fail-*open*, not fail-safe.
