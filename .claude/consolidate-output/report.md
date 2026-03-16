# Consolidation Report

## Run Info

| Field | Value |
|-------|-------|
| Started | 2026-03-15T22:25:09-0700 |
| Branch | consolidate/2026-03-15 |
| Worktree | .claude/worktrees/consolidate-2026-03-15 |
| Iterations | 18 |
| Rounds | 1 (complete), 2 (complete — clean) |
| Status | DEEP_DIVE — 12 of 24 candidates complete |

## Summary

| Content Type | Sweeps | HIGHs Applied | MEDIUMs Applied | MEDIUMs Blocked | Personas Enriched |
|-------------|--------|---------------|-----------------|-----------------|-------------------|
| Learnings | 2 | 0 | 3 | 0 | 2 |
| Skills | 2 | 0 | 0 | 0 | 0 |
| Guidelines | 2 | 0 | 0 | 0 | 0 |
| Deep Dives | 12 | 9 | 5 | 0 | 0 |
| **Total** | **18** | **9** | **8** | **0** | **2** |

## Actions (Chronological)

| Iter | Round | Content Type | Action | Source | Target | Confidence |
|------|-------|-------------|--------|--------|--------|------------|
| 1 | 1 | LEARNINGS | move section | ci-cd-gotchas.md "Git Workflows" | git-patterns.md | MEDIUM |
| 1 | 1 | LEARNINGS | reference wiring | local-dev-seeding.md | java-backend persona | MEDIUM |
| 1 | 1 | LEARNINGS | reference wiring | claude-code-hooks.md | claude-config-expert persona | MEDIUM |
| 2 | 1 | SKILLS | (clean) | — | — | — |
| 3 | 1 | GUIDELINES | (clean) | — | — | — |
| 4 | 2 | LEARNINGS | (clean) | — | — | — |
| 5 | 2 | SKILLS | (clean) | — | — | — |
| 6 | 2 | GUIDELINES | (clean) | — | — | — |
| 7 | — | DEEP_DIVE | delete section | claude-code.md "Worktree Branches Block gh pr checkout" | — | HIGH |
| 8 | — | DEEP_DIVE | delete 5 bullets | curation-insights.md (duplicate content) | — | HIGH |
| 8 | — | DEEP_DIVE | merge 2 sections | curation-insights.md (structural cleanup) | — | MEDIUM |
| 9 | — | DEEP_DIVE | (clean) | resilience-patterns.md | — | — |
| 10 | — | DEEP_DIVE | (clean) | ci-cd-gotchas.md | — | — |
| 11 | — | DEEP_DIVE | update advice | git-patterns.md (per_page→paginate) | — | MEDIUM |
| 12 | — | DEEP_DIVE | delete section | java-backend.md (duplicate gotchas) | — | HIGH |
| 13 | — | DEEP_DIVE | delete 2 lines | claude-config-expert.md (duplicate boundary cases) | — | HIGH |
| 14 | — | DEEP_DIVE | update cross-ref | claude-authoring-skills.md (stale ref to deleted pattern) | — | HIGH |
| 14 | — | DEEP_DIVE | compress 2→1 | claude-authoring-skills.md (merge duplicate takeaways) | — | MEDIUM |
| 15 | — | DEEP_DIVE | fix heading levels | api-design.md (5 ### → ## for independent patterns) | — | MEDIUM |
| 16 | — | DEEP_DIVE | (clean) | skill-platform-portability.md | — | — |
| 17 | — | DEEP_DIVE | (clean) | nextjs.md | — | — |
| 18 | — | DEEP_DIVE | (clean) | react-patterns.md | — | — |

## Blocked Items

See `review.md` for details.

- Total: 0
- Open: 0
- Resolved: 0

## Collection Health

| Metric | Before | After |
|--------|--------|-------|
| Learnings files | 56 | 56 |
| Skills | 31 | 31 |
| Guidelines files | 4 | 4 |
| Persona files | 11 | 11 |
