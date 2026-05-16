Greenfield schema design — when to promote vs defer entities, sidecar vs extension tradeoffs at v0.
**Keywords:** schema, entity, promote, defer, greenfield, v0, migration, sidecar, consumer-count, table
**Related:** ~/.claude/learnings/postgresql-query-patterns.md

# Greenfield Schema Design — When to Promote, When to Defer

## First-class entities vs sidecars at v0 scale

"Fewer tables at v0 scale" is a defensible argument for **sidecars without other consumers** (e.g., a 1:0..1 child for nullable extension fields). It is **not** a defensible argument for promoting entities that have multiple consumers from day one.

**Rule:** a candidate entity earns its own table at v0 when it has ≥2 consumers, OR when the migration cost of promoting it later requires deduping rows / rewriting working code / migrating snapshots. Examples that meet the bar:

- `wallet` / `bank_account` in a settlement system — consumed by sighting, payment, KYC, custody ops, internal rebalancing graphs
- `customer` separated from `customer_kyc` — consumed by ledger, payment, compliance independently

**Why deferring is expensive:** at v1+ you back-fill from the denormalized source (e.g., dedupe wallet rows from N SSIs that reference the same address), rewrite resolution logic to read from joined tables, migrate snapshot references, and regression-test working code. The "v0 scale" framing optimizes for current row count; the migration cost scales with the *consumer count* and *historical-data weight* — both of which only grow.

**Cost of doing it at v0:** one extra `CREATE TABLE` per entity in the same Flyway file. Trivial relative to the v1 migration.

## When to defer (sidecars are fine)

- Single-consumer extension fields → keep nullable on the parent table or in a 1:0..1 sidecar
- Speculative features ("we might want X") → defer; nullable columns or no columns until the use case lands
- Tables that exist *only* to participate in an ENUM hierarchy with no other reads → keep flat

## Practical test before promoting

Count how many places in the proposed v0 codebase will read from the candidate entity. If only the parent-aggregate code reads it, sidecar or stay flat. If sighting reads it, payment reads it, and KYC reads it, promote.

## Cross-Refs

- `~/.claude/learnings/postgresql-query-patterns.md` → schema migration safety
