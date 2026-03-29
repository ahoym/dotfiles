Event sourcing and CQRS patterns for financial ledger systems — event store design, CQRS separation, snapshot strategies, projection rebuilds, schema evolution, and how ES layers onto the three-table schema.
- **Keywords:** event sourcing, CQRS, event store, projection, snapshot, schema evolution, upcasting, global_position, correlation_id, causation_id, read-your-own-writes, blue-green rebuild, Axon, Spring @TransactionalEventListener, JPA @Immutable, PostgreSQL
- **Related:** ~/.claude/learnings/resilience-patterns.md, ~/.claude/learnings/postgresql-query-patterns.md, ~/.claude/learnings/java/spring-boot.md

---

## Ledger-ES Natural Fit

Ledger entries are already an append-only event log — event sourcing formalizes what ledgers do naturally:

- Entries (immutable) = domain events (immutable)
- Reversal entries (never UPDATE) = compensating events (never mutate)
- Balance at any date = replay entries to that point

**Key distinction (Oskar Dudycz)**: event stores record the *decision model* (why: `DepositRequested`, `RiskApproved`); ledger tables record *outcomes* (debit/credit entry pairs). Both are append-only and immutable, but serve different roles — don't conflate them.

## When to Add ES vs. Stay With Three Tables

**Three tables are sufficient when**: single-service ledger with local ACID transactions; `source_type`/`source_id` on entries already links to domain tables for audit; no regulatory requirement to reconstruct pre-entry decision history.

**ES adds value when**:
- Regulatory audit requires reconstructing decision chain (risk checks, approvals), not just outcomes
- Temporal queries: "what was this account's state at 3:47 PM on March 15?"
- Multi-service coordination: domain events drive saga orchestration
- Dispute resolution: need the exact sequence of decisions that led to a charge
- Projection diversity: 5+ different read models from the same data (risk dashboard, compliance reports, GL queue)

**Default recommendation**: start with three tables. Add ES when a specific need arises. Entries are already events — adding a formal event store is additive, not a rewrite.

## Hybrid Architecture (Most Common in Production)

Keep three-table schema as the transactional core. Add event sourcing at the boundary:

```
Event Store (optional layer)
  DepositRequested → RiskApproved → ACHInitiated → DepositSettled
         |
         | event handlers write entries
         v
Three-Table Ledger (always present)
  accounts | entries (SoR) | balances (cache/synchronous projection)
         |
         | events also drive
         v
Async Projections (dashboards, compliance, GL)
```

1. Domain events written to event store or outbox at the service boundary
2. Ledger service handles events → creates entries + updates balances in a single ACID transaction
3. Secondary read models (dashboards, reports) built from event stream, not ledger queries

## Event Store Schema

```sql
CREATE TABLE domain_events (
    event_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stream_id       TEXT NOT NULL,         -- aggregate ID (e.g., account_id, transfer_id)
    stream_type     TEXT NOT NULL,         -- aggregate type (e.g., 'Account', 'Transfer')
    event_type      TEXT NOT NULL,         -- e.g., 'DepositRequested', 'BalanceDebited'
    event_data      JSONB NOT NULL,
    event_metadata  JSONB,                 -- correlation_id, causation_id, user_id, ip
    version         BIGINT NOT NULL,       -- per-stream sequence number
    global_position BIGSERIAL,            -- global ordering across all streams
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (stream_id, version)            -- optimistic concurrency control
);
CREATE INDEX idx_events_stream ON domain_events (stream_id, version);
CREATE INDEX idx_events_global ON domain_events (global_position);
```

Key decisions:
- `stream_id + version` unique constraint: two concurrent writes with same expected version → one fails, retry. Same pattern as balance row versioning.
- `global_position`: monotonically increasing across all streams. Essential for projections needing total ordering.
- `correlation_id / causation_id` in metadata: mandatory. Correlation = originating request. Causation = direct parent event. Without these, debugging distributed financial flows is nearly impossible.
- No `aggregate_state` column in the event table — state is always derived from events.

## Stream Design for Ledgers

| Stream type | Stream ID pattern | Typical events |
|-------------|-------------------|----------------|
| Account | `account-{id}` | AccountOpened, BalanceDebited, BalanceCredited, AccountFrozen |
| Transfer | `transfer-{id}` | TransferInitiated, DebitPosted, CreditPosted, TransferCompleted |
| Deposit | `deposit-{id}` | DepositRequested, RiskChecked, EarlyAccessGranted, ACHSettled, ACHReturned |
| Withdrawal | `withdrawal-{id}` | WithdrawalRequested, FundsReserved, WireSent, WithdrawalCompleted |

**Design tension**: account-centric streams grow unboundedly (years of transactions). Transfer/deposit/withdrawal streams are naturally bounded. Use "closing the books" (see Snapshots) rather than snapshots for account streams.

## Event Store Technology Options

| Technology | Best for ledgers | Considerations |
|------------|-----------------|----------------|
| PostgreSQL (as event store) | Same DB as ledger — event + entry write in one ACID tx | Single-node write ceiling; custom projection infrastructure |
| EventStoreDB | Purpose-built; native subscriptions; ~15K writes/sec | Separate infra; no same-tx guarantee with ledger entries |
| Kafka | High throughput (100K+ writes/sec); partition-per-account | Per-partition ordering only; no aggregate versioning; operational cost |

**PostgreSQL as event store** is the most common choice for custom fintech ledgers because it enables the transactional outbox pattern: write event to outbox alongside entry in the same transaction — no dual-write problem.

## CQRS Separation

### Write Side

Enforce all invariants on the write path (unchanged from three-table pattern):
- Double-entry constraint: `SUM(debits) = SUM(credits)` per transaction
- Balance sufficiency: `available >= 0` after debit
- Idempotency: check `idempotency_key` before creating entries
- Optimistic concurrency: version check on balance update

### Read Side — Projection Examples

| Projection | Source events | Consumer |
|-----------|--------------|----------|
| Customer balance | BalanceDebited, BalanceCredited | Customer-facing API |
| Transaction history | TransferCompleted, DepositSettled | Customer-facing UI |
| Risk dashboard | DepositRequested, EarlyAccessGranted, ACHReturned | Risk team |
| Compliance report | All events with user context | Compliance/regulatory |
| GL posting queue | PeriodClosed, EntryCreated | General ledger system |

### Eventual Consistency Problem

CQRS introduces read lag — a customer deposits $500, balance projection hasn't updated yet. This matters more for ledgers than social apps: stale balances can enable overdrafts, breach risk limits, trigger false reconciliation alerts.

**Mitigation strategies** (least to most complex):
1. **Read-your-own-writes**: after a write, read balance directly from the write model for the affected account only. Other users see eventually-consistent projection.
2. **Synchronous inline projection**: `ledger_balances` updated in the same transaction as the entry write. This is what the three-table pattern already does — it's a synchronous projection.
3. **Causal consistency tokens**: write returns the event's `global_position`; read waits until projection catches up to that position before responding.
4. **Hybrid** (most common): synchronous projection for balances (critical path), async for dashboards and reports (tolerate seconds of lag).

## Snapshot Strategies

### "Closing the Books" (Preferred Over Snapshots)

Close a long-lived stream and start fresh — mirrors the accounting close:

```
Stream: account-{id}-2025
  ... 3000 events ...
  Final: PeriodClosed {balances: {settled: 5000, pending: 200}, period: "2025-Q4"}

Stream: account-{id}-2026
  PeriodOpened {carry_forward: {settled: 5000}}, ...
```

Better than snapshots because: aligns with actual accounting practices; short streams avoid versioning complexity; each stream fits in memory for replay; no snapshot invalidation concerns.

### Snapshots (When Closing the Books Isn't Applicable)

**Timing strategies**:
| Strategy | When | Tradeoff |
|----------|------|----------|
| Every N events | After 100–500 events | Up to N events to replay after snapshot |
| On business event | After PeriodClosed, large batch | Aligns with business cycles |
| On-demand | When replay time exceeds threshold | Requires monitoring |

**Schema**:
```sql
CREATE TABLE aggregate_snapshots (
    stream_id      TEXT PRIMARY KEY,       -- only latest snapshot per stream
    version        BIGINT NOT NULL,
    schema_version INT NOT NULL,           -- for deserialization safety
    state_data     JSONB NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Critical gotcha**: snapshot schema coupling. When aggregate state shape changes, old snapshots become undeserializable. Always include `schema_version` and implement fallback to full event replay on deserialization failure.

**Read pattern**: load snapshot → load events since `snapshot.version` → replay on top.

## Projection Patterns

**Synchronous**: updated in the same transaction as the write. `ledger_balances` is the canonical example. No lag; adds write latency; can't scale read side independently.

**Asynchronous (materialized)**: built by background consumers. Eventual consistency (ms-to-seconds). Read side scales independently; diverse read models from same events.

**Live (on-demand)**: rebuilt from events on every query. Only practical for bounded streams. Use for debugging and temporal queries.

### Projection Rebuild (Blue-Green)

1. Create new projection table (e.g., `customer_balance_v2`)
2. Replay all events into the new table
3. Once caught up to the live stream, switch read traffic
4. Drop old table

**Requirements for safe rebuilds**:
- **Idempotent handlers**: same event applied twice = same result. Use `UPSERT` with `last_event_position`, never blind `INSERT`.
- **Checkpoint tracking**: projection tracks last processed `global_position`. On restart, resume from checkpoint.
- **Freshness monitoring**: alert when lag between latest event and latest projected event exceeds threshold.

### Projection Gotchas for Ledgers

1. **Projection lag during high-volume periods**: during flash sales or payroll processing, async projections fall behind. Balance checks for withdrawals must read from the write model, not the stale projection.
2. **Cross-stream ordering**: a transfer debits Account A and credits Account B. If projections for A and B process at different speeds, one balance updates before the other — momentary imbalance visible to monitoring. Will trigger false reconciliation alerts without tolerance windows.
3. **Idempotency is mandatory**: projections re-process events on consumer restarts, rebalancing, and rebuilds. Without idempotent handlers, balances drift.
4. **Read model ≠ snapshot**: don't use a read model as a snapshot for faster aggregate loading — it couples read and write schemas. They diverge over time.

## Multi-Entity Event Streams

For intercompany flows or multi-entity ledgers:
- Use transfer-scoped streams (`transfer-{id}`) rather than account-scoped streams to capture the full cross-entity flow in one coherent event sequence
- Cross-entity projection consistency: projections per entity may process at different speeds — design reconciliation to tolerate per-entity lag windows, not require atomic cross-entity consistency
- Integration events at entity boundaries: internal domain events shouldn't cross entity/service boundaries; map to integration events (`FundsTransferCompleted`) that hide internal domain model details

## Event Schema Evolution

Events are immutable and long-lived. Schema evolution is unavoidable.

**1. Additive-only changes (strongly preferred)**: never remove, rename, or change field types. Only add optional fields with defaults. Old consumers ignore unknown fields; no versioning infrastructure needed.

**2. Upcasting (read-time transformation)**: transform events from old to new schema during deserialization; original bytes unchanged in storage. Chain composes across versions (V1→V2→V3). **Gotcha**: upcaster chain grows over time — test all historical versions in CI.

**3. New event type**: when semantics change fundamentally (not just fields), create a new event type rather than versioning.

**4. Copy-and-transform (nuclear option)**: migrate the entire event store. Use only when: upcaster chain becomes prohibitively expensive; GDPR data deletion is required; fundamental store technology change.

### Schema Registry (At Scale)

Define event schemas (JSON Schema, Avro, or Protobuf). Validate compatibility as a CI gate. **For ledgers**: BACKWARD compatibility is the minimum — you must always be able to replay historical events. FULL compatibility (read old and new in both directions) is the target.

### Financial-Specific Schema Concerns

- **Amount field precision**: never change integer↔float. Add a new field if a new precision representation is needed.
- **Currency representation**: once established (ISO 4217 codes vs numeric codes), don't change.
- **Idempotency key format**: if key generation algorithm changes, old and new keys must be distinguishable. Include a version prefix or namespace.

## Anti-Patterns

**Property sourcing**: `BalanceUpdated {field: "settled", value: 5000}` is no better than a change log — loses business intent. Use `DepositSettled {deposit_id, amount, new_settled_balance}`.

**Fat events**: including full aggregate state in every event defeats the purpose (events become snapshots) and creates coupling. Events should contain the delta.

**Internal events as integration events**: domain model events (`BalanceDebited`) leak internal details. Map to integration events (`FundsTransferCompleted`) at the service boundary.

**Event store as message bus**: don't have external services poll the event store directly. Publish integration events to a message bus (Kafka, SQS); the event store retains domain events.

**Skipping correlation/causation IDs**: without these, tracing a distributed financial flow ("customer says $500 is missing") is nearly impossible.

**Premature event sourcing**: not every part of a fintech system needs ES. Customer profile management, notification preferences, UI settings — these are CRUD. Apply ES to the financial core (ledger, payments, transfers) and leave the rest as standard application state.

## Java/Spring Specifics

**Axon Framework**: full ES+CQRS framework for Java. Manages event store, aggregate loading, projection subscriptions, and upcaster registration. Significant investment to adopt but provides the full pattern out of the box. Best fit when the team is already event-sourcing the whole domain.

**Spring Events (lightweight CQRS)**: `ApplicationEventPublisher` + `@EventListener` / `@TransactionalEventListener` for in-process CQRS without a full event store. `@TransactionalEventListener(phase = AFTER_COMMIT)` publishes after the write transaction commits — prevents phantom events on rollback. Suitable for single-service CQRS where full ES isn't required.

**PostgreSQL LISTEN/NOTIFY for projections**: use `pg_notify` from a trigger or the application after committing a write; projection consumers listen via `LISTEN channel` and update read models. Provides near-synchronous async projection without Kafka. Works well when the event store is already PostgreSQL and projection consumers are in the same environment.

**JPA event store entity design**:
```java
@Entity @Table(name = "domain_events")
@Immutable  // Hibernate hint: never dirty-check or flush updates
public class DomainEventEntity {
    @Id UUID eventId;
    String streamId;
    String eventType;
    @Type(JsonType.class) Map<String, Object> eventData;
    @Type(JsonType.class) Map<String, Object> eventMetadata;
    Long version;
    Long globalPosition;
    Instant createdAt;
}
```
Use `@Immutable` to prevent Hibernate from ever attempting an UPDATE on event rows.

## Production Readiness Checklist

- [ ] Event schema registry with version tracking and CI compatibility gate
- [ ] Upcasters registered and tested for all historical event versions
- [ ] Snapshot or "closing the books" strategy defined, with `schema_version` and retention
- [ ] Projection rebuild tested without downtime (blue-green)
- [ ] All projection handlers idempotent with `last_event_position` dedup
- [ ] Correlation and causation IDs on every event
- [ ] Read-your-own-writes or synchronous projection for balance-critical paths
- [ ] Monitoring: event append latency, projection lag, disk usage
- [ ] GDPR compliance: crypto-shredding strategy for PII in events
- [ ] Reconciliation between event-derived state and materialized balances
- [ ] Event store backup and point-in-time recovery tested

## Cross-Refs

- `~/.claude/learnings/resilience-patterns.md` — idempotent processing and dedup-before-process patterns that apply to projection handlers and event consumers
- `~/.claude/learnings/postgresql-query-patterns.md` — JSONB indexing, optimistic locking, and schema migration patterns for event store tables
- `~/.claude/learnings/java/spring-boot.md` — Spring transactional event listener patterns, Spring Data JPA with immutable entities
