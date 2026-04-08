# Consolidation Report

## Run Info

| Field | Value |
|-------|-------|
| Started | 2026-04-08 |
| Branch | consolidate/2026-04-08 |
| Worktree | claude/worktrees/consolidate-2026-04-08 |
| Iterations | 8 |
| Status | IN_PROGRESS (deep dive phase) |

## Summary

| Content Type | Sweeps | HIGHs Applied | MEDIUMs Applied | MEDIUMs Blocked | Personas Enriched |
|-------------|--------|---------------|-----------------|-----------------|-------------------|
| Learnings | 1 | 9 | 4 | 0 | 0 |
| Skills | 1 | 1 | 0 | 0 | 0 |
| Guidelines | 1 | 0 | 0 | 1 | 0 |
| Deep Dive | 4 | 9 | 0 | 0 | 0 |
| **Total** | **7** | **19** | **4** | **1** | **0** |

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

## Blocked Items

See `review.md` for details.

- Total: 1
- Open: 1
- Resolved: 0

## Collection Health

| Metric | Before | After |
|--------|--------|-------|
| Learnings files | 110 | 96 |
| Skills | 36 | — |
| Skill references | 26 | 25 |
| Guidelines files | 4 | 4 |
| Persona files | 19 | 19 |
