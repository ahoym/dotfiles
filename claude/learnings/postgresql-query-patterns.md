Staged entries for enrichment of ~/.claude/learnings/postgresql-query-patterns.md

---

### Zero-downtime unique index replacement: add CONCURRENTLY first, drop old constraint later

When replacing a unique constraint or index (e.g., adding a column to a composite unique index), use two deployments: (1) create the new unique index with `CREATE UNIQUE INDEX CONCURRENTLY` — the `CONCURRENTLY` keyword prevents table locking during index build; (2) drop the old constraint in a future MR after all instances are running the updated code. Verify there are no pre-existing violations before creating the new index, or the build will fail. Running both steps in a single migration creates a gap where the old constraint is gone before application code has switched over. This is the database equivalent of expand-and-contract.

Note: `CREATE INDEX CONCURRENTLY` cannot run inside a transaction — if using Flyway (which wraps migrations in transactions by default), use a non-transactional migration or a Flyway callback.
