# Decision Log

All consolidation actions and judgments, logged for auditability and rollback.

**Format**: Every action (HIGH auto-applied, MEDIUM judged, persona enrichment) gets a row. The Decision column shows `applied`, `blocked`, or `skipped`. The Rationale column explains why — especially important for MEDIUM judgments where the agent exercised autonomous discretion.

| Iter | Content Type | Action | Source | Target | Confidence | Decision | Rationale |
|------|-------------|--------|--------|--------|------------|----------|-----------|
| 1 | LEARNINGS | add cross-ref See Also | java-observability.md | java-observability-gotchas.md | HIGH | applied | Companion pair — gotchas file header says "Companion to java-observability.md" but no reciprocal link existed in the patterns file |
| 1 | LEARNINGS | add cross-ref See Also | quarkus-kotlin.md | spring-boot.md | HIGH | applied | File was isolated (no See Also section); added link to related Java ecosystem file for discoverability |
| 1 | LEARNINGS | add cross-ref See Also | java-infosec-gotchas.md | api-design.md | MEDIUM | applied | Gotchas file had no companion or cross-ref; api-design.md has security hardening section that provides positive counterpart to the tripwires list. Reversible, additive. |
| 2 | SKILLS | fix stale skill reference | git/repoint-branch/SKILL.md | — | HIGH | applied | `/pr` skill no longer exists — renamed to `/git:create-request`. Updated line 105 to reference current skill name. |
