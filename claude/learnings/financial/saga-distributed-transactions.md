Patterns for maintaining consistency when ledger entries span multiple services, databases, or legal entities — orchestration vs choreography, compensation design, transactional outbox, and intercompany sagas.
- **Keywords:** saga, distributed transaction, orchestration, choreography, compensation, transactional outbox, CDC, idempotency key, semantic lock, intercompany, two-phase, Temporal, Spring @Transactional, PostgreSQL
- **Related:** ~/.claude/learnings/resilience-patterns.md, ~/.claude/learnings/postgresql-query-patterns.md

---

## When to Use a Saga (Decision Matrix)

| Scenario | Pattern |
|----------|---------|
| Entry + balance update in same DB | Local ACID transaction — no saga |
| Entry + event publication | Transactional outbox — no saga needed |
| Entry + external API call | Saga (orchestration) |
| Multi-entity or multi-shard transfer | Saga (orchestration) + intercompany recon |
| Multi-step approval with human gates | Saga or hand-rolled state machine |
| High-volume notification fan-out | Choreography (no compensation needed) |
| Customer-to-customer transfer (same DB) | Local ACID — both accounts in one transaction |
| Customer-to-customer transfer (sharded) | Saga — can't span DB shards in one transaction |

**Default posture**: keep as much as possible in a single DB transaction. Introduce sagas only when you cross a service, DB, or vendor boundary where both sides must eventually succeed or both must compensate.

## Orchestration vs Choreography

**Orchestration** (default for financial flows): a central coordinator manages the lifecycle — tells each participant what to do, tracks progress, triggers compensations on failure.

```
          Saga Orchestrator
         /       |        \
        v        v         v
   Ledger Svc  Payment Svc  Risk Svc
```

Use orchestration when: you need an audit trail of the decision path, flow has conditional branches (risk checks, compliance gates), or timeouts must be centrally owned.

**Choreography** (notifications, analytics): each service publishes events; downstream services react. Suitable when eventual consistency without compensation is acceptable — no compensation logic means no central coordinator is needed.

## Compensation Design Rules

In a ledger, undo = **new reversal entries**, not mutation of existing records. Compensations are forward-moving actions that counterbalance previous steps.

| Forward Action | Compensating Action |
|---------------|-------------------|
| Debit account (PENDING_OUT) | Credit account (reversal entry, `state: REVERSED`) |
| Reserve funds (hold) | Release hold (new entry) |
| Credit counterparty | Debit counterparty (clawback — may need separate approval) |
| Initiate external transfer | Cancel if pending; else initiate return |

**Five rules:**
1. **Register compensation before executing the forward step** — if the process crashes between forward success and compensation registration, rollback capability is lost.
2. **Execute compensations in reverse order** — undo most recent step first.
3. **Compensations must be idempotent** — use the original idempotency key with a `-reversal` suffix.
4. **Compensations must be retryable indefinitely** — they're the safety net; a failed compensation is worse than a failed forward step.
5. **Use a disconnected context for compensations** — if the saga is being cancelled, the compensation must run on a context not tied to the cancelled workflow (e.g., Temporal's `NewDisconnectedContext`).

## Transactional Outbox Pattern

Solves the dual-write problem: writing to the DB and publishing an event/calling an API are two separate systems — a partial failure leaves them inconsistent.

```
BEGIN TRANSACTION
  INSERT INTO ledger_entries (...)   -- the actual entry
  INSERT INTO outbox_events (...)    -- the message to publish
COMMIT

-- Separate async process:
-- Poll outbox_events (or use CDC) to publish to broker
-- Mark as published after confirmed delivery
```

Both writes are in the same ACID transaction — either both persist or neither does. The publisher is idempotent; if it crashes after publishing but before marking, it re-publishes (downstream consumers must also be idempotent).

**CDC vs polling:**
- **Polling**: simple, no extra infrastructure. Start here.
- **CDC (Debezium)**: near-real-time, no polling overhead. Migrate when sub-second propagation or polling load becomes a concern.

## Idempotency Key Strategy for Saga Steps

Derive each step's key from the saga key + step identifier:

```
Saga key:            "transfer-{customer_id}-{request_id}"
Step 1 key:          "transfer-{customer_id}-{request_id}-ledger-debit"
Step 2 key:          "transfer-{customer_id}-{request_id}-ledger-credit"
Compensation 1 key:  "transfer-{customer_id}-{request_id}-ledger-debit-reversal"
```

At the ledger layer, use `ON CONFLICT (idempotency_key) DO NOTHING RETURNING id`. If `affected_rows = 0`, the entry already exists — return existing ID without error. This makes the ledger step naturally idempotent without a pre-check.

## Saga State Machine

Each saga execution is a persistent state machine:

```
STARTED → STEP_N_EXECUTING → STEP_N_COMPLETED → ... → COMPLETED
                  |
                  v
           STEP_N_FAILED → COMPENSATING → COMPENSATED
                                        → COMPENSATION_FAILED (alert ops)
```

### Hand-Rolled Saga Table (PostgreSQL)

```sql
CREATE TABLE saga_executions (
  id                       UUID PRIMARY KEY,
  saga_type                VARCHAR NOT NULL,       -- e.g. 'DEPOSIT', 'FX_CONVERSION'
  state                    VARCHAR NOT NULL,       -- e.g. 'STEP_2_EXECUTING'
  payload                  JSONB NOT NULL,         -- saga input parameters
  compensations_registered JSONB,                 -- ordered compensation actions
  started_at               TIMESTAMP NOT NULL,
  updated_at               TIMESTAMP NOT NULL,
  completed_at             TIMESTAMP,
  error_details            JSONB,
  idempotency_key          VARCHAR UNIQUE NOT NULL
);
```

A background job scans for stuck sagas (`state != 'COMPLETED' AND updated_at < NOW() - interval`) and triggers compensation.

### Workflow Engine vs Hand-Rolled

- **Hand-rolled**: appropriate for simple flows (2–3 steps, no conditional branching). Lower operational overhead.
- **Workflow engine** (Temporal, Restate, Step Functions): pays for itself at 5+ steps, conditional branches, or timeout handling. Provides state persistence, automatic retry, compensation orchestration, and a visibility dashboard.

## Failure Taxonomy

| Failure | Recovery | Saga Response |
|---------|----------|--------------|
| Transient (network timeout, 503) | Retry with backoff | Retry current step |
| Business rejection (insufficient funds) | No retry | Compensate completed steps |
| Infrastructure failure (DB down) | Wait and retry | Saga pauses; resume on recovery |
| Poison pill (always-invalid data) | Skip + alert | Dead-letter after max retries |
| Partial success (vendor accepted, DB crashed) | Reconciliation | Saga state unknown — recon resolves |
| Compensation failure | Retry indefinitely; alert if stuck | Enter `COMPENSATION_FAILED`; human must intervene |

**Compensation-failure design principle**: make compensations as simple as possible. Prefer compensations that only write to the local database (always succeeds) over ones that also call an external API. Decouple: write the reversal entry locally, then have a separate process handle external cancellation.

## Pending State as Semantic Lock

During saga execution, intermediate states are visible to other transactions. Mitigate with:

1. **Pending state entries**: use `PENDING_OUT` on the debit. Balance composition queries exclude pending entries from `available_to_use` but include them in `pending_outgoing` — the customer sees "funds in transit," not a mysterious deduction. (Balance composition is in `domain-ledger-architecture.md`.)
2. **Commutative entry design**: append-only entries naturally commute — each independently adds/subtracts, so ordering doesn't affect the final balance.
3. **Semantic lock column** (high-contention accounts): add `locked_by_saga_id` to the balance row. Other sagas check for an active lock and either queue or fail fast.

## Intercompany Saga Patterns

When a saga spans two entities' ledgers, each step commits independently into each entity's database — no single ACID transaction spans both.

**Intercompany timing gap**: Entity A's steps and Entity B's steps create a natural mismatch window (seconds to minutes). Reconciliation must tolerate this window without alerting. See `domain-ledger-architecture.md` for the intercompany account structure.

**Cross-entity double-entry**: each entity maintains its own balanced double-entry. The intercompany accounts (`payable_to_B` in Entity A, `receivable_from_A` in Entity B) create a "virtual" balance across entities — must net to zero after settlement. The saga doesn't enforce this in real-time; reconciliation verifies it after the fact.

**Step ordering for multi-entity FX saga:**
```
Step 1: [Entity A] Debit customer sell-currency account
Step 2: [Entity A] Credit platform FX revenue (spread)
Step 3: [Entity B] Debit platform buffer buy-currency
Step 4: [Entity B] Credit customer buy-currency account
Step 5: [Entity A] Record intercompany payable
        [Entity B] Record intercompany receivable
```
If Step 3 fails after Steps 1–2 committed, the saga must compensate Steps 2 → 1 in reverse order.

## Saga Hygiene

- **Audit every saga step**: log saga ID, step name, idempotency key, and result for every step and compensation. This is the distributed audit trail.
- **Keep sagas short**: target < 10 steps. 15+ steps signals an opportunity to batch or collapse.
- **Test compensation paths**: compensation code runs rarely in production but is critical when it does — inject failures in tests to exercise every branch.
- **Monitor stuck sagas**: alert on sagas in `COMPENSATING` state beyond a threshold. These represent money in a potentially inconsistent state.
- **Separate step timeouts from saga timeouts**: a step may timeout at 30s (retry the step); the saga may timeout at 5 business days (trigger full compensation).

## Spring / JPA Notes

- **Transaction boundary**: each saga step should run in its own `@Transactional` method. Don't wrap the entire saga in one transaction — that defeats the point and holds locks across external API calls.
- **Compensation context**: use `Propagation.REQUIRES_NEW` for compensation methods so they commit independently even if called from a failed outer transaction context.
- **Outbox publishing**: write outbox rows in the same `@Transactional` block as the ledger entry. The outbox publisher runs in a separate `@Scheduled` method with its own transaction.
- **Saga state updates**: use optimistic locking (`@Version`) on the `saga_executions` row to prevent concurrent updates if two threads race on the same saga.

## Cross-Refs

- `~/.claude/learnings/resilience-patterns.md` — scheduler-decoupled maker/checker (complements saga step decoupling), domain-typed exceptions for integration failures
- `~/.claude/learnings/postgresql-query-patterns.md` — migration safety and locking patterns relevant to adding saga_executions table to an existing schema
