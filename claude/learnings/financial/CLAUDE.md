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
