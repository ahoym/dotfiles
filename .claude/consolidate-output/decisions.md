# Decision Log

All consolidation actions and judgments, logged for auditability and rollback.

**Format**: Every action (HIGH auto-applied, MEDIUM judged, persona enrichment) gets a row. The Decision column shows `applied`, `blocked`, or `skipped`. The Rationale column explains why — especially important for MEDIUM judgments where the agent exercised autonomous discretion.

| Iter | Content Type | Action | Source | Target | Confidence | Decision | Rationale |
|------|-------------|--------|--------|--------|------------|----------|-----------|
| 1 | LEARNINGS | Remove stale internal ref | ci-cd-gotchas.md | — | MEDIUM | applied | "See ci-cd.md for full YAML examples" — ci-cd.md has no YAML examples; stale reference |
| 1 | LEARNINGS | Cross-ref wiring | parallel-plans.md | multi-agent-patterns.md | MEDIUM | applied | Shared agent orchestration concerns; non-obvious lateral link (different mental model — "plans" vs "agents") |
| 1 | LEARNINGS | Cross-ref wiring | spring-boot.md | postgresql-query-patterns.md | MEDIUM | applied | Migration safety patterns complement Spring Boot Flyway gotchas; not keyword-discoverable |
| 1 | LEARNINGS | Cross-ref wiring | newman-postman.md | local-dev-seeding.md | MEDIUM | applied | Newman is the API seeding layer in the hybrid architecture; bidirectional discovery value |
| 1 | LEARNINGS | Cross-ref wiring | local-dev-seeding.md | newman-postman.md | MEDIUM | applied | Bidirectional complement of M4 |
| 2 | SKILLS | Persona de-enrichment | java-devops.md (Metrics & Observability) | java-observability-gotchas.md | MEDIUM | applied | 4 inline gotchas nearly verbatim from proactive-loaded learning file; replaced with 1-line judgment summary + reference |
| 6 | DEEP_DIVE | Title/framing fix | claude-code.md § "Use TaskOutput" | multi-agent-patterns.md § "TaskOutput Only Works" | MEDIUM | applied | Section title said "Background Agent Progress" but TaskOutput only works for background Bash tasks (not Agent tasks). Title and opening line contradicted multi-agent-patterns.md. Renamed to "Background Bash Tasks" and added explicit cross-ref. |
| 7 | DEEP_DIVE | Cross-ref wiring | git-patterns.md (See also) | ci-cd-gotchas.md | MEDIUM | applied | git-patterns.md references ci-cd-gotchas.md in See also but ci-cd-gotchas.md had no back-reference. Added See also section with bidirectional link. |
| 8 | DEEP_DIVE | Takeaway compression | spring-boot.md (24 patterns) | — | MEDIUM | applied | Removed 24 redundant Takeaway lines that restated heading+body. Folded 2 valuable Takeaways into body text (pattern 15: @Data/@Builder recipe; pattern 25: multi-replica safety). Minor body tightening (provenance removal, procedure folding). 205→157 lines (~23% compression). |
| 8 | DEEP_DIVE | Cross-ref wiring | spring-boot.md (See also) | spring-boot-gotchas.md | MEDIUM | applied | spring-boot-gotchas.md self-describes as "Companion to spring-boot.md" (line 3) but spring-boot.md had no back-reference. Added to See also. |

## Methodology Loaded (Iter 1)

First invocation — loaded all methodology references:
- classification-model.md: 6-bucket model (skill candidate, template, context, guideline candidate, standalone reference, outdated). Migration litmus test: "Would this change how I execute?" Context cost check for @-referenced files.
- claude-authoring-content-types.md: Content type routing table. Quick decision tree.
- persona-design.md: 4-section structure, 60-80 line mature size, suggestion criteria (3+ files, 8+ patterns).
- curation-insights.md: Cadence check, rename=HIGH, inline analysis <25 files, post-prune cross-ref cleanup, compression targets (provenance, self-assessments, debugging trails, verbose code).
- SKILL.md (curate): Content mode vs skill mode, broad sweep variant, multi-file pipelines.
