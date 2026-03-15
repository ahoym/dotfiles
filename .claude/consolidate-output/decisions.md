# Decision Log

All consolidation actions and judgments, logged for auditability and rollback.

**Format**: Every action (HIGH auto-applied, MEDIUM judged, persona enrichment) gets a row. The Decision column shows `applied`, `blocked`, or `skipped`. The Rationale column explains why — especially important for MEDIUM judgments where the agent exercised autonomous discretion.

| Iter | Content Type | Action | Source | Target | Confidence | Decision | Rationale |
|------|-------------|--------|--------|--------|------------|----------|-----------|
| 1 | LEARNINGS | fix misplaced takeaway + merge duplicate sections | process-conventions.md | process-conventions.md | HIGH | applied | Takeaway "No findings = no post" was attached to "Verify safeguards survive fixes" but belongs to "Don't post empty reviews". Two sections ("Verify safeguards survive fixes" + "Verify the fix didn't break the safeguard") covered the same concept — merged into one cohesive section with proper takeaway. |
| 1 | LEARNINGS | reference wiring (See also) | financial-applications.md | financial-applications.md | MEDIUM | applied | No cross-refs existed. bignumber-financial-arithmetic.md covers JS BigNumber.js for frontend; financial-applications.md covers Java BigDecimal for backend. Same domain (financial arithmetic), different stacks — lateral discovery value. Reversible, no content lost. |
| 1 | LEARNINGS | reference wiring (See also) | aws-messaging.md | aws-messaging.md | MEDIUM | applied | SQS consumer design (idempotency, DLQ, retry) directly relates to resilience-patterns.md (dedup-before-process, domain exceptions, scheduler decoupling). Non-obvious connection across different domain clusters. Reversible, no content lost. |
