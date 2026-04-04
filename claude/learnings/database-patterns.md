Staged entries for enrichment of ~/.claude/learnings/database-patterns.md

---

### Partial-unique index for nullable columns in PostgreSQL

`CREATE UNIQUE INDEX idx_name ON table(column) WHERE column IS NOT NULL` enforces uniqueness on non-null values while allowing multiple NULLs -- standard SQL says NULL != NULL, but not all databases handle this consistently in unique constraints. The partial index approach is explicit and portable across PostgreSQL versions. Useful for optional external IDs, email fields, or any column where "no value" is valid but duplicate real values are not.

### PostgreSQL views cannot reorder columns in-place

`CREATE OR REPLACE VIEW` can add new columns at the end but cannot reorder existing columns or change their types. Attempting to reorder columns requires `DROP VIEW` + `CREATE VIEW`, which breaks dependent objects. This matters for Flyway repeatable migrations (`R__create_view.sql`) -- if a column order change sneaks in, the migration fails silently or errors depending on the change. New columns must always be appended at the end of the SELECT list.
