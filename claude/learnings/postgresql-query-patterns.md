# PostgreSQL Query Patterns

## Window Functions

- Use `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` for "latest per group" queries — more efficient than correlated subqueries.
- `LAG()`/`LEAD()` for comparing consecutive rows (e.g., detecting status transitions, calculating deltas).
- `SUM() OVER (ORDER BY ... ROWS UNBOUNDED PRECEDING)` for running totals — useful in financial reconciliation.
- Window functions execute after WHERE/GROUP BY — filter first, window second. Use a CTE or subquery if you need to filter on window results.

## CTEs (Common Table Expressions)

- Use CTEs for readability when a query has 3+ logical steps. Postgres materializes CTEs by default before v12; from v12+ the optimizer can inline them.
- `WITH RECURSIVE` for tree/graph traversal (org hierarchies, category trees). Always include a termination condition.
- Writable CTEs (`WITH ... AS (UPDATE ... RETURNING *)`) are useful for atomic read-modify-write patterns.
- Don't nest CTEs when a simple JOIN would do — CTEs add readability but can hurt performance if they prevent predicate pushdown (pre-v12 or when `MATERIALIZED` is forced).

## JSONB Operations

- `jsonb_path_query()` (SQL/JSON path) is more readable than chained `->` operators for deep nested access.
- Index strategies:
  - `GIN` index on the whole column for general `@>` containment queries.
  - Expression index on a specific path (`CREATE INDEX ON t ((data->>'key'))`) when queries always target the same field.
- `jsonb_agg()` / `jsonb_object_agg()` for building JSON in queries — avoids N+1 when materializing nested API responses.
- Don't store data in JSONB that you'll need to JOIN on or enforce FK constraints for. JSONB is for semi-structured/optional data, not core relational fields.

## Partial Indexes

- `CREATE INDEX ... WHERE condition` — dramatically smaller and faster when queries consistently filter on the same condition.
- Common use cases: `WHERE status = 'ACTIVE'`, `WHERE deleted_at IS NULL`, `WHERE type = 'DEPOSIT'`.
- The query's WHERE clause must match (or imply) the index condition for the planner to use it.
- Combine with covering indexes (`INCLUDE (col)`) for index-only scans on filtered subsets.

## Indexing Strategy

- Index columns used in WHERE, JOIN ON, and ORDER BY — in that priority order.
- Composite indexes: put equality columns first, range columns last (`(status, created_at)` not `(created_at, status)`).
- `CONCURRENTLY` for production index creation — avoids table locks but takes longer and can't run inside a transaction.
- Monitor with `pg_stat_user_indexes` — drop indexes with zero scans after a full business cycle.
- Avoid indexing low-cardinality boolean columns unless combined with other columns in a composite or partial index.

## Partitioning

- Consider range partitioning on time columns when tables exceed ~100M rows or when you need efficient bulk deletion (drop partition vs DELETE).
- Partition key must be part of the primary key and any unique constraints.
- Query planner only prunes partitions when the partition key appears in the WHERE clause — always include it.
- Start with monthly partitions, adjust based on query patterns and data volume.

## Schema Design Patterns

- **Composite PK indexing:** B-tree on `(a, b)` supports lookups by `a` (leading column) but NOT `b` alone. A separate index on `b` is needed for direct lookups. An index on `a` alone is redundant.
- **Boolean column indexes:** Justified when data skew is heavy (e.g., 99% FALSE, 1% TRUE) and queries filter on the minority value.
- **Junction tables:** Default to including `updated_at` — zero cost now, avoids a future migration.
- **FK references over plain strings:** When a column stores a value from another table, use a FK constraint. FK target changes need pre-validation of data integrity.
- **Column naming:** Should match the referenced entity (`currency` not `asset` when FK now targets `currencies`). Rename when FK targets change.
- **Redundant view columns:** When a view joins tables with identical column values, include only one. Design views around filtering purpose.

## Migration Safety Patterns

- **Schema + dependent data = one migration:** When seed data doesn't fit existing constraints, alter the schema and insert in a single migration for atomicity.
- **NOT NULL constraints:** Before `SET NOT NULL`, verify the backfill UPDATE has no WHERE clause gaps. Two-step for populated tables (add nullable → backfill → constrain); single step for empty tables with documented assumption.
- **Validate constraints with SQL tests:** Demonstrate correctness with concrete SQL — happy path, unhappy path, edge cases.
- **Verify environment state before data-state claims:** When justifying decisions based on "no data exists," specify which table and which environment.

## See also

- `spring-boot.md` — Flyway migration safety patterns overlap with migration safety above
- `financial-applications.md` — DECIMAL precision patterns for financial column design
