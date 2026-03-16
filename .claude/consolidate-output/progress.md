# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 13 |
| ROUND | 3 |
| CONTENT_TYPE | LEARNINGS |
| ROUND_CLEAN | true |
| CLEAN_ROUND_STREAK | 1 |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_CANDIDATES | claude-authoring-skills.md, api-design.md, skill-platform-portability.md, nextjs.md, react-patterns.md, explore-repo.md, react-frontend.md, platform-engineer.md, code-quality-instincts.md, cross-repo-sync.md, playwright-patterns.md, refactoring-patterns.md, xrpl-patterns.md, xrpl-typescript-fullstack.md, testing-patterns.md, quantum-tunnel-claudes/SKILL.md, agent-prompting.md |
| DEEP_DIVE_COMPLETED | claude-code.md, curation-insights.md, resilience-patterns.md, ci-cd-gotchas.md, git-patterns.md, java-backend.md, claude-config-expert.md |

## Pre-Flight

```
Recent commits: 895c763 Add more learnings, d879ade Extract shared request interaction patterns, 0bc8aad add worktree constraints CLAUDE.md
Learnings files: 56
Skills count: 31
Guidelines files: 4
Persona files: 11
Cadence: stale (0 curation commits in last 5)
Suggested iterations: 20
```

## Content Type Status

### LEARNINGS
- **Sweeps**: 2
- **HIGHs applied**: 0
- **MEDIUMs applied**: 3
- **MEDIUMs blocked**: 0

### SKILLS
- **Sweeps**: 2
- **HIGHs applied**: 0
- **MEDIUMs applied**: 0
- **MEDIUMs blocked**: 0

### GUIDELINES
- **Sweeps**: 2
- **HIGHs applied**: 0
- **MEDIUMs applied**: 0
- **MEDIUMs blocked**: 0

## Round Summary

<!-- Appended at the end of each round -->

| Round | L HIGHs | L MEDs | S HIGHs | S MEDs | G HIGHs | G MEDs | Clean? |
|-------|---------|--------|---------|--------|---------|--------|--------|
| 1 | 0 | 3 | 0 | 0 | 0 | 0 | false |
| 2 | 0 | 0 | 0 | 0 | 0 | 0 | true |

## Iteration Log

<!-- Each iteration appends: | N | Round | CONTENT_TYPE | HIGHs | MEDIUMs | LOWs | Actions | Notes | -->

| Iter | Round | Content Type | HIGHs | MEDIUMs | LOWs | Actions | Notes |
|------|-------|-------------|-------|---------|------|---------|-------|
| 1 | 1 | LEARNINGS | 0 | 3 | 0 | 3 | Moved git workflows section, wired 2 persona refs |
| 2 | 1 | SKILLS | 0 | 0 | 0 | 0 | Clean — 31 skills, 10 clusters, all current |
| 3 | 1 | GUIDELINES | 0 | 0 | 0 | 0 | Clean — 4 files, all @-referenced, no overlap |
| 4 | 2 | LEARNINGS | 0 | 0 | 0 | 0 | Clean — corpus stable after round 1 changes |
| 5 | 2 | SKILLS | 0 | 0 | 0 | 0 | Clean — 31 skills unchanged, no cross-type regressions |
| 6 | 2 | GUIDELINES | 0 | 0 | 0 | 0 | Clean — 4 files unchanged. Round 2 clean → convergence. 24 deep dive candidates identified. |
| 7 | — | DEEP_DIVE | 1 | 0 | 0 | 1 | claude-code.md: deleted duplicate "Worktree Branches Block gh pr checkout". Tracker duplicate key fixed. |
| 8 | — | DEEP_DIVE | 5 | 2 | 0 | 7 | curation-insights.md: deleted 5 duplicate bullets (covered by SKILL.md/classification-model/content-mode), merged Classification Calibration (cont.) into parent, folded Phase 2 into Execution Strategy. 81→70 lines. |
| 9 | — | DEEP_DIVE | 0 | 0 | 0 | 0 | resilience-patterns.md: clean. 4 patterns, all unique standalone references. Cross-refs healthy (bidirectional with financial-applications.md). |
| 10 | — | DEEP_DIVE | 0 | 0 | 0 | 0 | ci-cd-gotchas.md: clean. 19 patterns (6 GH Actions, 12 GitLab, 1 CI Guards), all unique. platform-engineer persona correctly references as proactive load. |
| 11 | — | DEEP_DIVE | 0 | 1 | 1 | 1 | git-patterns.md: 1 MEDIUM (per_page=100→--paginate), 1 LOW (missing See also). 28 patterns verified unique across 6 cross-ref files. |
| 12 | — | DEEP_DIVE | 1 | 0 | 1 | 1 | java-backend.md: 1 HIGH (deleted duplicate gotchas section — both items verbatim in proactive-loaded spring-boot-gotchas.md). 1 LOW (missing refs to java-infosec/observability files). 50→45 lines. |
| 13 | — | DEEP_DIVE | 1 | 0 | 0 | 1 | claude-config-expert.md: 1 HIGH (deleted 2 boundary case lines duplicated from proactive-loaded claude-authoring-content-types.md). 7 gotchas, 13 references all verified. 54→52 lines. |

## Deep Dive Status

<!-- Populated when PHASE transitions to DEEP_DIVE after broad sweep convergence -->

| File | Status | Iter | Summary |
|------|--------|------|---------|
| claude-code.md | done | 7 | 1 HIGH applied (deleted duplicate "Worktree Branches Block gh pr checkout" — fuller version in claude-authoring-skills.md). Tracker duplicate key fixed. |
| curation-insights.md | done | 8 | 5 HIGHs (deleted duplicate bullets covered by SKILL.md, classification-model.md, content-mode.md, deep-dive-methodology.md). 2 MEDIUMs (merged split Classification Calibration section, folded Phase 2 into Execution Strategy). 81→70 lines. |
| resilience-patterns.md | done | 9 | Clean — 4 patterns, all unique. Cross-refs valid (bidirectional with financial-applications.md, inbound from aws-messaging.md). |
| ci-cd-gotchas.md | done | 10 | Clean — 19 patterns across 3 sections, all unique standalone references. 1 LOW thematic match (cancel-in-progress with ci-cd.md — different lookup paths). Cross-refs healthy via companion header + shared naming. |
| git-patterns.md | done | 11 | 1 MEDIUM applied (per_page=100 → --paginate for full fetches). 1 LOW (missing See also — reverse link exists in bash-patterns.md). 28 patterns, all unique. Cross-refs with resolve-conflicts skill verified (complementary, not duplicate). |
| java-backend.md | done | 12 | 1 HIGH applied (deleted "Known gotchas & platform specifics" section — both items near-verbatim in proactive-loaded spring-boot-gotchas.md). 1 LOW (missing references to java-infosec-gotchas.md, java-observability-gotchas.md, java-observability.md). 50→45 lines. |
| claude-config-expert.md | done | 13 | 1 HIGH applied (deleted 2 boundary case lines from Content type placement — near-verbatim of proactive-loaded claude-authoring-content-types.md lines 30-31). All 7 gotchas verified against corpus (condensed tripwires, not duplicates). All 13 detailed references verified (files exist, descriptions accurate). 54→52 lines. |

## Notes for Next Iteration

<!-- Appended each iteration with ### Iter N heading — do not overwrite -->

### Iter 1

**Methodology loaded**: Classification model (6 buckets), persona design (4-section structure, suggestion criteria 3+ files/8+ patterns), curation insights (operational calibration, compression targets, context cost), content type taxonomy (routing table). Key criteria condensed below.

**Classification quick-ref**: Skill candidate (multi-step procedure, invokable, repeatable), Template (reusable structure used by skills), Context for skill (decision criteria), Guideline candidate (behavioral, universal), Standalone reference (useful knowledge, no skill connection), Outdated (superseded/stale). Migration litmus: "Would having this in the target file actually change how I execute?"

**Compression targets**: Provenance notes, compound-time self-assessments, debugging trails, verbose code blocks, redundant structural dividers, stale snapshot numbers.

**LEARNINGS sweep findings**: Corpus is clean after prior runs. No HIGHs found. 3 MEDIUMs auto-applied: (1) moved "Git Workflows" section from ci-cd-gotchas to git-patterns (misplaced content), (2) wired local-dev-seeding into java-backend persona, (3) wired claude-code-hooks into claude-config-expert persona. No compounding needed — all findings were routine applications of existing methodology.

**Per-file quality scan (Polish Opportunities)**:
- `claude-authoring-skills.md` (517 lines) — largest learnings file, covers skill design + execution + polling + reference management. Above 150-line split threshold with 3+ distinct sub-topics. Deep dive candidate for potential split.
- No genericization issues found — prior runs cleaned project-specific content well.
- No compression candidates beyond existing clean state.

**Deep dive tracker**: run_count incremented 8→9. 4 files marked as modified (last_deep_dive_run=0): ci-cd-gotchas, git-patterns, java-backend persona, claude-config-expert persona.

### Iter 2

**SKILLS sweep**: Clean. 31 skills across 10 namespace clusters evaluated. No HIGHs, MEDIUMs, or LOWs.

**Cluster summary**: `do-*` (2), `explore-repo` (2), `extract-request-learnings` (1), `git:*` (10), `learnings:*` (4), `parallel-plan:*` (2), `quantum-tunnel-claudes` (1), `ralph:consolidate:*` (2), `ralph:research:*` (5), standalone (2: session-retro, set-persona).

**Key observations**: No intra-namespace overlap. Skills with similar domains have explicit disambiguation sections. All Co-Authored-By templates use current model version (Opus 4.6). Shared reference files (platform-detection, request-interaction-base, subagent-patterns) properly centralized in skill-references/. No stale references found.

**No compounding needed** — clean sweep, no findings to extract insights from.

### Iter 3

**GUIDELINES sweep**: Clean. 4 files evaluated, all `@`-referenced from CLAUDE.md: communication.md (14 sections, behavioral), skill-invocation.md (2 sections), context-aware-learnings.md (7+ sections, procedural protocol), path-resolution.md (2 sections, operational reference).

**Checks**: No orphaned guidelines, no domain-specific content for persona migration, no duplication with learnings/skills, no compression opportunities that wouldn't degrade teaching quality. CLAUDE.md inline Path Resolution table partially overlaps `path-resolution.md` but serves as complementary quick-reference (5 lines, minimal cost).

**Round 1 complete**: ROUND_CLEAN=false (LEARNINGS found 3 MEDIUMs). CLEAN_ROUND_STREAK stays 0. Advancing to Round 2, CONTENT_TYPE reset to LEARNINGS.

### Iter 4

**LEARNINGS sweep (Round 2)**: Clean. 56 files, all clusters evaluated. Round 1 changes verified: git workflows section in git-patterns.md (correct location), local-dev-seeding wired into java-backend (line 49), claude-code-hooks wired into claude-config-expert (line 53). No concept-name collisions, no new overlaps, no genericization/compression opportunities.

**Deep dive candidates (for when convergence is reached)**:
- Modification-triggered (last_deep_dive_run=0): claude-code.md, curation-insights, resilience-patterns.md, ci-cd-gotchas.md, git-patterns.md, java-backend persona, claude-config-expert persona
- Polish Opportunity: claude-authoring-skills.md (517 lines, 3+ distinct sub-topics — potential split)
- Staleness (run_count 9, threshold 3): api-design (5 behind), skill-platform-portability (4), nextjs (4), react-patterns (4), explore-repo (4), code-quality-instincts (4), cross-repo-sync (4), react-frontend persona (4), platform-engineer persona (4)
- Untracked files: ~30 learnings files not yet in tracker — these fill remaining slots after criteria 1-6 candidates

**Tracker note**: deep-dive-tracker.json has a duplicate key for `.claude/learnings/git-patterns.md` (lines 27 and 42). JSON parser keeps the last entry (last_deep_dive_run=0). Not functionally broken but should be cleaned up during deep dive phase.

### Iter 5

**SKILLS sweep (Round 2)**: Clean. 31 skills across 10 namespace clusters — identical to sweep 2. No skill files modified since last SKILLS sweep. No cross-type regressions from round 1 learnings changes. No compounding needed.

### Iter 6

**GUIDELINES sweep (Round 2)**: Clean. 4 files, all @-referenced, identical to sweep 3. No modifications between sweeps.

**Round 2 complete**: ROUND_CLEAN=true → CLEAN_ROUND_STREAK=1 → **Broad sweeps converged.**

**Deep dive candidates (24 files)**:
- **Modification-triggered** (7): claude-code.md, curation-insights.md, resilience-patterns.md, ci-cd-gotchas.md, git-patterns.md, java-backend persona, claude-config-expert persona
- **Polish Opportunity** (1): claude-authoring-skills.md (517 lines, 3+ distinct sub-topics)
- **Staleness** (16): api-design (5 behind), skill-platform-portability/nextjs/react-patterns/explore-repo/react-frontend/platform-engineer/code-quality-instincts/cross-repo-sync (4 behind), playwright-patterns/refactoring-patterns/xrpl-patterns/xrpl-typescript-fullstack/testing-patterns/quantum-tunnel-claudes/agent-prompting (3 behind)

**Tracker cleanup needed**: git-patterns.md has duplicate key in deep-dive-tracker.json (noted in iter 4). Clean up when deep-diving that file.

### Iter 7

**DEEP DIVE: claude-code.md** (278 lines, 30 patterns). Cross-referenced against multi-agent-patterns.md, claude-code-hooks.md, git-patterns.md, bash-patterns.md, claude-authoring-skills.md.

**1 HIGH applied**: Deleted "Worktree Branches Block `gh pr checkout`" (lines 88-90) — 2-line stub duplicated by fuller version in claude-authoring-skills.md (lines 488-490) which includes detection pattern + skill design recommendations. The skills version also cross-refs back to claude-code.md already.

**Tracker maintenance**: Fixed duplicate key for `.claude/learnings/git-patterns.md` (noted in iter 4). Removed stale entry (value 5), kept modification-triggered entry (value 0).

**No compounding needed** — the deletion was a straightforward dedup, no meta-insight to extract.

### Iter 8

**DEEP DIVE: curation-insights.md** (81 lines, 8 sections). Cross-referenced against SKILL.md (curate), classification-model.md, content-mode.md, deep-dive-methodology.md, claude-authoring-content-types.md, claude-authoring-skills.md, persona-design.md.

**5 HIGHs applied** (all duplicate deletions):
1. Line 39 (`@` refs always-on cost) — near-verbatim duplicate of SKILL.md line 29
2. Line 40 (non-`@` refs selective loading) — near-verbatim duplicate of SKILL.md line 30
3. Line 42 (granular > monolithic files) — near-verbatim duplicate of SKILL.md line 31
4. Line 62 (deep dives bounded/non-cascading) — duplicate of deep-dive-methodology.md + stale "max 5" (now max 30)
5. Line 71 (guidelines must be universal) — duplicate of content-mode.md § 4b + claude-authoring-content-types.md § Evaluating Existing Guidelines

**2 MEDIUMs applied** (structural cleanup):
1. Merged `## Classification Calibration (cont.)` (1 remaining bullet after HIGH deletion) into `## Classification Calibration`
2. Moved `## Phase 2 Patterns` bullet (1 remaining after HIGH deletion) into `## Execution Strategy`, deleted section

**Result**: 81→70 lines. 6 sections (was 8). All remaining content is unique operational calibration not covered by the eagerly-loaded SKILL.md or step-4 reference files.

**No compounding needed** — all actions were dedup/structural cleanup, no novel meta-insight to extract.

### Iter 9

**DEEP DIVE: resilience-patterns.md** (32 lines, 4 patterns). Cross-referenced against financial-applications.md, aws-messaging.md, spring-boot-gotchas.md, java-backend persona.

**Clean** — all 4 patterns are unique standalone references:
1. "Mark items as processed before processing" — application-level dedup, distinct from aws-messaging SQS dedup (infrastructure-level)
2. "Domain-specific exceptions" — distinct from spring-boot-gotchas RuntimeException context (interrupt flag, not domain typing)
3. "Scheduler-decoupled maker/checker" — no matches anywhere in corpus
4. "Stale validation caches" — specific production incident complementing java-backend persona's general principle

**Cross-refs verified**: financial-applications.md bidirectional ✅, aws-messaging.md inbound ✅ (no reverse needed — keyword overlap sufficient for discovery).

**No compounding needed** — clean deep dive, no findings.

### Iter 10

**DEEP DIVE: ci-cd-gotchas.md** (32 lines, 19 patterns across 3 sections). Cross-referenced against ci-cd.md, gitlab-ci-cd.md, platform-engineer persona.

**Clean** — all 19 patterns are unique standalone references:
- GitHub Actions (6 patterns): concurrency, paths-ignore, continue-on-error, minimal permissions, job timeouts, diagnosing failures with `gh run view`
- GitLab CI/CD (12 patterns): rules, needs, cache, artifacts, interruptible, extends, include, protected variables, GIT_DEPTH, allow_failure, environment/review apps, retry
- CI Guards (1 pattern): lightweight API-based guard (pointer to ci-cd.md for YAML)

**1 LOW thematic match**: `cancel-in-progress: true` also appears in ci-cd.md line 15 (CI Pipeline Structure). Different contexts — gotchas is a standalone tripwire checklist item, ci-cd.md embeds it in pipeline design. Both serve distinct lookup paths.

**Cross-refs**: No formal `## See also` but companion header (line 3) links ci-cd.md and gitlab-ci-cd.md. Shared "ci-cd" naming makes keyword discovery reliable — formal cross-refs would add tokens without adding discoverability.

**Persona**: platform-engineer correctly lists ci-cd-gotchas.md as proactive load (line 29).

**No compounding needed** — clean, no findings.

### Iter 11

**DEEP DIVE: git-patterns.md** (231 lines, 28 patterns). Cross-referenced against claude-code.md, bash-patterns.md, process-conventions.md, cross-repo-sync.md, git:resolve-conflicts skill, git:cascade-rebase skill, git:split-commit skill.

**1 MEDIUM applied**: Updated line 182 — `per_page=100` for full fetches replaced with `--paginate`. Three other corpus files (bash-patterns.md, claude-code.md, process-conventions.md) had already converged on `--paginate`; the git-patterns advice was stale.

**1 LOW recorded**: No `## See also` section. bash-patterns.md already has reverse cross-ref (line 161). Forward link would be marginally helpful but not critical for discoverability.

**Verified clean patterns**: Rebase ours/theirs inversion (lines 202-204) matches resolve-conflicts skill line 137 but serves different access pattern (keyword lookup vs in-context operational reference). Merge vs Rebase Token-Cost Heuristic (lines 228-231) extends the skill's decision point with the full 1.5x formula. Cascade Rebase (lines 222-226) complements the cascade-rebase skill (concise reference vs executable procedure). All appropriate separation.

**No compounding needed** — routine stale-advice update, no meta-insight to extract.

### Iter 12

**DEEP DIVE: java-backend.md** (50 lines, persona file). Cross-referenced against spring-boot-gotchas.md (proactive load), spring-boot.md, api-design.md, resilience-patterns.md, financial-applications.md, code-quality-instincts.md, aws-messaging.md, postgresql-query-patterns.md, newman-postman.md, local-dev-seeding.md, process-conventions.md. Also checked java-infosec-gotchas.md, java-observability-gotchas.md, java-observability.md for missing references.

**1 HIGH applied**: Deleted "Known gotchas & platform specifics" section (lines 27-31, 5 lines). Both items (`@Scheduled`+ShedLock exception swallowing, per-item catch in loops) are near-verbatim duplicates of spring-boot-gotchas.md lines 5-6, which is already listed as a proactive load. Persona → 45 lines.

**1 LOW recorded**: Three Java-domain learnings files (java-infosec-gotchas.md, java-observability-gotchas.md, java-observability.md) are not in the persona's reference lists. Keyword discovery via `java-*` naming is reliable, so the gap is marginal.

**All 10 detailed references verified**: All files exist and contain content matching the persona's description annotations. No stale or broken references.

**No compounding needed** — straightforward dedup of proactive-loaded content, no meta-insight to extract.

### Iter 13

**DEEP DIVE: claude-config-expert.md** (54 lines, persona file). Cross-referenced against 12 files: claude-authoring-content-types.md (proactive load), claude-authoring-skills.md, claude-authoring-guidelines.md, claude-authoring-claude-md.md, claude-authoring-personas.md, claude-authoring-learnings.md, claude-code.md, skill-platform-portability.md, code-quality-instincts.md, process-conventions.md, curation-insights.md, claude-code-hooks.md.

**1 HIGH applied**: Deleted 2 boundary case lines from Content type placement section (lines 20-21). "If prescriptive but conditional on domain" and "If a guideline restates what a skill already does by default" are near-verbatim of claude-authoring-content-types.md lines 30-31 (Boundary Cases), which is this persona's proactive load. Same dedup pattern as java-backend iter 12. Persona → 52 lines.

**All 7 Known gotchas verified**: Each is a condensed tripwire with fuller versions in learnings files. Appropriate persona-level condensation — not duplication. Verified against claude-code.md, claude-authoring-skills.md, claude-authoring-personas.md, skill-platform-portability.md.

**All 13 detailed references verified**: All files exist, all description annotations accurately match file content. No stale or broken references. No missing critical references identified.

**No compounding needed** — straightforward dedup of proactive-loaded content, no meta-insight to extract.
