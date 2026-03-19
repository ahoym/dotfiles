# Local Dev Environment Seeding

## Hybrid API + SQL Seeding Architecture

When a service receives data from both its own API and external systems (custody callbacks, scheduled tasks, compliance webhooks), local seeding needs two layers:

- **API layer**: Newman/Postman or curl for entities the app creates (customers, partners, wallets, collections). Validates the API actually works.
- **SQL layer**: Direct inserts for entities from external systems (raw transactions, settlements, screening results, custody accounts without endpoints).

**Bridge pattern**: API layer exports a JSON manifest of created IDs (e.g., Newman `--export-environment`). SQL layer uses `envsubst` to render a templated `.sql.template` file with those IDs before executing via `psql`.

```
Newman API seeding → .local-seeded.json (manifest)
                          ↓
              jq extract → export as env vars
                          ↓
              envsubst < seed_data.sql.template → rendered SQL
                          ↓
              psql execution
```

**SQL template uses `ON CONFLICT (id) DO NOTHING`** for idempotent re-runs.

## Schema Drift Detection

For projects with SQL seed files, detect when Flyway migrations have changed the schema and seed data may be stale:

1. Commit a `current_schema_dump.sql` baseline (from `pg_dump --schema-only -n <schema>`)
2. On seed, diff live schema against baseline
3. If drift detected: update seed template + regenerate baseline

Static validation of rendered SQL (check FK references, column counts, enum values) catches issues before `psql` execution. **Validate the rendered output, not the template** — templates contain `${VAR}` placeholders that false-positive on "unreplaced variable" checks.

## Deterministic Seed UUIDs

Use a recognizable UUID pattern for seed data (e.g., `00000000-0000-4000-XXXX-00000000000Y` with section-specific `XXXX` values). Dual purpose:
- **Identification**: easy to spot seed data in queries (`WHERE id LIKE '00000000-0000-4000-%'`)
- **Idempotency**: `ON CONFLICT (id) DO NOTHING` works reliably. Using `uuid_generate_v4()` with bare `ON CONFLICT DO NOTHING` can fail if no matching constraint exists — always specify the conflict target column.

## Seed External-System State to Bypass Dependencies

When the app depends on external systems for state transitions (e.g., compliance screening → partner activation), seed that state directly via SQL so the local env doesn't need the external system running:

```sql
-- Insert screening result as RELEASE
INSERT INTO compliance_screening (..., status, ...) VALUES (..., 'RELEASE', ...);
-- Update the entity to reference the screening
UPDATE partners SET screening_id = '<screening-uuid>' WHERE id = '<partner-id>';
```

This eliminates async wait times (e.g., polling for compliance approval) and removes external service dependencies from local development.

## See also

- `newman-postman.md` — Newman runtime gotchas (skipRequest sync-only, conditional assertions, export-environment manifest)

