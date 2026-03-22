Period-end close procedures for fintech ledger systems — soft/hard close, closing entries, snapshot implementation, period state machines, balance carry-forward, late-arriving transactions, and continuous accounting.
- **Keywords:** period close, soft close, hard close, closing entries, retained earnings, snapshot, balance carry-forward, late-arriving transaction, prior-period adjustment, accrual reversal, subledger, GL, continuous accounting, @Scheduled, ShedLock, PostgreSQL partitioning
- **Related:** domain-ledger-architecture.md, financial-applications.md, postgresql-query-patterns.md, spring-boot.md, resilience-patterns.md

---

## Soft Close vs Hard Close

Two distinct closing models exist; most production systems implement both in a layered cadence.

**Soft close** — internal management reporting. Only material accounts reconciled; estimates used for predictables (rent, depreciation). Books remain open for adjustments. Output: directional-accuracy management reports, not audit-ready.

**Hard close** — audit-ready. Every account reconciled to external sources, all accruals verified, period locked (no further entries). Output: financial statements suitable for external reporting.

**Hybrid cadence (most common)**:
```
Monthly:  soft close  →  soft close  →  hard close (quarter-end)
Year-end: hard close (includes year-end adjustments + audit prep)
```
Soft closes reduce hard-close work — quarterly hard close becomes verification of estimates vs actuals, not a from-scratch reconciliation.

| Aspect | Soft Close | Hard Close |
|--------|-----------|-----------|
| Period state | `SOFT_CLOSED` | `CLOSED` / `PERMANENTLY_CLOSED` |
| Entry acceptance | Yes | No (adjusting entries only, with approval) |
| Snapshot mutability | Regenerable (estimates may change) | Immutable (changes require restatement) |
| Reconciliation depth | Material accounts only | All accounts |

## Period State Machine

```
FUTURE → OPEN → SOFT_CLOSED → CLOSING → CLOSED → PERMANENTLY_CLOSED
                    │                      │
                    ↓                      ↓
                  OPEN                ADJUSTING
               (reopen)            (limited entries)
                                        │
                                        ↓
                                     CLOSED
                                   (re-close)
```

| State | New entries? | Adjusting entries? | Snapshot? | Reopenable? |
|-------|-------------|-------------------|-----------|-------------|
| `FUTURE` | No | No | No | N/A |
| `OPEN` | Yes | Yes | No | N/A |
| `SOFT_CLOSED` | Limited | Yes | Preliminary | → OPEN |
| `CLOSING` | No (transient) | No | Being generated | No |
| `CLOSED` | No | Yes (approval required) | Immutable | → ADJUSTING |
| `ADJUSTING` | No | Yes (approval required) | Exists, being amended | → CLOSED |
| `PERMANENTLY_CLOSED` | No | No | Final | No |

**Period ordering constraint**: a period cannot be closed if any earlier period is still open. Prevents gaps in the audit trail.

**Multi-entity exception**: when entities close on different schedules, intercompany accounts may reference transactions in open periods in one entity and closed periods in another. Requires reconciliation tolerance windows.

### Java / Spring: @Scheduled Close Orchestration

```java
// Single-threaded scheduler prevents concurrent close attempts
@Scheduled(cron = "0 0 1 * * *", zone = "UTC")  // 1am UTC daily
@SchedulerLock(name = "period-close", lockAtLeastFor = "PT5M")
public void runScheduledClose() {
    periodCloseService.closeEligiblePeriods();
}
```

Use `ShedLock` (or equivalent) to prevent multi-instance execution. The close operation itself must be idempotent — safe to re-run from the beginning on failure.

## Closing Entries: Double-Entry Mechanics

Closing entries zero temporary accounts (revenue, expense) at period end. Only the GL performs closing entries — the subledger does not.

**Sequence**:
1. Close revenue accounts → Income Summary (debit each revenue account, credit Income Summary)
2. Close expense accounts → Income Summary (credit each expense account, debit Income Summary)
3. Close Income Summary → Retained Earnings (net income flows to equity)
4. Close Dividends/Distributions → Retained Earnings

**Subledger vs GL split**:
- Subledger's role at period-end: freeze the period, generate trial balance, produce snapshot for GL consumption
- GL's role: perform the actual closing entries, generate financial statements
- The subledger freeze and GL close are **separate operations with different timing** — subledger must freeze first, then GL closes from the frozen state

## Snapshot Implementation

A period-end snapshot captures the ledger state at the close boundary — the artifact shown to auditors and regulators.

**Contents**: trial balance (SUM(debits) = SUM(credits)), account balances per account, entry count, checksums, metadata (period boundaries, who initiated, timestamp).

### Three Implementation Patterns

**Pattern A — Point-in-Time Query (no physical snapshot)**:
```sql
SELECT ledger_account_id,
       SUM(CASE WHEN direction = 'DEBIT' THEN amount ELSE 0 END) as total_debits,
       SUM(CASE WHEN direction = 'CREDIT' THEN amount ELSE 0 END) as total_credits
FROM ledger_entries
WHERE effective_date BETWEEN $period_start AND $period_end
GROUP BY ledger_account_id
```
Pros: no extra storage, always consistent. Cons: expensive at scale, not truly immutable (backdated entries silently change it).

**Pattern B — Materialized Snapshot Table**:
```sql
CREATE TABLE period_snapshots (
    id              BIGINT PRIMARY KEY,
    period_id       VARCHAR NOT NULL,       -- e.g., '2026-Q1', '2026-03'
    account_id      BIGINT NOT NULL,
    total_debits    NUMERIC(38,18) NOT NULL,
    total_credits   NUMERIC(38,18) NOT NULL,
    closing_balance NUMERIC(38,18) NOT NULL,
    entry_count     BIGINT NOT NULL,
    checksum        VARCHAR,                -- hash of contributing entry IDs + amounts
    snapshot_at     TIMESTAMPTZ NOT NULL,
    created_by      VARCHAR NOT NULL,
    UNIQUE (period_id, account_id)
);
```
Pros: O(1) retrieval, immutable once written, serves as audit artifact. Cons: must be reconciled against entries; requires explicit immutability enforcement.

**Pattern C — Hybrid (recommended)**:
```
close_period(period_id):
  1. Compute snapshot from entries (Pattern A query)
  2. Write to period_snapshots table (Pattern B)
  3. Recompute from entries again
  4. Assert snapshot == recomputation (if mismatch: abort, investigate concurrent writes)
  5. Mark period CLOSED
```
Gives performance of materialized snapshot + auditability of entry-based reconstruction.

### Snapshot Immutability Enforcement

1. **Database**: revoke `UPDATE`/`DELETE` on `period_snapshots` for application roles; only a migration role can modify
2. **Application**: close handler writes once; any re-close creates a new snapshot version with an audit trail delta
3. **Checksum**: hash of all contributing entry IDs + amounts; mismatch signals tampering or illegal backdating
4. **Periodic verification job**: recomputes from entries and compares to materialized snapshot; mismatch triggers alert

### PostgreSQL: Table Partitioning by Period

Partition `period_snapshots` by `period_id` (list partitioning) or `snapshot_at` (range) for large deployments. Range partitioning on `snapshot_at` aligns naturally with archival:

```sql
CREATE TABLE period_snapshots (
    ...
    snapshot_at TIMESTAMPTZ NOT NULL
) PARTITION BY RANGE (snapshot_at);

CREATE TABLE period_snapshots_2026 PARTITION OF period_snapshots
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
```

## Balance Carry-Forward

When a period closes, permanent account balances become opening balances of the next period.

| Account Type | Carry Forward? | Close Treatment |
|-------------|---------------|-----------------|
| Assets | Yes | Opening balance = prior period closing balance |
| Liabilities | Yes | Opening balance = prior period closing balance |
| Equity | Yes | Absorbs net income from Income Summary |
| Revenue | No | Zeroed to Income Summary |
| Expenses | No | Zeroed to Income Summary |

### Three Implementation Options

**Option 1 — Explicit Opening Entries**: Create journal entries on the first day of the new period establishing opening balances (Oracle GL, Dynamics 365 approach). Pros: explicit, auditable, each period is self-contained. Cons: synthetic entries that aren't real transactions.

**Option 2 — Implicit (Query-Based)**: No opening entries; opening balance of period N+1 = SUM of all prior entries. Pros: no synthetic entries. Cons: queries scan from inception, no explicit period boundary in data.

**Option 3 — Checkpoint-Based (recommended for subledgers)**:
```sql
CREATE TABLE balance_checkpoints (
    account_id      BIGINT NOT NULL,
    period_id       VARCHAR NOT NULL,
    closing_balance NUMERIC(38,18) NOT NULL,
    entry_id        BIGINT NOT NULL,    -- last entry included in this checkpoint
    checksum        VARCHAR,
    PRIMARY KEY (account_id, period_id)
);
```
Opening balance for period N+1 = `closing_balance` from period N checkpoint. Current balance = checkpoint + SUM(entries since checkpoint). O(1) lookup, no synthetic entries.

**Risk**: checkpoint drift if entries are incorrectly backdated into the prior period. Verify with periodic reconciliation against entry-based recomputation.

## Late-Arriving Transactions

Transactions that belong to a closed period but arrive after the close require a defined materiality policy.

**Approach 1 — Prior-Period Adjustment (Restate)**: Post with true `effective_date` in the closed period. Requires reopening to `ADJUSTING` state, regenerating snapshot, and re-closing. Use for material amounts or regulatory requirements. Risk: cascading re-close — if period N changes, periods N+1 through current may need opening balance adjustments.

**Approach 2 — Current-Period Catch-Up**: Post in the current open period with metadata linking to original period. GAAP allows this for immaterial prior-period items. Risk: period-over-period comparisons show artificial variance.

**Approach 3 — Accrual + Reversal (planned late arrivals)**: For predictable timing gaps (e.g., vendor invoices always arrive 5 days late), accrue at close and reverse when actual arrives:
```
At close (period end):
    Dr  Expense (estimated)       X
        Cr  Accrued Liabilities       X

When actual arrives (next period):
    Dr  Accrued Liabilities       X    ← auto-reversal on period 1 day
        Cr  Expense (estimated)        X
    Dr  Expense (actual)          X+Δ
        Cr  Accounts Payable          X+Δ
```
Auto-reversal: system generates the reversal entry automatically on the first day of the new period.

**Materiality threshold**: amounts below threshold → current-period catch-up; amounts above → prior-period adjustment. The threshold is a business/accounting decision; the system must support both paths.

## Subledger-to-GL Close Orchestration

```
1. Subledger freeze
   ├── Reject new entries for the period
   ├── Drain in-flight transactions (pending → settled or failed)
   └── Generate subledger trial balance

2. Subledger-to-GL posting
   ├── Aggregate subledger entries into GL journal entries
   ├── Map subledger account types to GL chart of accounts
   └── Post to GL  [idempotent — same subledger state always produces same GL entries]

3. GL adjustments
   ├── Manual adjusting entries (accruals, corrections, reclassifications)
   ├── Automated adjustments (depreciation, amortization, FX revaluation)
   └── Tax provisions

4. GL close
   ├── Verify trial balance
   ├── Generate closing entries (zero temporary accounts)
   ├── Carry forward permanent account balances
   └── Generate financial statements

5. Snapshot and freeze
   ├── Materialize snapshot
   ├── Verify snapshot == entry-based recomputation
   └── Mark period CLOSED
```

### Failure Handling

| Failure Point | Recovery |
|--------------|---------|
| Subledger freeze fails (in-flight txns) | Wait for in-flight to resolve, retry freeze |
| SL→GL posting fails | Retry (idempotent). On partial failure: roll back and retry entire batch |
| Snapshot mismatch | Investigate entries written during close window, re-run |
| Close job crashes mid-way | Re-run from beginning — entire close operation must be idempotent |

### Multi-Entity and Intercompany Alignment

- When entities close on different schedules, intercompany accounts may reference open-period transactions in one entity and closed-period transactions in another
- Define a reconciliation tolerance window (e.g., T+3 days) where intercompany differences are acceptable before escalating
- Use a canonical UTC close boundary — `effective_date` must be UTC-normalized before period assignment; a transaction at 11pm PST vs 2am EST lands in different periods if time zones are not handled consistently

## Continuous Accounting

Traditional period-end close concentrates reconciliation and accrual work into a burst. Continuous accounting distributes this work across the entire period.

**Core operations run continuously** (not at period-end):
- Daily bank reconciliation: match bank transactions as they clear, not in a batch
- Real-time accrual: post expenses when invoices are received, not at close
- Running trial balance: always current, computed continuously
- Anomaly detection: flag variance as it occurs

**What continuous accounting does not eliminate**: the period-end close still exists, but becomes a **verification step** (hours, not days). Steps: verify running trial balance is correct → post any final adjustments → generate snapshot → freeze period → produce financial statements.

**Implementation requirements**: webhook-based bank feeds (not batch statement ingestion), automated rules-based or ML-based transaction matching, a continuously-accurate `ledger_balances` table (the three-table schema running balance), aging alerts when reconciliation items exceed thresholds.

**Relationship to intra-day recon**: continuous accounting is the read-side complement to event-driven reconciliation (see `domain-ledger-architecture.md`). Period-end close in a continuous model = run on-demand verification one final time, confirm match, freeze and snapshot.

## Anti-Patterns

1. **Closing without freezing first** — generating a snapshot while entries are still being written produces non-deterministic results. Always: freeze → snapshot → verify → close.

2. **No materiality threshold for late arrivals** — treating every late-arriving transaction as a prior-period adjustment creates endless re-close cycles.

3. **Mutable snapshots** — allowing in-place updates to period snapshots destroys the audit trail. Snapshots must be append-only (new versions, never overwritten).

4. **Binary period state (OPEN/CLOSED only)** — missing `SOFT_CLOSED`, `CLOSING`, and `ADJUSTING` states forces binary choices that don't match operational reality.

5. **Closing GL before subledgers** — GL close is meaningless if subledger entries are still flowing in. Oracle explicitly prevents GL period close when subledger periods are open.

6. **No checksums on snapshots** — without entry-based verification, snapshot corruption or tampering is undetectable until audit.

7. **Time zone inconsistency in period assignment** — `effective_date` must be normalized to a single canonical time zone (UTC) before determining period membership.

8. **Hard-closing every month** — full hard close monthly is resource-intensive and usually unnecessary. Monthly soft close + quarterly/annual hard close is the standard cadence.

## Cross-Refs

- `~/.claude/learnings/domain-ledger-architecture.md` — Three-table schema, ledger_balances running balance, intra-day reconciliation (foundation for continuous accounting)
- `~/.claude/learnings/financial-applications.md` — Monetary calculation safety, idempotency patterns (relevant to SL→GL posting and snapshot checksums)
- `~/.claude/learnings/postgresql-query-patterns.md` — Window functions, partitioning, migration safety (period snapshot table design)
- `~/.claude/learnings/spring-boot.md` — @Scheduled, ShedLock, transaction boundaries (close orchestration in Java)
- `~/.claude/learnings/resilience-patterns.md` — Idempotent processing, reprocessing loop prevention (close job failure recovery)
