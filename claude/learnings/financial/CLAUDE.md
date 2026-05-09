Financial and ledger engineering: monetary calculations, ledger architecture, pricing, sagas, event sourcing, and accounting patterns.

| File | When to read |
|------|-------------|
| domain-ledger-architecture.md | Core ledger patterns: three-table schema, balance composition, entry lifecycle |
| applications.md | Monetary calculation safety, error handling |
| numeric-precision-strategy.md | Cross-layer precision: DB NUMERIC, wire strings, BigDecimal/BigNumber.js, crypto decimals, sizing rationale |
| order-book-pricing.md | Mid-price approaches, slippage calculation, spread |
| saga-distributed-transactions.md | Saga patterns: orchestration vs choreography, compensation, transactional outbox |
| ledger-testing-strategies.md | Accounting invariants, property-based testing, reconciliation harnesses |
| chart-of-accounts.md | Hierarchy design, GL integration, account lifecycle, multi-entity |
| period-end-closing.md | Soft/hard close, snapshots, balance carry-forward |
| ledger-schema-migration.md | Balance-first to entry-first, dual-write, zero-downtime cutover |
| event-sourcing-cqrs.md | Event store design, projections, schema evolution, snapshots |
| futures-etf-translation.md | Leveraged ETF → micro futures: ticker mapping, P/L translation, discrete sizing, DCA mechanics |
| futures-order-type-restrictions.md | Per-contract MKT-order rules (VIX-family rejects MKT on Cboe) + wide-crossing-LMT mitigation pattern |
| futures-tick-rounding.md | Per-contract tick grid (MNQ=0.25, VX/VXM=0.05) — `round(price, 2)` rejects on Cboe; snap with `round(round(p/tick)*tick, 4)` |
| market-calendars.md | Market-calendar library selection — disentangle from DataFrame library choice (NYSE holidays, futures roll math) |
| scheduling-time-windows.md | Runtime gates from time windows: cross-midnight wrap, weekday/market-aware open-days, derive-from-window sleep cadence |
