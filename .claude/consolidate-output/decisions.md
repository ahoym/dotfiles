# Decision Log

All consolidation actions and judgments, logged for auditability and rollback.

**Format**: Every action (HIGH auto-applied, MEDIUM judged, persona enrichment) gets a row. The Decision column shows `applied`, `blocked`, or `skipped`. The Rationale column explains why — especially important for MEDIUM judgments where the agent exercised autonomous discretion.

| Iter | Content Type | Action | Source | Target | Confidence | Decision | Rationale |
|------|-------------|--------|--------|--------|------------|----------|-----------|
| 1 | LEARNINGS | move section | ci-cd-gotchas.md "Git Workflows" | git-patterns.md | MEDIUM | applied | Cascade rebase + checkout -B are git branching patterns, not CI/CD gotchas; moved to topically correct file |
| 1 | LEARNINGS | reference wiring | local-dev-seeding.md | java-backend persona | MEDIUM | applied | Newman + SQL seeding directly relevant to java backend local dev; persona already refs newman-postman.md |
| 1 | LEARNINGS | reference wiring | claude-code-hooks.md | claude-config-expert persona | MEDIUM | applied | Hook authoring mechanics essential for config surface; was 2-hops away via claude-code.md cross-ref |
| 7 | DEEP_DIVE | delete section | claude-code.md "Worktree Branches Block gh pr checkout" | — | HIGH | applied | 2-line stub fully covered by claude-authoring-skills.md lines 488-490 (includes detection pattern, skill design recs, and cross-ref back to claude-code.md) |
| 8 | DEEP_DIVE | delete bullet | curation-insights.md line 39 (@ refs always-on cost) | — | HIGH | applied | Near-verbatim duplicate of SKILL.md line 29 (eagerly loaded) + classification-model.md line 111 |
| 8 | DEEP_DIVE | delete bullet | curation-insights.md line 40 (non-@ selective loading) | — | HIGH | applied | Near-verbatim duplicate of SKILL.md line 30 (eagerly loaded) + classification-model.md line 113 |
| 8 | DEEP_DIVE | delete bullet | curation-insights.md line 42 (granular > monolithic) | — | HIGH | applied | Near-verbatim duplicate of SKILL.md line 31 (eagerly loaded) |
| 8 | DEEP_DIVE | delete bullet | curation-insights.md line 62 (deep dives bounded) | — | HIGH | applied | Duplicate of deep-dive-methodology.md § Bounded + stale "max 5 invocations" (now max 30) |
| 8 | DEEP_DIVE | delete bullet | curation-insights.md line 71 (guidelines must be universal) | — | HIGH | applied | Duplicate of content-mode.md § 4b guideline gate + claude-authoring-content-types.md § Evaluating Existing Guidelines |
| 8 | DEEP_DIVE | merge section | curation-insights.md "Classification Calibration (cont.)" → "Classification Calibration" | — | MEDIUM | applied | 1-bullet section after HIGH deletion; no value in split section structure |
| 8 | DEEP_DIVE | merge section | curation-insights.md "Phase 2 Patterns" → "Execution Strategy" | — | MEDIUM | applied | 1-bullet section after HIGH deletion; content is execution calibration, fits Execution Strategy |
| 11 | DEEP_DIVE | update advice | git-patterns.md line 182 (per_page=100 → --paginate) | — | MEDIUM | applied | per_page=100 for full fetches is outdated — misses results beyond 100. bash-patterns.md, claude-code.md, and process-conventions.md all converged on --paginate. Updated to --paginate. |
| 12 | DEEP_DIVE | delete section | java-backend.md "Known gotchas & platform specifics" (lines 27-31) | — | HIGH | applied | Both gotcha items (ShedLock exception swallowing, per-item catch in loops) are near-verbatim duplicates of spring-boot-gotchas.md lines 5-6, which is already a proactive load for this persona. Removed 5 lines. |
| 13 | DEEP_DIVE | delete 2 lines | claude-config-expert.md lines 20-21 (boundary case duplicates) | — | HIGH | applied | Two boundary cases ("prescriptive but conditional on domain" and "guideline restates skill default") are near-verbatim of claude-authoring-content-types.md lines 30-31, which is this persona's proactive load. Same pattern as java-backend iter 12. 54→52 lines. |
