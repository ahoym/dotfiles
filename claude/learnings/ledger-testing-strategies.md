# Ledger Testing Strategies

Ledger-specific testing patterns — accounting invariants, property-based testing with jqwik, reconciliation harnesses, saga compensation paths, period-end validation, chaos testing, and deterministic simulation.
- **Keywords:** ledger testing, property-based testing, jqwik, accounting invariant, double-entry, trial balance, reconciliation, golden dataset, chaos testing, Testcontainers, @DataJpaTest, saga compensation, period-end close, deterministic simulation
- **Related:** domain-ledger-architecture.md, financial-applications.md, resilience-patterns.md, postgresql-query-patterns.md, spring-boot.md

---

## Testing Pyramid Weight

Financial ledgers need more integration and property-based tests than typical services. Unit tests alone can't catch consistency bugs — the DB's isolation, locking, and constraint semantics are the thing being tested.

```
E2E              (critical flows only — deposit, settlement, reversal)
Period-end       (close procedure + snapshot regression)
Chaos/simulation (crash recovery, network partition)
Reconciliation   (golden datasets, exception paths)
Saga/compensation(state machine + fault injection per step)
Integration      (real DB — never mock for financial tests)
Property-based   (double-entry invariants, conservation, idempotency)
Unit             (pure arithmetic, fee calc, debit/credit formulas)
```

Push tests down: if a unit test covers debit/credit arithmetic, don't duplicate it at E2E. But never replace a real-DB integration test with a mock.

## Core Accounting Invariants

Cover these explicitly across the test suite — use the list as a checklist.

| Invariant | What It Catches |
|-----------|----------------|
| `SUM(debits) = SUM(credits)` per transaction | Unbalanced entries, partial writes |
| `SUM(debits) = SUM(credits)` globally (trial balance) | Data integrity, orphaned entries |
| Balance = replay of entries from zero | Stale materialized balances, drift |
| `available >= 0` on every debit | Overdraft bugs, race conditions |
| `available <= settled` | Early-access inflation bugs |
| Money conservation: total assets unchanged across operations | Money creation/destruction bugs |
| Reversals create new entries, never mutate originals | Immutability violations |
| Same idempotency key → same result, single entry count | Duplicate entries on retry |
| Optimistic lock conflict detected on concurrent balance updates | Lost updates |

## Property-Based Testing (jqwik / fast-check / Hypothesis)

PBT is the highest-leverage technique for ledger correctness. The double-entry constraint is a natural property.

**Five properties to always test:**

1. **Debits = Credits (per transaction)** — post a transaction, assert entry sums balance
2. **Conservation of money (global)** — total across all accounts unchanged before/after N operations
3. **Balance derivation** — `SUM(entries)` for account == materialized `ledger_balances` value
4. **Idempotency** — post same idempotency key twice, assert single entry count and identical result
5. **Reversal correctness** — original entries unchanged; reversal entries mirror them; net effect = 0

**Generator design:**
- Generate transactions with valid account pairs, positive amounts in smallest-unit integers, matching debit/credit sides, unique idempotency keys
- Bad generators (random strings for amounts, self-referential transfers) test input validation — not ledger logic
- Use stateful PBT (model-based): generate random op sequences (post, reverse, adjust), compare system under test against an in-memory model after each step

**Java: jqwik**
- JUnit 5 integration — annotate with `@Property` and `@ForAll`
- Supports stateful testing via `@StatefulProperty` and `ActionSequence`
- Excellent shrinking — failing 50-txn sequence shrinks to 2-3 operations
- Don't use "no exception thrown" as a property — it misses logical correctness entirely
- Include explicit example-based tests for known edge cases (zero-amount, precision boundary, max integer)

**CI iteration count**: 100 in standard CI, 10,000 in nightly builds.

## Integration Testing: Real Database Required

Never mock the database for ledger integration tests. Mocks return "success" and hide exactly the bugs that matter — transaction isolation, constraint enforcement, locking behavior.

**What to test:**

- **Transaction isolation** — two concurrent debits with same version should produce one conflict, not two successes
- **Optimistic lock retry** — retry path must re-read balance and re-check constraints before re-attempting UPDATE
- **Idempotency enforcement** — `INSERT ... ON CONFLICT (idempotency_key) DO NOTHING` must hold under concurrent retries
- **Partial write recovery** — simulate crash between entry insert and balance update; verify transaction rolled back completely (no orphaned entry)
- **Running total consistency** — `running_total` column correct after concurrent inserts, reversals, and recovery

**Java: Testcontainers + @DataJpaTest**
- Use `@DataJpaTest` with a real PostgreSQL container (testcontainers)
- `@Transactional` on test class for isolation via rollback — but turn it off for concurrency tests (need multiple threads, each with own transaction)
- Match production DECIMAL precision, CHECK constraints (`amount > 0`, `direction IN ('DEBIT','CREDIT')`), triggers, and indexes
- Shared `@Container` at class level for test-class performance; fresh schema per class for isolation

**Concurrent debit test pattern (JUnit 5):**
```java
ExecutorService pool = Executors.newFixedThreadPool(2);
Future<Result> t1 = pool.submit(() -> ledgerService.debit(accountId, 100, key1));
Future<Result> t2 = pool.submit(() -> ledgerService.debit(accountId, 100, key2));
// exactly one succeeds, one gets OptimisticLockException
assertThat(successCount(t1, t2)).isEqualTo(1);
```

## Saga Compensation Path Testing

Compensation runs rarely but is critical. Test it explicitly — not as an afterthought.

**Test each compensation in isolation first** — verify reversal entry created, balance restored, original entry unchanged.

**Test partial failure at every saga step** — for an N-step saga, write N failure scenarios. For step K failing: execute steps 1..K-1 successfully, fail K, verify compensations fire in reverse order (K-1 .. 1), verify all accounting invariants hold.

**Test compensation idempotency** — fire compensation twice (simulating retry after transient failure); assert no duplicate reversal entry. Compensation idempotency key pattern: `"{saga_key}-step{N}-reversal"`.

**Test compensation failure** — compensation fails after max retries → saga enters `COMPENSATION_FAILED` state, alert fires, original debit entry preserved (no money lost).

**Test concurrent saga interference** — two sagas on the same account, one compensating while the other progresses; optimistic locking must prevent lost updates and both reach a consistent terminal state.

**Orchestrator state machine unit test** — enumerate every valid transition and verify invalid transitions (e.g., `COMPLETED → STEP_1_EXECUTING`) are rejected.

**Temporal / workflow engine (if used):**
- Replay testing: replay completed saga history, assert same result (critical before deploying saga logic changes)
- Signal testing: external signals (e.g., "ACH confirmed") advance state correctly
- Timer testing: timeout after N business days triggers compensation

## Reconciliation Testing

**Golden dataset approach** — maintain curated datasets covering every matching pattern:

| Scenario | Expected Result |
|----------|----------------|
| Exact match (1 entry, 1 bank txn, same amount) | Matched |
| Many-to-one (N deposit entries, 1 ACH batch) | Matched (sum) |
| One-to-many (1 large payment, M wires) | Matched (split) |
| Netting (gross amount minus refunds/fees) | Matched (net) |
| Timing offset (entry Day 0, bank txn Day 1) | Matched within tolerance |
| Duplicate (1 entry, 2 bank txns same amount) | 1 matched, 1 flagged |
| Missing internal (no entry, bank txn present) | Unmatched — escalate |
| Missing external (entry present, no bank txn) | Unmatched — age and escalate |
| Amount mismatch (fee deducted by bank) | Matched within tolerance OR flagged |

**Three-layer reconciliation tests:**
1. **Balance proof** — `SUM(entries per account) == materialized_balance` for every account
2. **Trial balance** — `SUM(all debits) == SUM(all credits)` for the period
3. **Bank reconciliation** — matching algorithm against golden dataset; verify match rates, exception categories, escalation

**Intercompany reconciliation** — for multi-entity ledgers: intercompany receivable on entity A must equal intercompany payable on entity B. Eliminate before consolidated trial balance. Test the elimination entries and the consolidated view separately.

**Exception path testing** — generate synthetic mismatches (duplicate entries, missing payments, incorrect amounts), verify: correct categorization, escalation to ops with appropriate severity, auto-correction rules (entry-vs-materialized auto-corrects; entry-vs-bank requires investigation).

**Scale testing** — reconciliation at 1K txns may fail at 1M. Test: memory usage during many-to-many matching, query performance at production-like volumes, checkpoint window correctness, running total under high concurrency.

## Period-End Close Testing

**Closing balance formula**: `Closing Balance = Opening Balance + Total Credits - Total Debits` must hold exactly for every account.

**Temporary account zeroing** — revenue, expense, withdrawal accounts must zero after close; net rolls into retained earnings; zeroing entries themselves must be balanced.

**Permanent account carry-forward** — opening balance of period N+1 must equal closing balance of period N.

**Late-arriving transactions** — transactions arriving after close: rejected (hard close) or posted to an adjustments account (soft close). Test both paths.

**Prior-period adjustments** — back-dated `effective_date` in current period; adjustment attributed to original period in reports; current period balances correct; closed period snapshot immutable.

**Snapshot regression testing:**
1. Capture trial balance, income statement, balance sheet, and closing entries as golden files after first correct close
2. Run as regression on every code change
3. Treat golden file updates like schema migrations — require explicit review, not silent acceptance
4. Include cross-module cascade: change upstream module (e.g., tax calc), run full close, compare snapshot

## Chaos and Fault Injection Testing

**Five targeted experiments for ledgers:**

| Experiment | Hypothesis | Verify |
|------------|-----------|--------|
| Payment processor blackhole | Pending deposits stay in PENDING_IN, no balance change | Entries unchanged, retry queue populates, alert fires |
| DB connection pool exhaustion | Failed txns return error, no partial writes | No orphaned entries, no balance drift |
| Process crash mid-transaction | DB transaction rolls back, no inconsistency | Balance proof passes on restart, no orphaned entry |
| Outbox publisher failure | Events re-published on restart, no duplicates | All committed entries eventually published; downstream idempotent |
| Clock skew | effective_date ordering preserved, no false reconciliation mismatches | Server-generated timestamps used; recon within tolerance |

**Safety rules:**
- Always have a hypothesis — "let's see what happens" is not chaos engineering
- Measure steady state first (baseline without faults)
- Keep blast radius small (one account, one flow, one minute)
- Start in non-production; graduate to production with kill switch only

**Deterministic simulation (DST)** — full-cluster simulation with all I/O replaced by deterministic simulators. Seed + commit fully determines the run; any failure is reproducible. TigerBeetle's VOPR and FoundationDB both use this approach. For services on PostgreSQL, Antithesis (commercial DST-as-a-service) is the practical alternative to building a custom simulator.

**Jepsen-style testing** — not deterministic, but tests linearizability under real faults. Requires domain-specific checkers to catch balance-constraint violations (generic linearizability checkers miss them).

## Anti-Patterns

| Anti-Pattern | Why Dangerous | Alternative |
|-------------|--------------|-------------|
| Mocking the DB | Hides isolation, locking, constraint bugs | Real PostgreSQL via testcontainers |
| "No exception thrown" as PBT property | Misses logical correctness bugs | Properties must encode domain invariants |
| Testing reconciliation only at small scale | Matching algorithms fail at production volume | Test at realistic data volumes |
| Ignoring compensation paths | Untested compensation = untested money recovery | Inject failures at every saga step |
| Silent defaults on calculation error | Fee calc returns 0, txn processes with zero fees | Fail loudly on any financial calculation error |
| Testing period-end without late-arriving txns | Misses common real-world scenario | Include late-arrival and prior-period adjustment |
| Overly strict assertions on all corruption | Panicking on benign bit flips crashes unnecessarily | Grade corruption severity; degrade gracefully for benign faults |
| Generic linearizability checkers only | Miss domain-specific balance/duplicate bugs | Build domain-specific state machine models |

## Test Infrastructure (Java / PostgreSQL)

- **testcontainers-postgresql** — ephemeral real DB per test class; same constraints, triggers, indexes as production
- **jqwik** — property-based testing with JUnit 5; use `@Property`, `@ForAll`, `ActionSequence` for stateful PBT
- **@DataJpaTest** — loads JPA layer only; wire in testcontainers via `@AutoConfigureTestDatabase(replace = NONE)`
- **Factory helpers** — typed builders for `LedgerAccount`, `LedgerEntry`, `LedgerTransaction`; amounts always in smallest-unit integers, never floats
- **Parallel test execution** — separate schemas per test class; `@Container` shared at class level, not method level (container startup is expensive)
- **CI splits** — property tests at 100 iterations in PR CI, 10K in nightly; integration tests parallelized; reconciliation and chaos tests in dedicated environments

## Cross-Refs

~/.claude/learnings/domain-ledger-architecture.md — schema and balance patterns being tested throughout (entries, accounts, idempotency keys, running totals)
~/.claude/learnings/financial-applications.md — monetary calculation safety rules that determine what counts as a correct result in PBT properties
~/.claude/learnings/resilience-patterns.md — idempotent processing and reprocessing loop prevention tested via outbox and saga compensation paths
~/.claude/learnings/postgresql-query-patterns.md — locking, isolation level, and constraint patterns exercised by ledger integration tests
~/.claude/learnings/spring-boot.md — @DataJpaTest and Mockito 5+ context relevant to Java ledger test configuration
