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

### Silent fallback to stale state is worse than crashing (financial code)

In financial/trading systems, a backwards-compat fallback that reads potentially-stale state without logging is a high-severity blind spot during migration windows — monitoring stays green while the algo decides on wrong monetary state (cash, positions, DCA counters). Always log a distinctively-prefixed warning on fallback entry:

```python
logger.warning("LIMITS_FALLBACK: %s not found, falling back to %s", primary, legacy)
```

A unique prefix (`LIMITS_FALLBACK`, `ACCOUNTING_FALLBACK`) makes ops dashboards alertable on it. Prefer a loud fail over a silent succeed whenever the fallback could read stale state — incident diagnosis is far easier with explicit traces than with "system was healthy until balances diverged."

## Symmetric Failure Handling Across Sibling Helpers

When extracting code into sibling helper functions (e.g., `_close_leg` and `_open_leg`, or `_pre_commit` and `_post_commit`), failure-handling must be symmetric. Asymmetry — open leg wraps persistence in `try/except` + CRITICAL log + re-raise, but close leg doesn't — hides risk: the same failure mode exists on both sides, but only one is guarded. **Review heuristic:** when reviewing extracted helpers, scan the diff for failure handling and confirm both siblings have the same pattern. If one has a guard the other doesn't, either both need it or neither does.
