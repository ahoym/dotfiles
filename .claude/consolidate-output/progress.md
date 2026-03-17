# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 4 |
| CONTENT_TYPE | DEEP_DIVE |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_CANDIDATES | See Deep Dive Status below (82 candidates, max guard 30) |
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
- **Sweeps**: 1
- **HIGHs applied**: 0
- **MEDIUMs applied**: 0
- **MEDIUMs blocked**: 0

### GUIDELINES
- **Sweeps**: 1
- **HIGHs applied**: 0
- **MEDIUMs applied**: 0
- **MEDIUMs blocked**: 0

## Iteration Log

<!-- Each iteration appends: | N | CONTENT_TYPE | HIGHs | MEDIUMs | LOWs | Actions | Notes | -->

| Iter | Content Type | HIGHs | MEDIUMs | LOWs | Actions | Notes |
|------|-------------|-------|---------|------|---------|-------|
| 1 | LEARNINGS | 0 | 0 | 0 | 0 | Clean — 58 files, ~1200 patterns. Well-maintained from run 13. |
| 2 | SKILLS | 0 | 0 | 0 | 0 | Clean — 31 skills, 16 skill-references. All consumers wired, no stale model strings. |
| 3 | GUIDELINES | 0 | 0 | 0 | 0 | Clean — 4 files, all @-referenced, universally needed, no overlap. Transitioned to DEEP_DIVE. |
| 4 | DEEP_DIVE | 0 | 0 | 0 | 0 | claude-authoring-content-types.md — clean. Hub confirmed. 11 patterns all KEEP. |

## Deep Dive Status

<!-- 82 total candidates across all tiers. Max guard = 30. Prioritized by spec. -->

| # | File | Tier | Criterion | Status | Iter | Summary |
|---|------|------|-----------|--------|------|---------|
| 1 | .claude/learnings/claude-authoring-content-types.md | 1 | hub (1) | done | 4 | Clean — 11 patterns, all STANDALONE REFERENCE. Hub confirmed well-maintained. |
| 2 | .claude/guidelines/communication.md | 2 | unreviewed (6) | pending | — | — |
| 3 | .claude/guidelines/context-aware-learnings.md | 2 | unreviewed (6) | pending | — | — |
| 4 | .claude/guidelines/path-resolution.md | 2 | unreviewed (6) | pending | — | — |
| 5 | .claude/guidelines/skill-invocation.md | 2 | unreviewed (6) | pending | — | — |
| 6 | .claude/commands/set-persona/claude-config-author.md | 2 | unreviewed (6) | pending | — | — |
| 7 | .claude/commands/set-persona/claude-config-reviewer.md | 2 | unreviewed (6) | pending | — | — |
| 8 | .claude/commands/set-persona/java-infosec.md | 2 | unreviewed (6) | pending | — | — |
| 9 | .claude/commands/set-persona/reviewer.md | 2 | unreviewed (6) | pending | — | — |
| 10 | .claude/skill-references/code-quality-checklist.md | 2 | unreviewed (6) | pending | — | — |
| 11 | .claude/skill-references/corpus-cross-reference.md | 2 | unreviewed (6) | pending | — | — |
| 12 | .claude/skill-references/platform-detection.md | 2 | unreviewed (6) | pending | — | — |
| 13 | .claude/skill-references/request-interaction-base.md | 2 | unreviewed (6) | pending | — | — |
| 14 | .claude/skill-references/subagent-patterns.md | 2 | unreviewed (6) | pending | — | — |
| 15 | .claude/skill-references/github/batch-operations.md | 2 | unreviewed (6) | pending | — | — |
| 16 | .claude/skill-references/github/commands.md | 2 | unreviewed (6) | pending | — | — |
| 17 | .claude/skill-references/github/comment-interaction.md | 2 | unreviewed (6) | pending | — | — |
| 18 | .claude/skill-references/github/fetch-review-data.md | 2 | unreviewed (6) | pending | — | — |
| 19 | .claude/skill-references/github/pr-management.md | 2 | unreviewed (6) | pending | — | — |
| 20 | .claude/skill-references/gitlab/batch-operations.md | 2 | unreviewed (6) | pending | — | — |
| 21 | .claude/skill-references/gitlab/commands.md | 2 | unreviewed (6) | pending | — | — |
| 22 | .claude/skill-references/gitlab/comment-interaction.md | 2 | unreviewed (6) | pending | — | — |
| 23 | .claude/skill-references/gitlab/fetch-review-data.md | 2 | unreviewed (6) | pending | — | — |
| 24 | .claude/skill-references/gitlab/pr-management.md | 2 | unreviewed (6) | pending | — | — |
| 25 | .claude/commands/do-refactor-code/SKILL.md | 2 | unreviewed (6) | pending | — | — |
| 26 | .claude/commands/do-security-audit/SKILL.md | 2 | unreviewed (6) | pending | — | — |
| 27 | .claude/commands/explore-repo/SKILL.md | 2 | unreviewed (6) | pending | — | — |
| 28 | .claude/commands/explore-repo/brief/SKILL.md | 2 | unreviewed (6) | pending | — | — |
| 29 | .claude/commands/git/address-request-comments/SKILL.md | 2 | unreviewed (6) | pending | — | — |
| 30 | .claude/commands/git/cascade-rebase/SKILL.md | 2 | unreviewed (6) | pending | — | — |
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

### Iter 4

**Deep dive 1 of 30**: `claude-authoring-content-types.md` (hub, tier 1) — CLEAN.
- Hub file is authoritative and up-to-date. All 6 spoke files confirmed present.
- Key insight: `## See also` is NOT needed for this file — the "Authoring Guides" section already lists all spoke files inline, and they're keyword-discoverable via shared "claude-authoring-" prefix. Don't add See also to files where refs are already explicit AND keyword-discoverable.
- Next: candidate 2 = `communication.md` (guidelines, unreviewed, tier 2).

### Iter 3

**GUIDELINES sweep** (4 files, all @-referenced from .claude/CLAUDE.md):
- communication.md (~200 lines) — universal communication patterns, comprehensive
- context-aware-learnings.md (~120 lines) — learnings search protocol, hard gates + triggers
- path-resolution.md (~30 lines) — @ references, relative path resolution
- skill-invocation.md (~25 lines) — always use Skill tool, don't ask permission within skills
- All behavioral/procedural, universally needed, no domain-specific content, no overlap with learnings/skills/personas
- No dead weight, no wiring issues

**Deep dive candidate compilation** (all 3 content types complete):
- Tier 1 (modification-triggered): 1 file (claude-authoring-content-types.md — hub)
- Tier 2 (unreviewed skills/skill-refs/guidelines/personas): 49 files (4 guidelines, 4 personas, 15 skill-refs, 26 skills)
- Tier 3 (unreviewed learnings): 7 files
- Tier 4 (stale skills/skill-refs/personas): 12 files (5 skills, 1 skill-ref, 6 personas)
- Tier 5 (stale learnings): 11 files
- Total: 82 candidates, max guard 30 → top 30 listed in Deep Dive Status
- Remaining 52 carry over to future runs (staleness increases naturally)
