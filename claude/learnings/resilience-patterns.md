# Resilience Patterns

Fault tolerance patterns for distributed and batch-processing systems.
- **Keywords:** dedup, retry, idempotency, circuit breaker, stale cache, scheduler decoupling, domain exceptions
- **Related:** financial-applications.md, aws-messaging.md

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

- `claude/learnings/financial-applications.md` — fee calculation invariants, zero-divisor guards, two-layer idempotency, and "fail loudly" error handling (complements the system-level resilience patterns here)
