Vercel platform constraints: cron limits, Postgres (Neon) driver behavior, and serverless gotchas.
- **Keywords:** Vercel, cron, Neon, @vercel/postgres, POSTGRES_URL, IS NOT DISTINCT FROM, nullable, serverless
- **Related:** typescript-ci-gotchas.md, xrpl-patterns.md

---

## Cron job frequency limits

Vercel cron jobs floor at **1/day on Hobby** (free) and **1/min on Pro** ($20/mo). Sub-minute scheduling is not possible with Vercel crons — requires an always-on external process (e.g., ECS Fargate, Railway, Fly.io).

## Vercel Postgres (@vercel/postgres)

- Uses Neon's **HTTP-based query driver** — no persistent connections, no pool configuration needed. Each `sql` call is an independent HTTP request. Safe for serverless concurrency.
- Reads `POSTGRES_URL` from env automatically (auto-populated when you link a Vercel Postgres database).
- Use `POSTGRES_URL_NON_POOLING` for DDL/migrations (Neon requires non-pooled connections for schema changes).
- `IS NOT DISTINCT FROM` is required for nullable column comparisons in WHERE clauses. Standard `=` fails because `NULL = NULL` evaluates to false in SQL — queries filtering on nullable columns (e.g., XRP pairs where issuer is NULL) will silently return no results.
- The `sql` tagged template passes strings to Postgres NUMERIC columns correctly — no need for `parseFloat()` which would lose precision on financial data.

## Cross-Refs

- `typescript-ci-gotchas.md` — Vercel serverless cold start and lockfile gotchas
- `xrpl-patterns.md` — Vercel serverless WebSocket connection management for XRPL apps
