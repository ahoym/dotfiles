Patterns for fintech ledger systems — schema design, balance composition, and money movement lifecycle.
- **Keywords:** ledger, double-entry, ledger_entries, ledger_balances, pending, settled, reconciliation, trial balance, FX conversion, multi-entity, intercompany, period close, closing entries
- **Related:** financial-applications.md, bignumber-financial-arithmetic.md, order-book-pricing.md

---

## Core Schema: Three Tables

**`ledger_accounts`** — named buckets that categorize value (e.g., `customer_cash`, `pending_deposits`). Each has: `account_type` (ASSET/LIABILITY/REVENUE/EXPENSE), `normal_side` (DEBIT/CREDIT), `currency`, and `owner_type`/`owner_id`.

**`ledger_entries`** — append-only log of all money movement. Always-positive `amount` with `direction` (DEBIT/CREDIT). Key fields: `ledger_account_id`, `state` (PENDING_IN/PENDING_OUT/SETTLED/REVERSED), `source_type`/`source_id` (links back to domain tables like deposits, trades), `transaction_id` (groups entries that must balance — double-entry constraint), `idempotency_key` (prevents double-posting on retry).

**`ledger_balances`** — materialized balance per account with `settled`, `pending_in`, `pending_out` columns and a `version` for optimistic locking. Performance optimization over the entries — entries are authoritative, balances are a cache. Entry write + balance update happen in the same DB transaction.

## Balance Views Are Composition Over Accounts

A "customer balance" is a **product concept**, not a ledger concept. It's assembled from multiple ledger accounts, each with their own rules:

- `customer_cash` — settled, withdrawable
- `customer_cash_early` — usable (trade/spend) but not withdrawable until settlement
- `customer_rewards` — usable but never withdrawable
- `pending_deposits` — visible but not usable

**Composition defines the views:**
- `available_to_use = SUM(customer_cash, customer_cash_early, customer_rewards WHERE settled)`
- `available_to_withdraw = SUM(customer_cash WHERE settled)` (stricter)
- `pending_incoming = SUM(pending_deposits WHERE pending_in)`

Separate accounts make rules structural rather than conditional — no "which dollar is this?" logic on every operation.

## Config-Driven Balance Composition (Option B)

Define balance views as config (YAML or code records) mapping view names → included account types + states + subtracted accounts. A generic service resolves any view by querying the relevant accounts and summing. Adding a new view (e.g., `buying_power` including margin) is config-only — no new code. Works well for **read-side** aggregation; write-side enforcement (velocity limits, risk scoring) typically stays in code.

## Entry Lifecycle and State Transitions

```
PENDING_IN → SETTLED → PENDING_OUT → COMPLETED
     │            │
     ↓            ↓
  FAILED      RESERVED → RELEASED (back to SETTLED)
                  │
                  ↓
              DEDUCTED (dispute lost)
```

## Deposit with Early Access Pattern

Customer deposits $500 via ACH. Risk engine approves early access:

1. **Initiation**: credit `customer_cash_early` (SETTLED — customer can use it), debit `pending_deposits` (PENDING_IN — bank owes us)
2. **Settlement**: clear `pending_deposits`, credit `cash_at_bank`, debit `customer_cash_early`, credit `customer_cash` (promote to withdrawable)
3. **Failure** (ACH returns): reverse `customer_cash_early`, clear `pending_deposits`, create `customer_negative` if already spent

The gap between early access and settlement is the company's credit risk exposure — `pending_deposits` aggregate is a key risk metric.

## Pending Withdrawals as Accounts Payable

`pending_withdrawals` mirrors AP: money debited from `customer_cash` immediately (can't spend it), held as a payable until the bank confirms the outbound transfer, then cleared against `cash_at_bank`.

The fundamental equation that must always hold: `cash_at_bank + pending_deposits = customer_cash + pending_withdrawals` (assets = liabilities). Reconciliation verifies this continuously.

## Account-Per-Currency vs Separate Ledger Accounts

**Account-per-currency** groups `cash`, `pending_in`, `pending_out` as columns on a single row per customer+currency. Fewer accounts, intuitive for basic flows. Breaks down when balance types don't fit the shape (rewards, dispute holds, early access cash) or when platform accounts need different structures (buffers, LP payables, revenue).

**Hybrid approach** (most common): group balances that always exist together and share the same lifecycle into one account row. Split things with different rules or conditional existence into separate ledger accounts. Customer core balances → grouped; rewards, holds, platform accounts → separate ledger accounts.

## Settled vs Available Balance

`settled` = fully cleared funds. `available` = what the customer can act on right now. They differ when holds or pending outflows exist:

```
available = settled - holds - pending_out
```

Invariants: `available >= 0` (enforced on every debit), `available <= settled` (can never exceed cleared funds). The `available <= settled` constraint means early access can't be represented by inflating `settled` or allowing `available > settled` — requires either a `cash_early` column or a separate ledger account.

**Storage pattern**: maintain `available` as a stored column for O(1) enforcement on spend/withdraw operations, but periodically reconcile against `settled - holds - pending_out` to catch drift. Same cache-and-verify pattern as entries→balances.

## FX Conversion with Spread Revenue

Multi-currency conversion creates entries across both currency domains. Key accounts: `customer_cash_{ccy}` (both sides), `platform_fx_revenue` (spread), `platform_jpy_buffer` (liquidity inventory), `platform_lp_payable` (external sourcing).

Spread = difference between mid-market rate and quoted rate, recognized as revenue at conversion time. Buffer drawdown + LP sourcing happen on the platform side independently of the customer credit. Revenue account has `account_type: REVENUE` — same entry mechanics as any other account, but rolls up to income statement (not balance sheet) in GL.

## Multi-Entity Ledger Patterns

When separate legal entities participate in one flow (e.g., Collection Co receives customer deposit, FX Co sources currency), each entity maintains its own ledger with intercompany accounts:

- `entityA_interco_payable_to_B` / `entityB_interco_receivable_from_A` — mirror accounts that must reconcile to zero after settlement
- Entity B can control assets custodied at Entity A's bank (e.g., `entityB_jpy_buffer_at_A`) — B instructs movements but bank only sees Entity A's account. B reconciles against A's bank confirmation, not its own bank statement.
- Same bank transaction can be relevant to both entities' ledgers but only appears on one bank statement

Each entity has separate revenue accounts, separate P&L, separate GL. At consolidated level, intercompany transactions net out.

## Bank Reconciliation

Bank reconciliation is **matching**, not row-by-row comparing. Company ledger entries and bank transactions differ in granularity, timing, and structure:

- **Many-to-one**: 50 individual deposit entries → 1 ACH batch on bank statement
- **One-to-many**: 1 large payment → bank splits across multiple wires
- **Netting**: processor settles gross - refunds - fees as single net deposit
- **Timing**: company posts wire Day 0, bank processes Day 1
- Processor reports often serve as the **bridge** between company's granular entries and bank's batched transactions

Only `cash_at_bank` entries have bank statement counterparts. Customer balances, revenue, intercompany — all internal bookkeeping with no bank equivalent.

## End-of-Day Reconciliation Process

Three layers, escalating severity:

1. **Balance proof** (internal): recompute each account's balance from entries, compare to materialized balance. Mismatch = bug (partial write, race condition). ⚠️
2. **Trial balance** (internal): verify SUM(debits) = SUM(credits) across all entries for the period. Imbalance = data integrity issue. 🔴
3. **Bank reconciliation** (external): match bank statement transactions to `cash_at_bank` entries. Most mismatches are normal (timing, fees, batching). Unknown transactions → escalate to ops/compliance.

Process: freeze/snapshot → balance proof → trial balance → ingest bank feeds → match → report → escalate unresolved items.

## Intra-Day Reconciliation

Same three layers as EOD, different cadence and trigger model:

**Event-driven (inline)**: double-entry validation and balance assertions at write time. Preventive — rejects bad writes before they persist. Essential for `cash_at_bank` and high-value accounts. Real-time bank webhook matching replaces batch statement ingestion.

**Cadenced (background)**: tiered by risk. Tier 1 (cash accounts) every few minutes, Tier 2 (customer accounts) every 5-15 min, Tier 3 (revenue/interco) hourly. Runs against read replicas. Tracks checkpoints per account to avoid full-history scans.

**On-demand**: same code as cadenced, triggered manually by ops. Used post-deployment, pre-large-payout, during incidents, or when dashboard metrics look unusual.

Intra-day complements EOD — reduces the chance EOD finds anything surprising. Ideal: nightly batch runs, finds zero discrepancies, report is boring.

## Recon at Scale

Progression to avoid primary DB load:

1. **Dedicated recon replica** — separate from application read replicas, can have recon-optimized indexes
2. **Checkpoints + windowed queries** — maintain `(account_id, balance_at_checkpoint, last_entry_id)`, only scan entries since checkpoint
3. **Running totals on entries** — add `running_total` column, write-time cost is one addition, recon becomes single-row lookup: `last_entry.running_total == materialized_balance`
4. **Stream-based projection** — entry events → Kafka/Kinesis → recon consumer builds own balance projection in memory, compares to replica periodically. Zero load on primary.

**Replica lag handling**: skip entries newer than N seconds in cadenced checks, use threshold tolerance for small drift, only hit primary for on-demand definitive checks.

**Operational nuances**: alert fatigue from false positives (replica lag, timing mismatches) is the main risk — tune thresholds continuously. Adjust cadence by business hours (tighter during peak, looser off-peak). Intercompany recon needs wider tolerance windows — two entities posting their sides asynchronously creates a natural mismatch window. Bank webhook reliability varies by institution (tier 1 banks: real-time; smaller banks: hourly batches or missing events). Golden record rule: entries win over materialized balances (auto-correct), but entries vs. bank requires investigation before correction (could be bank's error).

## Period Close and Closing Entries

Revenue and Expense are **temporary equity accounts** — they track period-scoped detail (earned/spent *this quarter*) then reset. Assets, Liabilities, and Equity are permanent (point-in-time balances that accumulate forever).

**Closing entries** zero out Revenue and Expense into Retained Earnings (equity) at period end:
- Debit each Revenue account (zeroing it), Credit Retained Earnings
- Debit Retained Earnings, Credit each Expense account (zeroing it)
- Net effect: Retained Earnings changes by the period's profit/loss

Mechanically just normal double-entry transactions — no special ledger engine support needed. Some systems use an intermediate **Income Summary** account (Revenue/Expense → Income Summary → Retained Earnings) for audit clarity.

The full equation during a period: `Assets = Liabilities + Equity + (Revenue - Expenses)`. After close: Revenue and Expense are zero, their net has rolled into Equity.

## Cross-Refs

- `financial-applications.md` — calculation safety, idempotency, decimal precision (complements the structural/schema patterns here)
- `bignumber-financial-arithmetic.md` — frontend financial arithmetic precision
- `order-book-pricing.md` — pricing patterns for trading domain ledgers
