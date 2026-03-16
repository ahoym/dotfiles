# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 20 |
| ROUND | 3 |
| CONTENT_TYPE | LEARNINGS |
| ROUND_CLEAN | true |
| CLEAN_ROUND_STREAK | 1 |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_CANDIDATES | platform-engineer.md, code-quality-instincts.md, cross-repo-sync.md, playwright-patterns.md, refactoring-patterns.md, xrpl-patterns.md, xrpl-typescript-fullstack.md, testing-patterns.md, quantum-tunnel-claudes/SKILL.md, agent-prompting.md |
| DEEP_DIVE_COMPLETED | claude-code.md, curation-insights.md, resilience-patterns.md, ci-cd-gotchas.md, git-patterns.md, java-backend.md, claude-config-expert.md, claude-authoring-skills.md, api-design.md, skill-platform-portability.md, nextjs.md, react-patterns.md, explore-repo.md, react-frontend.md |

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
| 14 | — | DEEP_DIVE | 1 | 1 | 1 | 2 | claude-authoring-skills.md: 1 HIGH (stale cross-ref to deleted claude-code.md pattern), 1 MEDIUM (compressed 2 near-duplicate subsections). 1 LOW (split candidate). 518→510 lines. |
| 15 | — | DEEP_DIVE | 0 | 1 | 1 | 1 | api-design.md: 1 MEDIUM (5 ### headings promoted to ## — independent patterns, not subsections). 1 LOW (missing See also). 14 patterns verified unique. |
| 16 | — | DEEP_DIVE | 0 | 0 | 1 | 0 | skill-platform-portability.md: clean. 22 patterns verified unique across claude-authoring-skills.md, claude-code.md, multi-agent-patterns.md, claude-config-expert.md. 1 LOW (missing See also). |
| 17 | — | DEEP_DIVE | 0 | 0 | 2 | 0 | nextjs.md: clean. 7 patterns verified unique across react-frontend-gotchas.md, react-patterns.md, testing-patterns.md, xrpl-typescript-fullstack, react-frontend personas. 2 LOWs (misplaced TypeScript pattern, missing See also). |
| 18 | — | DEEP_DIVE | 0 | 0 | 1 | 0 | react-patterns.md: clean. 10 patterns verified unique across react-frontend-gotchas.md, reactive-data-patterns.md, refactoring-patterns.md, testing-patterns.md, playwright-patterns.md, ui-patterns.md, code-quality-instincts.md. 1 LOW (missing See also). |
| 19 | — | DEEP_DIVE | 0 | 0 | 1 | 0 | explore-repo.md: clean. 15 patterns verified unique across multi-agent-patterns.md, claude-authoring-skills.md, claude-code.md, skill-platform-portability.md, claude-authoring-content-types.md. 1 LOW (missing See also). |
| 20 | — | DEEP_DIVE | 2 | 0 | 0 | 2 | react-frontend.md: deleted React 19 gotchas (3 bullets) and Playwright gotchas (5 bullets) — all near-verbatim of proactive load react-frontend-gotchas.md. 8 detailed refs verified. 65→55 lines. |

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
| claude-authoring-skills.md | done | 14 | 1 HIGH (updated stale cross-ref — "platform gotcha angle" pointed to pattern deleted in iter 7, updated to "worktree platform mechanics"). 1 MEDIUM (compressed "Context budget" + "Skill conversion signal" into single "Guideline-to-skill conversion signal" — near-identical takeaways, overlap with content-types.md). 1 LOW (510 lines, split candidate for polling/review cluster). 518→510 lines. |
| api-design.md | done | 15 | 1 MEDIUM (promoted 5 independent patterns from ### to ## — were orphaned subsection headings under "Centralize Error Maps"). 1 LOW (missing See also — keyword overlap sufficient for discovery). 14 patterns, all unique across 10 cross-ref files. |
| skill-platform-portability.md | done | 16 | Clean — 22 patterns (platform features, frontmatter, agents, plugins, cross-platform compat), all unique. 1 LOW (missing See also — reverse ref exists in claude-authoring-skills.md). |
| nextjs.md | done | 17 | Clean — 7 patterns (proxy.ts, async params, Turbopack, rate limiter, testing cross-ref, union types), all unique. Hub/spoke with react-frontend-gotchas.md verified correct. 2 LOWs (misplaced TS pattern, missing See also). |
| react-patterns.md | done | 18 | Clean — 10 patterns (React 19 setState/useEffect, hydration mismatch, circular hook deps, modal timing, refreshKey, page decomposition, two-tier hooks, polling visibility, per-env state), all unique. Companion hub/spoke with react-frontend-gotchas.md verified correct. 1 LOW (missing See also). |
| explore-repo.md | done | 19 | Clean — 15 patterns (parallel exploration, repo learnings structure, synthesis context budget, subdirectory CLAUDE.md heuristic, cross-domain dedup, staleness detection, scan inconsistencies, language-specific mapping, @-include guidance, PROJECT_CONTEXT hints, inconsistencies.md, single-pass synthesis, greenfield CLAUDE.md, auto-fix strategy, cross-reference graph), all unique. 1 LOW (missing See also). |
| react-frontend.md | done | 20 | 2 HIGHs applied (deleted React 19 gotchas subsection — 3 bullets near-verbatim of proactive load react-frontend-gotchas.md lines 7-9; deleted Playwright gotchas subsection — 5 bullets near-verbatim of proactive load react-frontend-gotchas.md lines 22-26). All 8 detailed references verified (files exist, descriptions accurate). 65→55 lines. |

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

### Iter 14

**DEEP DIVE: claude-authoring-skills.md** (518 lines, 70+ patterns — largest learnings file). Cross-referenced against skill-platform-portability.md, claude-authoring-content-types.md, multi-agent-patterns.md, process-conventions.md, subagent-patterns.md, agent-prompting.md, claude-code.md (via worktree patterns).

**1 HIGH applied**: Updated stale cross-reference on line 490. Original: "See also: `claude-code.md` for the platform gotcha angle" — the specific "Worktree Branches Block" pattern it referenced was deleted from claude-code.md in iter 7. Updated to "for worktree platform mechanics" since claude-code.md still has extensive worktree content (isolation, permissions, CWD pinning).

**1 MEDIUM applied**: Compressed "Guidelines-to-Skills Migration" subsections 1 ("Context budget drives guideline-to-skill conversion") and 2 ("Skill conversion signal: procedural workflows with clear triggers") into a single "Guideline-to-skill conversion signal" entry. Rationale: near-identical takeaways ("do X when triggered = skill"), significant overlap with claude-authoring-content-types.md Quick Decision Tree and Guideline Scoping table. 12 lines → 4 lines.

**1 LOW recorded**: File is 510 lines with 70+ patterns. Polling/review cluster (lines ~400-500) is the most distinct sub-topic for potential split. But all patterns share the "skill" keyword for lookup, so splitting has marginal discoverability benefit.

**Verified clean**: All remaining ~68 patterns are unique standalone references. No duplicates with skill-platform-portability.md (clean hub/spoke separation), multi-agent-patterns.md (different access patterns), or process-conventions.md (complementary content). All 4 See also cross-references verified valid and bidirectional.

**No compounding needed** — the stale cross-ref fix and compression are routine maintenance, no meta-insight to extract.

### Iter 15

**DEEP DIVE: api-design.md** (111 lines, 14 patterns). Cross-referenced against financial-applications.md, testing-patterns.md, code-quality-instincts.md, aws-messaging.md, spring-boot.md, refactoring-patterns.md, resilience-patterns.md, python-specific.md, xrpl-patterns.md, xrpl-dex-data.md. Persona references checked: java-backend (line 35), xrpl-typescript-fullstack (line 75).

**1 MEDIUM applied**: Promoted 5 independent patterns (lines 86-110) from `###` to `##` heading level. These patterns (token-derived identifiers, REST paths, integration client errors, API completeness, idempotency keys, correlation IDs) are not subsections of "Centralize Error Maps" — they're independent top-level entries that were incorrectly nested. Consistent heading structure improves keyword lookup.

**1 LOW recorded**: No `## See also` section. Related files (financial-applications.md, testing-patterns.md, code-quality-instincts.md) are discoverable via keyword overlap ("idempotency", "validator"). python-specific.md already has inbound cross-ref (line 30).

**Verified clean**: All 14 patterns unique. Idempotency patterns at 3 different levels across corpus (client parameter passing here, business/infra alignment in financial-applications.md, dedup window in aws-messaging.md). Validator patterns in different languages/contexts (TypeScript/Next.js here, Java in spring-boot.md, general strategy in refactoring-patterns.md, testing in testing-patterns.md). No genericization issues — all examples use generic types.

**No compounding needed** — heading level fix is routine formatting, no meta-insight to extract.

### Iter 16

**DEEP DIVE: skill-platform-portability.md** (220 lines, 22 patterns). Cross-referenced against claude-authoring-skills.md (510 lines), claude-code.md (274 lines), multi-agent-patterns.md (304 lines), claude-config-expert.md (52 lines, persona).

**Clean** — all 22 patterns are unique standalone references:
- Platform equivalence (`commands/` vs `skills/`), unused frontmatter features, `disable-model-invocation` context removal, intent-signaling for broken features — all unique platform knowledge
- Progressive Disclosure tiers, Dynamic Context Injection (`!command`), evaluation framework — not in any cross-ref file
- `context: fork` vs Task Subagents + Viability Checklist — unique isolation comparison, multi-agent-patterns.md covers different patterns
- Custom Agent Definitions + `memory:` field — not in multi-agent-patterns.md or claude-code.md
- Plugin sections (caching, settings, namespace flattening, validator rejection) — unique domain
- Cross-platform sections (field handling, `$ARGUMENTS`, `metadata.*`, `compatibility`) — unique

**1 LOW recorded**: No `## See also` section. claude-authoring-skills.md line 507 already has reverse reference. Keyword overlap sufficient.

**No compounding needed** — clean deep dive, no findings.

### Iter 17

**DEEP DIVE: nextjs.md** (91 lines, 7 patterns). Cross-referenced against react-frontend-gotchas.md, react-patterns.md, testing-patterns.md, xrpl-typescript-fullstack persona, react-frontend persona.

**Clean** — all 7 patterns are unique standalone references:
1. Next.js 16 middleware→proxy migration (lines 3-26) — full recipe; react-frontend-gotchas.md line 13 has condensed tripwire (correct hub/spoke)
2. Dynamic Route Params async (lines 28-47) — full code examples; condensed versions in gotchas + personas (different access patterns)
3. Turbopack Gotchas (lines 49-61) — 3 sub-items; condensed in gotchas file (correct)
4. Rate Limiter Wiring (lines 63-80) — full pattern with code; condensed in gotchas (correct)
5. Testing Route Handlers Directly (lines 82-84) — appropriate 2-line cross-ref to testing-patterns.md § Route Handler Test Structure
6. Extending a Union Type Used in Record Keys (lines 86-91) — generic TypeScript pattern

**2 LOWs recorded**:
- "Extending a Union Type Used in Record Keys" is a generic TypeScript pattern not specific to Next.js. Marginal misplacement — discoverable via current file.
- No `## See also` section. Both personas (react-frontend, xrpl-typescript-fullstack) reference nextjs.md. react-frontend-gotchas.md companion header references react-patterns.md (sibling). Keyword overlap sufficient.

**No compounding needed** — clean deep dive, no findings.

### Iter 18

**DEEP DIVE: react-patterns.md** (225 lines, 10 patterns). Cross-referenced against react-frontend-gotchas.md (companion), reactive-data-patterns.md, refactoring-patterns.md, testing-patterns.md, playwright-patterns.md, ui-patterns.md, code-quality-instincts.md. Persona references checked: react-frontend (line 58), xrpl-typescript-fullstack (line 65).

**Clean** — all 10 patterns are unique standalone references:
1. React 19 No setState in useEffect (3 sub-patterns) — full recipes; gotchas lines 7,9 have condensed tripwires (correct hub/spoke)
2. Hydration Mismatch with localStorage — full pattern; gotchas line 8 has tripwire (correct)
3. Circular Dependency When Extracting Hooks — unique, no matches elsewhere
4. Don't Unmount Modals Immediately — timing pattern; playwright-patterns.md covers different domain
5. Modal Execution Ownership — unique callback/ownership pattern
6. Per-Iteration refreshKey Bump — complements reactive-data-patterns.md (different mechanism)
7. Large Pages: Decompose into Sub-Components — React-specific decomposition rules
8. Audit Before Abstracting: Two-Tier Hook Design — React-specific; refactoring-patterns.md has general methodology (complementary)
9. Polling with Page Visibility Gating — visibility-gated polling; reactive-data-patterns.md covers event-driven refresh (complementary)
10. Per-Environment Frontend State with Migration — unique localStorage per-env pattern

**1 LOW recorded**: No `## See also` section. Companion header in react-frontend-gotchas.md already references react-patterns.md. Both personas list it. Keyword overlap sufficient.

**No compounding needed** — clean deep dive, no findings.

### Iter 19

**DEEP DIVE: explore-repo.md** (148 lines, 15 patterns). Cross-referenced against multi-agent-patterns.md, claude-authoring-skills.md, claude-code.md, skill-platform-portability.md, claude-authoring-content-types.md. No personas reference this file.

**Clean** — all 15 patterns are unique standalone references. Each pattern has related content in multi-agent-patterns.md (synthesis architecture, output file naming, structural context, scan inconsistencies) but at different granularity — multi-agent covers general principles, explore-repo covers the specific application to repo exploration. No duplication.

**1 LOW recorded**: No `## See also` section. Inbound cross-ref from claude-authoring-skills.md line 38. Keyword overlap sufficient.

**No compounding needed** — clean deep dive, no findings.

### Iter 20

**DEEP DIVE: react-frontend.md** (65 lines, persona file). Cross-referenced against react-frontend-gotchas.md (proactive load), react-patterns.md, playwright-patterns.md, accessibility-patterns.md, nextjs.md, reactive-data-patterns.md, ui-patterns.md, testing-patterns.md, code-quality-instincts.md.

**2 HIGHs applied** (both proactive-load dedup — same pattern as java-backend iter 12, claude-config-expert iter 13):
1. Deleted "### React 19" subsection (lines 34-37, 3 bullets) — all near-verbatim of proactive load react-frontend-gotchas.md lines 7-9
2. Deleted "### Playwright" subsection (lines 42-47, 5 bullets) — all near-verbatim of proactive load react-frontend-gotchas.md lines 22-26

**Kept**: "### Next.js 16 / Turbopack" pointer (line 40) — cross-reference to nextjs.md, not duplicated content. "When reviewing or writing code" section (lines 12-20) — lens content (what to flag during review), distinct from gotchas file's factual tripwires.

**All 8 detailed references verified**: code-quality-instincts.md, react-patterns.md, reactive-data-patterns.md, nextjs.md, accessibility-patterns.md, ui-patterns.md, testing-patterns.md, playwright-patterns.md — all exist, descriptions accurate.

**No compounding needed** — proactive-load dedup is a well-established pattern (3rd occurrence), no novel meta-insight to extract.
