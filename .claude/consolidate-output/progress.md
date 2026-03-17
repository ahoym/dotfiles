# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 2 |
| CONTENT_TYPE | GUIDELINES |
| PHASE | BROAD_SWEEP |
| DEEP_DIVE_CANDIDATES | — |
| DEEP_DIVE_COMPLETED | — |

## Pre-Flight

```
Recent commits: 115e93f Add improvements to polling code review, 5797cc1 Consolidation: 2026-03-16, d855fbc consolidate: add skill-references curation
Learnings files: 58
Skills count: 31
Skill references: 16
Guidelines files: 4
Persona files: 11
Cadence: moderate (2 curation commits in last 5)
Suggested iterations: 15
```

## Content Type Status

### LEARNINGS
- **Sweeps**: 1
- **HIGHs applied**: 0
- **MEDIUMs applied**: 0
- **MEDIUMs blocked**: 0

### SKILLS
- **Sweeps**: 0
- **HIGHs applied**: 0
- **MEDIUMs applied**: 0
- **MEDIUMs blocked**: 0

### GUIDELINES
- **Sweeps**: 0
- **HIGHs applied**: 0
- **MEDIUMs applied**: 0
- **MEDIUMs blocked**: 0

## Iteration Log

<!-- Each iteration appends: | N | CONTENT_TYPE | HIGHs | MEDIUMs | LOWs | Actions | Notes | -->

| Iter | Content Type | HIGHs | MEDIUMs | LOWs | Actions | Notes |
|------|-------------|-------|---------|------|---------|-------|
| 1 | LEARNINGS | 0 | 0 | 0 | 0 | Clean — 58 files, ~1200 patterns. Well-maintained from run 13. |
| 2 | SKILLS | 0 | 0 | 0 | 0 | Clean — 31 skills, 16 skill-references. All consumers wired, no stale model strings. |

## Deep Dive Status

<!-- Populated when PHASE transitions to DEEP_DIVE after broad sweeps complete -->

| File | Status | Iter | Summary |
|------|--------|------|---------|

## Notes for Next Iteration

<!-- Appended each iteration with ### Iter N heading — do not overwrite -->

### Iter 1

**Methodology loaded** (run_count incremented to 14):
- 6-bucket classification model: skill candidate, template, context, guideline candidate, standalone reference, outdated
- Migration litmus test: "Would having this in the target file actually change how I execute?"
- Context cost check: `@`-referenced = always-on cost, prefer conditional references for domain-specific content
- Thin files < 20 lines of pointers = fold-and-delete candidates (EXCEPT `*-gotchas.md` — never merge into parent)
- Persona coverage != learning obsolescence (keep learnings that prevent specific wrong approaches)
- MEMORY.md is not a curation safety net (prune MEMORY.md entry, not the learning)

**LEARNINGS clusters** (58 files):
- Meta/Tooling (16): claude-authoring-*, claude-code*, skill-platform-portability, ralph-loop, multi-agent-patterns, parallel-plans, cross-repo-sync, explore-repo, process-conventions
- XRPL+TS (8): xrpl-*, order-book-pricing, bignumber-financial-arithmetic
- React/Frontend (9): react-*, nextjs, accessibility-patterns, ui-patterns, reactive-data-patterns, playwright-patterns, typescript-specific, web-session-sync
- Java/Spring (6): spring-boot*, java-observability*, java-infosec-gotchas, quarkus-kotlin
- CI/CD+DevOps (7): ci-cd*, gitlab-*, typescript-ci-gotchas, vercel-deployment, aws-*
- General Dev (12): api-design, code-quality-instincts, refactoring-patterns, resilience-patterns, financial-applications, git-patterns, bash-patterns, local-dev-seeding, newman-postman, postgresql-query-patterns, testing-patterns, python-specific

**Cross-reference graph**: ~50 connected (See also), ~8 isolated, 4 hubs (claude-authoring-content-types 6+ inbound, code-quality-instincts 3+, multi-agent-patterns 3+, process-conventions 3+)

**Deep dive candidates from LEARNINGS** (criterion 6 — unreviewed):
- claude-code-hooks.md
- java-infosec-gotchas.md
- java-observability-gotchas.md
- spring-boot-gotchas.md
- postgresql-query-patterns.md

**Deep dive candidates from LEARNINGS** (criterion 1 — hub):
- claude-authoring-content-types.md (6+ inbound refs)

### Iter 2

**SKILLS sweep** (31 skills, 16 skill-references):
- 5 clusters: git:* (10), learnings:* (4), ralph:* (7), parallel-plan:* (2), standalone (8)
- No overlap (80%+) detected between any pair
- All 16 skill-references have consumers (including transitively via platform cluster pattern)
- Co-Authored-By strings all current (Claude Opus 4.6)
- No namespace gaps, no stale references, no scope issues

**Deep dive candidates from SKILLS** (criterion 6 — unreviewed, criterion 7 — stale):
- 26 skills never deep-dived (criterion 6)
- 5 tracked skills stale at threshold (criterion 7): quantum-tunnel-claudes, extract-request-learnings, split-commit, consolidate, ralph:consolidate:init
- Prioritization: unreviewed skills/skill-refs/guidelines first per spec
