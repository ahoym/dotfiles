# Decision Log

All consolidation actions and judgments, logged for auditability and rollback.

**Format**: Every action (HIGH auto-applied, MEDIUM judged, persona enrichment) gets a row. The Decision column shows `applied`, `blocked`, or `skipped`. The Rationale column explains why — especially important for MEDIUM judgments where the agent exercised autonomous discretion.

| Iter | Content Type | Action | Source | Target | Confidence | Decision | Rationale |
|------|-------------|--------|--------|--------|------------|----------|-----------|
| 1 | LEARNINGS | move section | ci-cd-gotchas.md "Git Workflows" | git-patterns.md | MEDIUM | applied | Cascade rebase + checkout -B are git branching patterns, not CI/CD gotchas; moved to topically correct file |
| 1 | LEARNINGS | reference wiring | local-dev-seeding.md | java-backend persona | MEDIUM | applied | Newman + SQL seeding directly relevant to java backend local dev; persona already refs newman-postman.md |
| 1 | LEARNINGS | reference wiring | claude-code-hooks.md | claude-config-expert persona | MEDIUM | applied | Hook authoring mechanics essential for config surface; was 2-hops away via claude-code.md cross-ref |
