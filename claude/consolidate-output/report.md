# Consolidation Report

## Run Info

| Field | Value |
|-------|-------|
| Started | 2026-04-08 |
| Branch | consolidate/2026-04-08 |
| Worktree | claude/worktrees/consolidate-2026-04-08 |
| Iterations | 16 |
| Status | COMPLETE |

## Summary

| Content Type | Sweeps | HIGHs Applied | MEDIUMs Applied | MEDIUMs Blocked | Personas Enriched |
|-------------|--------|---------------|-----------------|-----------------|-------------------|
| Learnings | 1 | 9 | 4 | 0 | 0 |
| Skills | 1 | 1 | 0 | 0 | 0 |
| Guidelines | 1 | 0 | 0 | 1 | 0 |
| Deep Dive | 12 | 34 | 1 | 0 | 0 |
| **Total** | **15** | **44** | **5** | **1** | **0** |

## Actions (Chronological)

| Iter | Content Type | Action | Source | Target | Confidence |
|------|-------------|--------|--------|--------|------------|
| 1 | LEARNINGS | fold-and-delete | claude-authoring-skill-design.md | claude-authoring/skill-design.md | HIGH |
| 1 | LEARNINGS | fold-and-delete | spring-boot-gotchas.md | java/spring-boot-gotchas.md | HIGH |
| 1 | LEARNINGS | fold-and-delete | java-spring-boot-gotchas.md | java/spring-boot-gotchas.md | HIGH |
| 1 | LEARNINGS | fold-and-delete | infosec-gotchas.md | java/infosec-gotchas.md | HIGH |
| 1 | LEARNINGS | fold-and-delete | java-security-patterns.md | java/infosec-gotchas.md | HIGH |
| 1 | LEARNINGS | move | gitlab-ci-patterns.md | cicd/gitlab-ci-patterns.md | HIGH |
| 1 | LEARNINGS | fold-and-delete | cicd-testing-strategy.md | cicd/patterns.md | HIGH |
| 1 | LEARNINGS | stale-path-fix | deep-dive-tracker (5 entries) | — | HIGH |
| 1 | LEARNINGS | index-update | java/CLAUDE.md, cicd/CLAUDE.md | — | HIGH |
| 1 | LEARNINGS | merge-and-move | java-code-quality.md + java-code-quality-and-testing.md | java/code-quality.md | MEDIUM |
| 1 | LEARNINGS | merge-and-move | java-concurrency-patterns.md + java-concurrency-and-resources.md | java/concurrency.md | MEDIUM |
| 1 | LEARNINGS | merge-and-move | java-integration-patterns.md + java-spring-configuration.md | java/integration.md | MEDIUM |
| 1 | LEARNINGS | move | java-testing-patterns.md | java/testing.md | MEDIUM |
| 2 | SKILLS | delete | skill-references/sweep-status-design.md | — | HIGH |
| 3 | GUIDELINES | wire-to-CLAUDE.md (blocked) | context-aware-learnings.md | CLAUDE.md | MEDIUM |
| 4 | TRIAGE | diff-routed-triage | 97a6278..HEAD (160+ files) | 12 groups, 38 targets | — |
| 5 | DEEP_DIVE | stale-ref-fix | protobuf-patterns.md | java/integration.md | HIGH |
| 6 | DEEP_DIVE | (clean) | java/testing, infosec-gotchas, spring-boot-gotchas | — | — |
| 7 | DEEP_DIVE | fold-and-delete | cicd/gotchas.md (GitLab sections) | cicd/gitlab.md (already present) | HIGH |
| 7 | DEEP_DIVE | fold-and-delete | cicd/gotchas.md (GitHub Actions) | cicd/patterns.md | HIGH |
| 7 | DEEP_DIVE | index-update | cicd/CLAUDE.md | — | HIGH |
| 8 | DEEP_DIVE | dedup-delete | learnings-content.md (2 sections) | learnings-organization.md, claude-md-advanced.md | HIGH |
| 8 | DEEP_DIVE | dedup-delete | claude-md.md (3 sections) | claude-md-advanced.md | HIGH |
| 9 | DEEP_DIVE | stale-ref-fix (x3) | polling-review-skills.md | Fixed 3 stale refs: claude-authoring-skills.md, skill-design.md→skill-references-and-loading.md, content-types.md→routing-table.md | HIGH |
| 10 | DEEP_DIVE | remove-intra-ref (x4) | director-patterns.md, orchestration.md, headless-nesting.md | Removed 4 intra-sub-cluster sibling refs | HIGH |
| 10 | DEEP_DIVE | heading-fix | orchestration.md | H3→H2 structural consistency | HIGH |
| 11 | DEEP_DIVE | dedup-delete (x11) | skill-platform-portability.md (3 agent + 8 plugin sections) | agent-definitions.md, plugin-packaging.md (already present) | HIGH |
| 11 | DEEP_DIVE | remove-intra-ref (x2) | platform-tools-and-automation.md | Removed 2 intra-cluster sibling refs | HIGH |
| 11 | DEEP_DIVE | dedup-fold + structural-fix | platform-tools-and-automation.md | Folded duplicate Glob section, moved section before Cross-Refs | HIGH |
| 11 | DEEP_DIVE | detail-fold | plugin-packaging.md | Added VS Code issue link from removed source | HIGH |
| 12 | DEEP_DIVE | (clean) | sweep-sessions.md, ralph-curation.md, ralph-loop.md | — | — |
| 13 | DEEP_DIVE | fold-section (x2), structural-fix | bash-patterns.md (fold 2 thin sections), review-conventions.md (move post-Cross-Refs sections) | 3 HIGHs applied | git-patterns.md clean (density exemption) |
| 14 | DEEP_DIVE | fold-and-delete (x3), fold-and-delete (x1 MEDIUM) | database-patterns.md→postgresql-query-patterns.md, framework-patterns.md→aws/patterns.md+java/spring-boot-gotchas.md, architecture-patterns.md→api-design.md | 3 HIGHs + 1 MEDIUM applied | Net -3 files. All thin unclustered fold candidates resolved. |
| 15 | DEEP_DIVE | fold-and-delete (x3) | docker-security.md→cicd/patterns.md, security.md→java/infosec-gotchas.md, documentation-hygiene.md→code-quality-instincts.md | 3 HIGHs applied | Net -3 files. All thin unclustered security/hygiene files resolved. |
| 16 | DEEP_DIVE + HOUSEKEEPING | stale-ref-fix, index-cleanup, tracker-update | playwright-patterns.md (stale testing-patterns.md ref), .keyword-index.json (gotchas.md stale entries) | 1 HIGH applied + housekeeping | Group 12 stale rotation: 5 targets, 4 clean, 1 stale ref fix. Housekeeping: keyword index partial cleanup, tracker anchored. |

## Blocked Items

See `review.md` for details.

- Total: 1
- Open: 1
- Resolved: 0

## Collection Health

| Metric | Before | After |
|--------|--------|-------|
| Learnings files | 110 | 90 |
| Skills | 36 | 36 |
| Skill references | 26 | 25 |
| Guidelines files | 4 | 4 |
| Persona files | 19 | 19 |
