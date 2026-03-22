Ledger migration patterns — balance-first to entry-first retrofit, dual-write architectures, zero-downtime cutover, balance recomputation, schema evolution, and multi-entity rollout strategies.
- **Keywords:** ledger migration, balance-first, entry-first, dual-write, CDC, strangler fig, shadow ledger, genesis entry, balance recomputation, Flyway, Spring Batch, PostgreSQL bulk import, idempotency key retrofit, multi-entity rollout
- **Related:** domain-ledger-architecture.md, postgresql-query-patterns.md, spring-boot.md, financial-applications.md, resilience-patterns.md

---

## Why Balance-First Systems Break

**Audit gaps** — without entries you cannot reconstruct how a balance was reached; regulators can't be satisfied. **Undetectable drift** — nothing prevents a bug from incorrectly updating a balance; you discover it at reconciliation time, if at all. **Reconciliation failures** — without entries, reconciling against external systems (bank statements, card network settlement files) requires reconstructing history from logs, which is fragile. **Reporting bottlenecks** — SQL GROUP BY aggregations over mutable balance rows don't scale; event-based entry systems do.

## Migration Architecture Selection

| Scenario | Pattern |
|----------|---------|
| Small dataset, brief downtime acceptable | Big-bang cutover |
| Large dataset, zero-downtime required | Incremental / phased (Coinbase model) |
| Multiple transaction types, gradual rollout | Strangler fig (route per transaction type) |
| High-risk system, need confidence before cutover | Shadow ledger / parallel run (Uber model) |
| Streaming/event-driven architecture | CDC-based migration (Debezium / DMS) |

**Incremental / phased (recommended default):**
1. Legacy only
2. Dual-write both systems; read legacy; log discrepancies
3. Backfill historical data into new system
4. Favor new system; legacy as fallback
5. Decommission legacy after confidence period

Coinbase's three principles: **make it repeatable** (expect to fail and retry), **make it fast** (iterate quickly on failures), **make it uneventful** (no disruption to normal operations).

## Dual-Write Pattern

Write every new transaction to both old and new systems during transition.

| Approach | Pros | Cons |
|----------|------|------|
| Application-level dual-write | Full control, data transformation | Distributed transaction risk |
| CDC-based (Debezium / DMS) | Decoupled, no app changes | Eventual consistency, schema mapping |
| Transactional outbox | Eliminates dual-write inconsistency | Requires outbox table + consumer |

**Transactional outbox is preferred:** write to primary DB and an outbox table in one transaction; a separate process reads the outbox and writes to the secondary system. Eliminates the partial-failure window.

## Strangler Fig for Ledgers

1. Place a ledger API facade in front of the legacy balance store
2. Route new transaction types to the new entry-based ledger
3. Migrate existing transaction types one at a time
4. The facade handles routing and model transformation
5. Once all traffic routes to new system, decommission legacy store

**Shadow traffic testing:** route copies of production requests to both systems; compare responses; log discrepancies without affecting users. Proceed to cutover when discrepancy rate drops below threshold (target: 0.01% for critical services).

## Shadow Ledger / Parallel Run

Run the new ledger alongside the old, processing all transactions in both, but serving results from the old system until confidence is established.

**Uber's approach (1.2 PB, 1+ trillion entries):**
- Shadow writes → compare real-time results
- Offline batch comparison (Spark jobs) → catch cold-data issues
- Incremental confidence building → gradually shift read traffic
- Zero data inconsistencies detected in 6 months of production
- Kept old system for 1 month after full cutover before decommission

## Synthetic Opening Balance Entries (Genesis Entries)

When migrating from balance-first, you need a starting point for the entry log.

```
For each account with existing balance B:
  Create entry:
    debit_account:  [account]
    credit_account: OPENING_BALANCE (equity account)
    amount:         B
    timestamp:      last moment before new system goes live
    metadata:       { type: "genesis", migration_id: "...", source_balance: B }
```

**Key decisions:**
- Use a dedicated `OPENING_BALANCE` or `MIGRATION_EQUITY` counterparty — standard accounting practice
- Tag genesis entries clearly so business logic can exclude them when needed
- Start with genesis entries for go-live, then backfill historical entries in background batches

## Historical Entry Reconstruction

| Approach | Audit completeness | Complexity | Risk |
|----------|--------------------|------------|------|
| Genesis entries only | Partial — pre-cutover history opaque | Low | Low |
| Full reconstruction | Complete — all history in entry format | High | Medium — reconstruction errors |
| Hybrid (genesis + recent history) | Good — recent visible, older summarized | Medium | Medium |

Recommended: genesis entries for go-live, background backfill for full history. Gets you running fast while preserving the option.

## Balance Recomputation

**Preserve existing balances when:** you trust current balances (verified against external sources), historical entries are incomplete (genesis-only), or recomputation cost is prohibitive.

**Recompute balances when:** you have complete entry history, you suspect drift, you're changing the balance calculation model (e.g., adding pending states), or regulatory requirements demand provable balance derivation.

**Balance caching options:**
1. **Materialized balance cache** — cached `current_balance` on the account row, updated on each entry. Best for high-volume accounts. Validate periodically against full recomputation.
2. **Periodic snapshots** — store balance checkpoints; sum entries since last checkpoint. Good middle ground.
3. **Full recomputation** — always `SUM()` all entries. Simple but O(n). Only viable for low-volume accounts.

### Java / PostgreSQL: Flyway Repeatable Migrations for Balance Recomputation

Use Flyway repeatable migrations (`R__` prefix) for balance recomputation SQL that needs to re-run after each backfill batch. Store the checksum-triggering logic in a versioned view or function so Flyway re-executes on schema change without manual intervention.

```sql
-- R__recompute_account_balances.sql
-- Flyway re-runs when file content changes
UPDATE ledger_accounts a
SET cached_balance = (
    SELECT COALESCE(SUM(CASE WHEN direction = 'CREDIT' THEN amount ELSE -amount END), 0)
    FROM ledger_entries e
    WHERE e.ledger_account_id = a.id
      AND e.state = 'SETTLED'
)
WHERE needs_recompute = true;
```

### Java / Spring Batch: Entry Backfill

Use Spring Batch for large-scale historical entry backfill — chunk-oriented processing gives you restart-on-failure, progress tracking, and configurable batch sizes.

```java
@Bean
public Step backfillEntriesStep(JobRepository jobRepository,
                                 PlatformTransactionManager txManager) {
    return new StepBuilder("backfillEntries", jobRepository)
        .<LegacyTransaction, LedgerEntry>chunk(1000, txManager)
        .reader(legacyTransactionReader())    // paginated JPA reader
        .processor(entryTransformProcessor()) // maps to double-entry format
        .writer(ledgerEntryWriter())          // idempotent write via ON CONFLICT DO NOTHING
        .build();
}
```

Key: the writer must be idempotent — use `INSERT ... ON CONFLICT (idempotency_key) DO NOTHING` so restarts are safe.

## Discrepancy Handling Framework

Uber: "when migrating historical data, there are always data corruption issues." Plan for it.

**Expected sources:**
- Storage-level corruption (even "11 nines" durability means ~10 corruptions per trillion records)
- Eventual-consistency timing differences between old and new system writes
- Rounding differences in currency calculations
- Business logic bugs in the old system now made visible

**Handling process:**
1. **Categorize** — data error, timing issue, or legitimate calculation difference?
2. **Quantify** — sub-cent? sub-dollar? material?
3. **Isolate** — dump problematic records separately; continue migration
4. **Investigate** — trace root cause per category
5. **Resolve** — create adjustment entries in new system (never silently fix or mutate)
6. **Document** — maintain audit trail of all discrepancy resolutions

## Reconciliation Checkpoint Architecture

Run both types during migration:
- **Transaction-oriented** — did each individual money movement replicate correctly?
- **Balance-oriented** — do aggregate balances match between internal ledger and external sources (bank accounts, partner systems)?

**Checkpoint schedule:**
- After genesis entry creation
- After each historical backfill batch
- Continuously during dual-write phase
- Final comprehensive comparison before decommission
- Allow 72–96 hours validation time after technical cutover

**Uber targets:** 99.99% completeness and correctness during shadow validation, upper bound 99.9999%.

## Schema Evolution: Adding New Entry States

When adding states (e.g., `PENDING_IN`, `PENDING_OUT`) to a system that only has `POSTED`:

1. Add new enum values — for PostgreSQL use `ALTER TYPE ... ADD VALUE` (append-only, backward-compatible) or use VARCHAR with application-level validation
2. Existing entries remain in old states — no backfill required
3. New code paths create entries in new states; old code paths see only known states
4. Gradually update read queries to be state-aware

Modern Treasury's state machine: **Pending** (mutable, during processing) → **Posted** (immutable, completed) → **Archived** (historical/error). Entries mutable while pending, immutable once posted.

## Schema Evolution: Signed Amounts to Debit/Credit Model

Using a single `amount` column with sign convention obscures account normality and is an "accounting no-no."

**Migration approach:**
1. Add nullable `debit_amount` and `credit_amount` columns
2. Backfill from existing `amount` using sign-to-direction mapping
3. Dual-write at column level: write both old and new columns during transition
4. Validate: `amount == debit_amount - credit_amount` (per your sign convention)
5. Switch read paths to new columns; drop old column when safe

**Balance calculation by normality:** credit-normal accounts = `SUM(credits) - SUM(debits)`; debit-normal = `SUM(debits) - SUM(credits)`.

## Schema Evolution: Adding Idempotency Keys Retroactively

1. Add nullable `idempotency_key` column
2. Generate synthetic keys for existing entries: `CONCAT(source_system, ':', original_transaction_id, ':', entry_sequence)`
3. Add unique index `CONCURRENTLY` — avoids write lock
4. Require idempotency keys on all new entries in application code
5. Make column `NOT NULL` after backfill

## PostgreSQL-Specific Migration Safety

- **Add nullable columns first** — `ALTER TABLE entries ADD COLUMN x UUID` doesn't lock; doesn't break existing code
- **Backfill in batches** — 1,000–10,000 rows per batch to avoid long-running transactions
- **NOT NULL constraint after backfill** — `ALTER TABLE ... ADD CONSTRAINT ... NOT VALID` then `VALIDATE CONSTRAINT` separately (shares lock only briefly during validation)
- **Concurrent index creation** — `CREATE INDEX CONCURRENTLY` avoids write lock; Coinbase relied on this heavily during 1B+ row migration
- **Bulk import into unindexed staging tables** — direct import into indexed production tables is too slow; import unindexed, then add indexes concurrently
- **Logical replication for dual-write** — PostgreSQL logical replication (`pglogical`, AWS DMS) can replay WAL to populate the new system without application changes; useful when CDC is preferred over app-level dual-write

## In-Flight Transactions During Cutover

Options when a transaction is half-complete at cutover:

1. **Drain before cutover** — stop accepting new transactions, wait for in-flight to complete, then switch. Simple, requires brief downtime.
2. **Finish in legacy, migrate completed** — let in-flight transactions complete in old system; migrate completed records as a second wave.
3. **Middleware buffering** — queue incoming transactions during cutover window; replay against new system once active.
4. **Per-transaction-type migration** — never have a single cutover moment; each type migrates independently. In-flight of type A stay on old system while type B already runs on new system.

**Document cross-system edge cases explicitly** — e.g., a payment authorized in the old system that settles in the new system. Which system records the settlement? Define this before migration starts.

## Multi-Entity Migration Coordination

When migrating a system with multiple entity types (e.g., customers, merchants, internal accounts) or multiple services:

- **Entity-by-entity rollout** — migrate one entity type at a time. Validate fully before moving to the next. Rollback scope is bounded to a single type.
- **Feature flags per entity type** — gate the new ledger path behind a flag; enable incrementally by entity type or cohort.
- **Shared reconciliation infrastructure** — build the reconciliation pipeline before migration starts and reuse it across all entity types. Don't build per-entity reconciliation in parallel.
- **Unified audit trail** — ensure adjustment entries from all entity migrations land in the same audit log with consistent metadata schema.

## Rollback Strategy

Define rollback criteria before migration begins — not during an incident.

**Criteria to define in advance:**
- More than N critical errors in financial data
- Inability to process settlements on schedule
- Compliance reporting failures
- Balance discrepancies above materiality threshold
- Performance degradation beyond acceptable limits

**Implementation:** Keep the old system live in read-only mode for at least the defined confidence period (Uber: 1 month). Phase 3 of the Coinbase model explicitly preserves legacy as a fallback read source.

**Rollback plan must include:** precise reversible steps and a named decision owner with authority to call it.

## Anti-Patterns

1. **Skipping dual-write phase** — going straight old → new without parallel validation
2. **Application-level backfill for large datasets** — use ETL/bulk import instead (Coinbase lesson: 1B+ rows via `aws_s3` PostgreSQL extension)
3. **Mutating entries to fix discrepancies** — always create new correcting entries; never update immutable records
4. **Silent discrepancy resolution** — all fixes must be auditable
5. **No rollback plan** — define criteria and procedures before starting
6. **Mixing migration and feature work** — migration is complex enough without simultaneous business logic changes
7. **Underestimating timeline** — Uber's migration took 2 years

## Cross-Refs

`~/.claude/learnings/domain-ledger-architecture.md` — core ledger schema (accounts, entries, states) that migration patterns operate on
`~/.claude/learnings/postgresql-query-patterns.md` — general migration safety, Flyway patterns, concurrent index creation, NOT VALID constraint pattern
`~/.claude/learnings/spring-boot.md` — Spring Boot and Spring Batch migration orchestration patterns
`~/.claude/learnings/financial-applications.md` — monetary calculation safety and error handling during migration
`~/.claude/learnings/resilience-patterns.md` — idempotent processing patterns relevant to backfill writers and dual-write consumers
