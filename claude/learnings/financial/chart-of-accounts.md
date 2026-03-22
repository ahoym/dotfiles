Chart of accounts design patterns — hierarchy structures, GL integration, account numbering, templates, lifecycle states, multi-entity CoA, and reporting hierarchies.
- **Keywords:** chart of accounts, CoA, GL integration, account hierarchy, ltree, materialized path, account lifecycle, account template, multi-entity, intercompany, hub-and-spoke, reporting hierarchy, JPA, PostgreSQL
- **Related:** ~/.claude/learnings/postgresql-query-patterns.md, ~/.claude/learnings/java/spring-boot.md

---

## Flat vs Hierarchical: Choose by Use Case

**Flat** (TigerBeetle, Fragment path-keys): optimized for throughput, no query-time tree traversal. Classification via separate type/code fields. Hierarchy is a reporting concern, not a storage concern. Use when account population is large (millions) or a separate OLAP layer handles reporting.

**Hierarchical** (colon-segments like `assets:bank:main`, parent-child trees): enables aggregate queries at any tree level. Use for GL/ERP integration, regulatory reporting, and systems where intermediate-level roll-ups are frequently queried.

**Hybrid (dominant production pattern)**: flat subledger for transaction processing + separate reporting layer (materialized views, OLAP, reporting DB) for hierarchy. Each layer optimizes for its primary concern. Modern Treasury "ledger account categories" exemplify this — hierarchy doesn't affect transaction processing.

## Account Numbering: Prefer UUID-Internal + Code-Mapping

Segment-encoded numbers (`1000-10-001`) are human-readable but cause namespace exhaustion, rigid evolution, and segment-meaning drift.

Recommended: internal UUID + external human-readable code in a mapping table with effective dates. The subledger never parses the code — it's a presentation-layer concern. Allows reclassification without touching transaction records.

## GL Integration: Separate Subledger from GL

The systems have incompatible requirements:

| Concern | Subledger | GL |
|---------|-----------|-----|
| Priority | Throughput, latency | Accuracy, auditability |
| Granularity | Per-transaction | Aggregated |
| Account count | Millions | Hundreds |
| Period close | Not applicable | Required |

Keep them separate. The subledger should not know GL codes. The GL should not know individual customer accounts.

**Pattern 1 — Account Type Mapping Table**: each subledger account type maps to a GL code. Simple, works for early-stage products.

**Pattern 2 — Rule-Based Mapping Engine**: transaction attributes (type, currency, entity) determine GL mapping. Handles multi-entity, multi-currency; high testing burden.

**Pattern 3 — Event-Driven GL Posting (recommended)**: subledger emits domain events (`PaymentSettled`, `FeeCharged`). A separate GL posting service subscribes, aggregates, and writes to the GL. Clean separation; GL posting can batch daily instead of per-transaction; multiple GL targets subscribe with different mappings.

**GL system impedance**: QuickBooks, Xero, and NetSuite have fixed account type taxonomies. Your richer internal model won't map 1:1 — the mapping layer absorbs this mismatch by design. Rate/batch limits in QBO and Xero make real-time reconciliation impractical; design for daily or hourly cycles.

## GL Reconciliation Pattern

1. Sum subledger balances grouped by GL mapping code → expected GL balances
2. Pull actual GL balances via GL system API
3. Diff → find reconciliation breaks
4. Investigate: timing differences, mapping errors, manual GL entries

Make this a scheduled job (daily or hourly), not a real-time check.

## Account Templates and Versioning

Create per-customer account sets from versioned templates. Each template defines which accounts to instantiate (suffix, type, GL code) at entity onboarding. Track `template_version` on each account instance — when a template gains a new account type, you can identify which existing customers need backfill.

Per-product variation: customers with multiple products (payments, lending) get separate template instantiations per product (`customer-id/payments/balance`, `customer-id/lending/principal`).

## Account Lifecycle States

| State | Can Debit | Can Credit | Balance Requirement |
|-------|-----------|------------|---------------------|
| Open | Yes | Yes | None |
| Frozen (debit) | No | Yes | None |
| Frozen (credit) | Yes | No | None |
| Frozen (both) | No | No | None |
| Closed | No | No | Must be zero |

**Rules**: never delete accounts — soft-close them (historical transactions reference them). Closure is two-step: freeze, confirm zero balance, then close. Regulatory hold (AML/KYC compliance freeze) is distinct from operational freeze. Frozen accounts should still accept reversals/corrections (configurable).

## Multi-Entity CoA: Shared vs Per-Entity

**Shared CoA**: one account structure, `entity_id` field on each balance row. Consolidated reporting = SUM across entities. Simpler maintenance; harder when entities have different regulatory requirements. NetSuite subsidiary model uses this.

**Per-Entity CoA**: each entity has independent account structure. Required when entities operate under different GAAP/IFRS regimes. Consolidation mapping is complex — accounts must be explicitly mapped across entities.

**Intercompany accounts**: must net to zero in consolidation (automated reconciliation checkpoint). For N entities, intercompany pairs grow as N×(N-1)/2. Above ~10 entities, use a hub-and-spoke model: all intercompany flows route through a central treasury entity.

## Dimensional Balances over Dimensional Accounts

Don't encode dimensions (currency, entity, product, processor) into account identity. 5 processors × 30 currencies × 3 entities = 450 accounts for one account type — adding a 4th entity requires 150 new accounts and updated reporting.

Instead, store dimensions as balance-row fields (`entity_id`, `currency`, `product`). One account record + many balance rows with different dimension values. Queries filter/aggregate on dimension columns.

## Roll-Up Hierarchy: Two Strategies

**Materialized hierarchy**: each account stores `parent_id`. Roll-ups via recursive CTE or pre-computed aggregates. Better for read-heavy reporting; restructuring requires updating parent refs.

**Tag-based grouping**: accounts carry metadata tags (`{"report_group": "cash"}`). Roll-ups via GROUP BY. More flexible for ad-hoc analysis; requires tag governance to stay consistent.

Keep hierarchy shallow — 3 levels max unless an intermediate level is actively used in reporting. Deep hierarchies slow queries and complicate restructuring.

### Java/JPA: Modeling CoA Hierarchy

Use `@ManyToOne(fetch = LAZY) Account parent` with a `@Column(name = "path")` storing materialized path (e.g., `/1000/1050/`) for efficient subtree queries without recursive CTEs.

```java
@Entity
public class Account {
    @Id UUID id;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    Account parent;
    String path; // materialized path: "/root-id/parent-id/this-id/"
    AccountType type;
    String glCode;
    int templateVersion;
}
```

Subtree query: `WHERE path LIKE :prefix || '%'` — add a B-tree index on `path`.

### PostgreSQL: Hierarchy Storage Options

**`ltree` extension**: purpose-built for label trees. Supports `@>` (ancestor), `<@` (descendant), `~` (lquery). Best for dynamic hierarchies with frequent subtree queries.

**Materialized path (varchar)**: portable, no extension required. Use `path LIKE '/root/%'` with a B-tree index. Simpler than `ltree` for shallow hierarchies.

**Recursive CTE**: flexible but slower at scale. Reserve for ad-hoc reporting, not hot-path queries.

## Anti-Patterns

**Business logic in account numbers**: encoding mutable attributes (product, region) into account codes creates structural rigidity. Account codes should be stable identifiers; use metadata for mutable attributes.

**Account proliferation via dimensional encoding**: separate account per dimension combination. Fix: dimensional balance rows instead.

**Over-engineered hierarchy**: 7-level deep CoA "for flexibility" when 3 would suffice. Rule of thumb: if no one has asked for intermediate-level roll-ups, don't create the level.

**Premature GL integration**: building GL mapping before the subledger model stabilizes. Subledger changes frequently in the first 6–12 months. Stabilize the subledger first, add GL integration as a separate layer afterward.

**No account versioning**: without effective-dated mappings and template versioning, historical reports break on restructuring and reclassification has no audit trail.

**Namespace collisions in multi-tenant systems**: human-readable codes need explicit tenant scoping even when internal IDs are UUIDs.

## Cross-Refs

- `~/.claude/learnings/postgresql-query-patterns.md` — recursive CTEs, ltree, index strategies for hierarchical queries
- `~/.claude/learnings/java/spring-boot.md` — JPA entity mapping patterns applicable to account hierarchy modeling
