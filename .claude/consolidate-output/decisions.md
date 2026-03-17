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
| 9 | DEEP_DIVE | Takeaway compression | process-conventions.md (3 patterns) | — | MEDIUM | applied | Removed 3 redundant Takeaway lines (lines 122, 128, 134) that restated heading+body: "Review summary vs inline" (zero overlap = already stated), "Emoji reactions" (resolved=emoji = already stated), "Don't post empty reviews" (silence is signal = already stated). 166→163 lines. Same pattern as spring-boot.md iter 8. |
| 10 | DEEP_DIVE | Takeaway compression | code-quality-instincts.md (9 patterns) | — | MEDIUM | applied | Removed 9 redundant Takeaway lines, all pure restatements of heading+body. Patterns: "Remove dead code" (audit opportunity = already stated), "Reuse existing calculation" (search first = already stated), "Named guard variables" (self-documenting = already stated), "Inline dict values" (don't name already-named = already stated), "Inline parameter docs" (move to code = already stated), "Eliminate duplicate entities" (base class = already stated), "Raise exceptions" (heading restatement), "Name primary method" (simplest name = already stated), "Consolidation" (single location = already stated). 131→113 lines (~14% compression). |
| 11 | DEEP_DIVE | Takeaway compression | financial-applications.md (6 patterns) | — | MEDIUM | applied | Removed 6 redundant Takeaway lines (patterns 3-8), all pure restatements of heading+body: "FeeMode" (Gross=Net+Fee invariant = already in body), "Proportional fee" (zero-divisor guard = heading), "Side-effect reads" (separate state transition = body), "Two-layer idempotency" (align keys = body), "Domain vs vendor enum" (domain language = body), "Off-by-one" (concrete examples = body). 64→52 lines (~19% compression). |
| 11 | DEEP_DIVE | Cross-ref wiring | financial-applications.md (See also) | bignumber-financial-arithmetic.md | MEDIUM | applied | financial-applications.md references bignumber-financial-arithmetic.md but no back-ref existed. Added See also section to bignumber-financial-arithmetic.md with bidirectional link (JS BigNumber ↔ Java BigDecimal financial patterns). |
| 13 | DEEP_DIVE | Cross-ref wiring | ci-cd.md (See also) | ci-cd-gotchas.md | MEDIUM | applied | ci-cd-gotchas.md declares itself "Companion to ci-cd.md" but ci-cd.md had no back-reference. Added See also section. |
| 13 | DEEP_DIVE | Cross-ref wiring | gitlab-ci-cd.md (See also) | ci-cd-gotchas.md | MEDIUM | applied | ci-cd-gotchas.md declares itself "Companion to gitlab-ci-cd.md" but gitlab-ci-cd.md had no back-reference. Added See also section. |
| 14 | DEEP_DIVE | Cross-ref wiring | multi-agent-patterns.md (See also) | parallel-plans.md | MEDIUM | applied | parallel-plans.md → multi-agent-patterns.md existed (sweep 1) but no reverse. Added back-ref: plan-level complement to agent orchestration patterns. |

## Methodology Loaded (Iter 1)

First invocation — loaded all methodology references:
- classification-model.md: 6-bucket model (skill candidate, template, context, guideline candidate, standalone reference, outdated). Migration litmus test: "Would this change how I execute?" Context cost check for @-referenced files.
- claude-authoring-content-types.md: Content type routing table. Quick decision tree.
- persona-design.md: 4-section structure, 60-80 line mature size, suggestion criteria (3+ files, 8+ patterns).
- curation-insights.md: Cadence check, rename=HIGH, inline analysis <25 files, post-prune cross-ref cleanup, compression targets (provenance, self-assessments, debugging trails, verbose code).
- SKILL.md (curate): Content mode vs skill mode, broad sweep variant, multi-file pipelines.

## Iter 15 — Deep Dive: newman-postman.md

| Iter | Type | Action | Source | Target | Confidence | Decision | Rationale |
|------|------|--------|--------|--------|------------|----------|-----------|
| 15 | DEEP_DIVE | (clean) | newman-postman.md | — | — | — | 4 patterns, all standalone reference / keep. Cross-refs valid (local-dev-seeding.md bidirectional, git-patterns.md inline). No overlap, no compression. |
