# Decision Log

All consolidation actions and judgments, logged for auditability and rollback.

**Format**: Every action (HIGH auto-applied, MEDIUM judged, persona enrichment) gets a row. The Decision column shows `applied`, `blocked`, or `skipped`. The Rationale column explains why — especially important for MEDIUM judgments where the agent exercised autonomous discretion.

## Methodology (loaded iter 1)

Read classification-model.md (6-bucket model), routing-table.md (content routing), persona-design.md (4-section structure), curation-insights.md (operational calibration), curate SKILL.md (analysis methodology), broad-sweep-methodology.md (sweep steps). Key criteria: thin files <20 lines fold-and-delete, unclustered files with existing cluster target → move/fold, rename is HIGH, merge for cohesion is MEDIUM auto-apply.

| Iter | Content Type | Action | Source | Target | Confidence | Decision | Rationale |
|------|-------------|--------|--------|--------|------------|----------|-----------|
| 1 | LEARNINGS | fold-and-delete | claude-authoring-skill-design.md | claude-authoring/skill-design.md | HIGH | applied | Thin file (14 lines, 2 patterns), explicit Related pointer to target, cluster exists |
| 1 | LEARNINGS | fold-and-delete | spring-boot-gotchas.md | java/spring-boot-gotchas.md | HIGH | applied | Thin file (8 lines, 1 pattern), ZoneOffset nuance complements existing ZoneId pattern |
| 1 | LEARNINGS | fold-and-delete | java-spring-boot-gotchas.md | java/spring-boot-gotchas.md | HIGH | applied | 4 patterns (log.debug, LocalTime, Optional.orElse, format strings) not in cluster file — verified no overlap |
| 1 | LEARNINGS | fold-and-delete | infosec-gotchas.md | java/infosec-gotchas.md | HIGH | applied | 3 Java-specific security patterns (HMAC, SpEL, scanner), cluster file is the authoritative Java security tripwires |
| 1 | LEARNINGS | fold-and-delete | java-security-patterns.md | java/infosec-gotchas.md | HIGH | applied | 1 pattern (logging PII), Java-specific security, same target as infosec-gotchas |
| 1 | LEARNINGS | move | gitlab-ci-patterns.md | cicd/gitlab-ci-patterns.md | HIGH | applied | 54-line file entirely about GitLab CI, cicd/ cluster exists with gitlab.md companion — git mv preserves history |
| 1 | LEARNINGS | fold-and-delete | cicd-testing-strategy.md | cicd/patterns.md | HIGH | applied | Thin file (18 lines, 2 patterns), test gating and iterative validation fit the CI patterns file |
| 1 | LEARNINGS | merge-and-move | java-code-quality.md + java-code-quality-and-testing.md | java/code-quality.md | MEDIUM | applied | Two thin files (18+10 lines) about Java code quality, merged into new cluster file. Reversible, no content lost |
| 1 | LEARNINGS | merge-and-move | java-concurrency-patterns.md + java-concurrency-and-resources.md | java/concurrency.md | MEDIUM | applied | Two thin files (10+10 lines) about Java concurrency, merged into new cluster file. Reversible |
| 1 | LEARNINGS | merge-and-move | java-integration-patterns.md + java-spring-configuration.md | java/integration.md | MEDIUM | applied | gRPC proto builders + Spring Security 6 interceptors → new integration file. Both Java integration patterns |
| 1 | LEARNINGS | move | java-testing-patterns.md | java/testing.md | MEDIUM | applied | Java-specific testing (TestNG, assertion hygiene) → java cluster, not testing cluster (which is JS-focused) |
| 1 | LEARNINGS | stale-path-fix | deep-dive-tracker.json | — | HIGH | applied | Fixed 5 stale tracker paths: web-session-sync, playwright-patterns, testing-patterns, newman-postman, vercel-deployment |
| 1 | LEARNINGS | index-update | java/CLAUDE.md | — | HIGH | applied | Added 4 new cluster files to java/ index |
| 1 | LEARNINGS | index-update | cicd/CLAUDE.md | — | HIGH | applied | Added gitlab-ci-patterns.md and patterns.md to cicd/ index |
| 2 | SKILLS | delete | skill-references/sweep-status-design.md | — | HIGH | applied | Draft design sketch with zero consumers — not referenced by any SKILL.md, skill-reference, or learnings file |
| 3 | GUIDELINES | wire-to-CLAUDE.md | guidelines/context-aware-learnings.md | CLAUDE.md @-reference or procedural table | MEDIUM | blocked | 55-line guideline defines mandatory learnings search gates (session-start, plan-mode, keyword, etc.) but has no CLAUDE.md wiring. Learning `guidelines.md:87` says it's behavioral (should be @-ref). But 55 lines always-on is significant context cost. Human should decide: @-reference vs procedural table vs leave-as-is. |
