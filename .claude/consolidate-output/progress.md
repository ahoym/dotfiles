# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 12 |
| ROUND | 3 |
| CONTENT_TYPE | LEARNINGS |
| ROUND_CLEAN | true |
| CLEAN_ROUND_STREAK | 1 |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_CANDIDATES | aws-messaging.md, ralph/consolidate/init/SKILL.md, extract-request-learnings/SKILL.md, git/split-commit/SKILL.md, learnings/consolidate/SKILL.md, ralph-loop.md, multi-agent-patterns.md, web-session-sync.md, typescript-devops.md, api-design.md, skill-platform-portability.md, nextjs.md, react-patterns.md, react-frontend.md, explore-repo.md, platform-engineer.md, code-quality-instincts.md, cross-repo-sync.md, git-patterns.md |
| DEEP_DIVE_COMPLETED | claude-authoring-content-types.md, claude-authoring-skills.md, process-conventions.md, bash-patterns.md, claude-authoring-guidelines.md, financial-applications.md |

## Pre-Flight

```
Recent commits: beaef09 Add retro learnings and sync GitLab reference fixes, efb1d0b Update request comments skill and curation, 5769855 Curate claude-code.md: deduplicate, merge, compress, add cross-refs
Learnings files: 56
Skills count: 31
Guidelines files: 4
Persona files: 11
Cadence: moderate (2 curation commits in last 5)
Suggested iterations: 15
```

## Content Type Status

### LEARNINGS
- **Sweeps**: 2
- **HIGHs applied**: 1
- **MEDIUMs applied**: 2
- **MEDIUMs blocked**: 0

### SKILLS
- **Sweeps**: 2
- **HIGHs applied**: 1
- **MEDIUMs applied**: 1
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
| 1 | 1 | 2 | 1 | 1 | 0 | 0 | No |
| 2 | 0 | 0 | 0 | 0 | 0 | 0 | Yes |

**Broad sweeps converged** after Round 2 (CLEAN_ROUND_STREAK = 1). Transitioning to DEEP_DIVE phase.

## Iteration Log

<!-- Each iteration appends: | N | Round | CONTENT_TYPE | HIGHs | MEDIUMs | LOWs | Actions | Notes | -->

| Iter | Round | Content Type | HIGHs | MEDIUMs | LOWs | Actions | Notes |
|------|-------|-------------|-------|---------|------|---------|-------|
| 1 | 1 | LEARNINGS | 1 | 2 | 2 | 3 | Fix misplaced takeaway + merge dup sections in process-conventions.md; reference wiring for financial-applications.md and aws-messaging.md |
| 2 | 1 | SKILLS | 1 | 1 | 0 | 2 | Add missing name frontmatter to 2 skills; update stale skill names in consolidate example table |
| 3 | 1 | GUIDELINES | 0 | 0 | 0 | 0 | Clean — 4 files, all @-referenced, no duplication/drift |
| 4 | 2 | LEARNINGS | 0 | 0 | 0 | 0 | Clean — 56 files, no new duplicates/staleness/regressions from R1 changes |
| 5 | 2 | SKILLS | 0 | 0 | 0 | 0 | Clean — 31 skills, R1 fixes verified, no regressions |
| 6 | 2 | GUIDELINES | 0 | 0 | 0 | 0 | Clean — 4 files, no changes since R1. R2 fully clean → convergence → DEEP_DIVE |
| 7 | — | DEEP_DIVE | 0 | 0 | 0 | 0 | claude-authoring-content-types.md: clean, 11 patterns all standalone reference |
| 8 | — | DEEP_DIVE | 0 | 5 | 1 | 5 | claude-authoring-skills.md: 503→~490 lines, dedup footnote, migrate 2 patterns to multi-agent, add cross-refs |
| 9 | — | DEEP_DIVE | 0 | 3 | 1 | 3 | process-conventions.md: 179→~170 lines, merge 2 near-dup sections, add See also cross-refs |
| 10 | — | DEEP_DIVE | 0 | 3 | 1 | 3 | bash-patterns.md: 180→~162 lines, migrate 2 permission gotchas to claude-code.md, add See also cross-refs |
| 11 | — | DEEP_DIVE | 0 | 3 | 0 | 3 | claude-authoring-guidelines.md: 57→~48 lines, migrate "Uniform Convention" to curation-insights, compress tier separation, add See also |
| 12 | — | DEEP_DIVE | 0 | 2 | 0 | 2 | financial-applications.md: 63→64 lines, add See also cross-refs to resilience-patterns.md (bidirectional) |

## Deep Dive Status

<!-- Populated when PHASE transitions to DEEP_DIVE after broad sweep convergence -->
<!-- Max guard: 15 invocations. Unprocessed candidates carry over to next run. -->

| File | Status | Iter | Summary |
|------|--------|------|---------|
| claude-authoring-content-types.md | done | 7 | Clean — 11 patterns, all standalone reference, hub-spoke boundary clean |
| claude-authoring-skills.md | done | 8 | 5 MEDIUMs applied: footnote dedup, 2 migrations to multi-agent-patterns, See also + reverse cross-ref. 1 LOW (worktree branches placement). |
| process-conventions.md | done | 9 | 3 MEDIUMs applied: 2 intra-file merges (near-duplicate sections), See also cross-refs. 1 LOW (redundant takeaways). |
| bash-patterns.md | done | 10 | 3 MEDIUMs applied: migrate inline-subshell + chaining gotchas to claude-code.md, See also cross-refs. 1 LOW (jq vs python3 placement). |
| claude-authoring-guidelines.md | done | 11 | 3 MEDIUMs applied: migrate "Uniform Convention" to curation-insights.md, compress tier separation (−9 lines), See also cross-refs. |
| financial-applications.md | done | 12 | 2 MEDIUMs applied: See also cross-ref to resilience-patterns.md + reverse cross-ref. 10 patterns all standalone reference, concise (63 lines). |

## Notes for Next Iteration

<!-- Appended each iteration with ### Iter N heading — do not overwrite -->

### Iter 1

**Methodology loaded**: Classification model (6-bucket), confidence levels, persona design (4-section structure, 3+ files / 8+ patterns for new persona suggestion), curation insights (operational calibration, compression targets, phase 2 patterns), content type routing table, broad sweep methodology.

**Key classification criteria**:
- HIGH = clear, unambiguous (rename, misplaced content, exact duplicates)
- MEDIUM auto-apply = reversible, no unique content lost (compression, genericization, dedup, reference wiring, fold thin file)
- MEDIUM block = irreversible or preference-dependent (delete unique content, ambiguous domain tradeoffs)
- LOW = uncertain, multiple valid approaches → review.md

**Corpus state**: 56 learnings, 31 skills, 4 guidelines, 11 personas. Collection is fairly mature — recent curation commits visible. Heading collision detection found no exact cross-file duplicates. Intra-file duplicate found in process-conventions.md (two safeguard-verification sections).

**Findings summary**: 1 HIGH (misplaced takeaway + merge dup sections), 2 MEDIUM auto-applied (reference wiring), 2 LOWs (stale transition note, cross-file duplicate footnote pattern).

**Polish Opportunities** (for deep dive candidacy):
- `claude-authoring-skills.md` (503 lines) — largest file, potential compression/split candidates
- `process-conventions.md` (now ~176 lines, ~25 patterns) — compression candidates in verbose takeaways
- `ralph-loop.md` (230 lines) — check for stale v1 references
- `multi-agent-patterns.md` (296 lines) — large but thematically unified

### Iter 2

**Skills sweep**: 31 skills across 5 namespace clusters (git:10, learnings:4, ralph:7, parallel-plan:2, standalone:8). Also read 11 persona files and 15 skill-reference files.

**Findings**: 1 HIGH (missing `name` frontmatter in extract-request-learnings + git:split-commit), 1 MEDIUM auto-applied (stale skill names in consolidate example table). No stale model version strings. No cross-persona content duplication. No skill overlap warranting merge/prune.

**Corpus health**: Skills collection is well-organized. Namespace clusters are clean with clear boundaries. Shared references are appropriately factored. Extension hierarchy in personas (claude-config-*, java-*) works well with no duplication.

**Modified files added to deep-dive tracker**: extract-request-learnings/SKILL.md, git/split-commit/SKILL.md, learnings/consolidate/SKILL.md

### Iter 3

**Guidelines sweep**: 4 files (communication.md, context-aware-learnings.md, path-resolution.md, skill-invocation.md). All @-referenced from `.claude/CLAUDE.md`. Cross-referenced against 56 learnings, 31 skills, 11 personas.

**Findings**: Clean. No duplicates, no domain-specific content, no dead references, no stale content. `claude-authoring-guidelines.md` in learnings is meta-knowledge about authoring guidelines — distinct from the guidelines themselves.

**Round 1 complete**: Not clean (sweeps 1-2 had findings). CLEAN_ROUND_STREAK stays at 0. Starting Round 2.

### Iter 4

**Round 2 LEARNINGS sweep**: 56 files, all read in parallel. Heading collision detection clean. No regressions from Round 1 changes (process-conventions fix, reference wiring for financial-applications and aws-messaging). No new duplicates, overlaps, stale content, genericization issues, or compression targets at broad sweep level.

**Deep dive candidates** (recording for convergence check):
- **Modified files (last_deep_dive_run=0)**: process-conventions.md, financial-applications.md, aws-messaging.md, bash-patterns.md, claude-authoring-skills.md, claude-authoring-guidelines.md, extract-request-learnings/SKILL.md, git/split-commit/SKILL.md, learnings/consolidate/SKILL.md, ralph/init/SKILL.md
- **Stale tracked files (delta >= 3)**: web-session-sync.md, ralph-loop.md, api-design.md, skill-platform-portability.md, nextjs.md, react-patterns.md, code-quality-instincts.md, cross-repo-sync.md, git-patterns.md, explore-repo.md, react-frontend.md (persona), platform-engineer.md (persona), typescript-devops.md (persona)
- **Polish Opportunities**: claude-authoring-skills.md (503 lines), multi-agent-patterns.md (296 lines), ralph-loop.md (230 lines), process-conventions.md (178 lines)
- **Cross-reference hub**: claude-authoring-content-types.md (referenced by classification-model, curation-insights, and 4+ authoring spoke files)

### Iter 5

**Round 2 SKILLS sweep**: 31 skills, 11 personas, 15 skill-references. All read in parallel. Verified Round 1 fixes (name frontmatter on extract-request-learnings + split-commit, consolidate example table update). No new issues — no overlap, no stale references, no scope problems. All namespace clusters clean.

**Next**: GUIDELINES sweep (Round 2). If clean → CLEAN_ROUND_STREAK = 1 → convergence → deep dive candidacy check.

### Iter 6

**Round 2 GUIDELINES sweep**: 4 files, all @-referenced from CLAUDE.md. Cross-referenced against learnings, skills, personas. No duplicates, no domain-specific content, no dead references, no compression targets. Clean.

**Round 2 complete**: All 3 sweeps clean → ROUND_CLEAN=true → CLEAN_ROUND_STREAK=1 → **broad sweeps converged**.

**Deep dive candidacy compiled**: 25 candidates prioritized:
- **Modification-triggered (11)**: 10 files with last_deep_dive_run=0 (bash-patterns, claude-authoring-skills, claude-authoring-guidelines, process-conventions, financial-applications, aws-messaging, ralph/consolidate/init, extract-request-learnings, git/split-commit, learnings/consolidate) + 1 cross-reference hub (claude-authoring-content-types)
- **Polish Opportunities (2 additional)**: ralph-loop (230 lines, delta=4), multi-agent-patterns (296 lines, delta=2)
- **Stale (12 additional, delta >= 3)**: web-session-sync, typescript-devops, api-design (delta=4); skill-platform-portability, nextjs, react-patterns, react-frontend, explore-repo, platform-engineer, code-quality-instincts, cross-repo-sync, git-patterns (delta=3)

**Tracker note**: Entry `.claude/commands/ralph/init/SKILL.md` doesn't match any actual file — actual paths are `ralph/consolidate/init/SKILL.md` and `ralph/research/init/SKILL.md`. Corrected in candidate list to `ralph/consolidate/init/SKILL.md`.

**Next**: Deep dive phase. Max guard = 5 invocations.

### Iter 7

**Deep dive: claude-authoring-content-types.md** (cross-reference hub file). 122 lines, 11 patterns. All classified standalone reference / HIGH / keep. Hub-spoke boundary verified clean — 5 spoke files (skills, guidelines, learnings, personas, claude-md) all exist with accurate descriptions. No duplication between hub and spokes. No stale references. No compression targets (file is already concise). No `## See also` section, but the "Authoring Guides (per-type)" routing section serves the same discovery function for spoke files.

**Next**: claude-authoring-skills.md (503 lines — largest file, likely has compression/split candidates).

### Iter 8

**Deep dive: claude-authoring-skills.md** (largest file, 503→~490 lines, ~64 patterns). Cross-referenced against process-conventions.md, multi-agent-patterns.md, claude-code.md, claude-authoring-content-types.md, claude-authoring-guidelines.md, skill-platform-portability.md, and 4 skill-reference files.

**Actions taken (5 MEDIUMs):**
- Compressed "Structured Footnote for External Platform Posts" — replaced duplicate template with pointer to process-conventions.md, kept unique composite-key filtering instruction. Resolves [L-2].
- Migrated "Mutual Agreement Auto-Implementation" and "Agent-to-Agent Review Cycle" to multi-agent-patterns.md — these describe multi-agent collaboration architecture, not skill design.
- Added `## See also` with 5 cross-refs to hub, siblings, and related files.
- Added reverse cross-ref in multi-agent-patterns.md back to this file.

**1 LOW recorded** — "Worktree Branches Block `gh pr checkout`" straddles skill design instruction and platform gotcha. [L-3].

**Remaining patterns (~62) are standalone reference / keep.** File is still the largest at ~490 lines but patterns are predominantly unique skill design knowledge with no further dedup or migration targets. The file would benefit from subsection-level compression in a future pass but nothing rises to MEDIUM confidence for autonomous action.

**Next**: process-conventions.md (next in DEEP_DIVE_CANDIDATES).

### Iter 9

**Deep dive: process-conventions.md** (179→~170 lines, ~30 patterns). Cross-referenced against code-quality-instincts.md, git-patterns.md, multi-agent-patterns.md, claude-authoring-content-types.md, and 4 skill reference files (request-reply-templates, request-lgtm-verification, re-review-mode, address-request-edge-cases).

**Actions taken (3 MEDIUMs):**
- Merged "Remove cross-cutting concerns to separate PRs" into "Scope MRs tightly" — same principle, specific instance folded into parent.
- Merged "Track organizational debt via issues before fixing" into "Defer large cross-cutting refactors" — both say "file an issue first," folded traceability insight.
- Added `## See also` with 2 cross-refs: multi-agent-patterns.md (references structured footnote from here) and code-quality-instincts.md (complementary code vs process quality).

**1 LOW recorded** — redundant takeaway lines rephrase their headings without adding insight. Small per-pattern savings, file not a compression priority. [L-4].

**Remaining ~28 patterns are standalone reference / keep.** Many patterns relate to review skills (address-request-comments, code-review-request) but don't duplicate — learnings teach principles, skill references provide implementation templates.

**Next**: bash-patterns.md (next in DEEP_DIVE_CANDIDATES).

### Iter 10

**Deep dive: bash-patterns.md** (180→~162 lines, 11→9 patterns). Cross-referenced against claude-code.md (244 lines, "Bash Permission Prefix Matching Gotchas"), git-patterns.md (225 lines, GitHub API patterns), and CLAUDE.md Bash Tool section.

**Actions taken (3 MEDIUMs):**
- Migrated "Inline `$()` Subshells Trigger Permission Prompts" to claude-code.md § "Bash Permission Prefix Matching Gotchas" as point 6. Permission system behavior, not bash language pattern.
- Migrated "Separate `git add` and `git commit` to Avoid Permission Rejection" to same section as point 5. Same reasoning — `&&` chaining breaks prefix matching.
- Added `## See also` with 2 cross-refs: claude-code.md (permission gotchas complement bash patterns) and git-patterns.md (GitHub API patterns, git scripting).

**1 LOW recorded** — "Use jq Instead of python3" straddles bash best practice and Claude Code permission workaround. Both framings valid. [L-5].

**Tracker note**: claude-code.md received migrated content → set last_deep_dive_run=0 (modified, needs future deep dive).

**Next**: claude-authoring-guidelines.md (next in DEEP_DIVE_CANDIDATES). Deep dive invocation #5 (max guard = 15).

### Iter 11

**Deep dive: claude-authoring-guidelines.md** (57→~48 lines, 7→6 patterns). Cross-referenced against claude-authoring-content-types.md (hub), claude-authoring-skills.md (sibling), curation-insights.md (migration target), and 2 persona files (claude-config-expert, claude-config-reviewer).

**Actions taken (3 MEDIUMs):**
- Migrated "Uniform Convention Over Case-by-Case Optimization" to curation-insights.md § "Classification Calibration (cont.)." Curation philosophy pattern, not guideline-specific — applies to any structural decision (personas, learnings, skills).
- Compressed "Three-Tier Guideline Separation" to "Pseudocode at the Universal Tier" (3 lines → 2 lines). Tier structure already in content-types.md § "Universal vs Language-Specific" + "Evaluating Existing Guidelines." Kept only unique insight: pseudocode examples at universal tier. Removed redundant takeaway line.
- Added `## See also` with 3 cross-refs: hub (content-types.md), sibling (skills.md), and migration target (curation-insights.md).

**Tracker note**: curation-insights.md received migrated content → added to tracker with last_deep_dive_run=0.

**Next**: financial-applications.md (next in DEEP_DIVE_CANDIDATES). Deep dive invocation #6.

### Iter 12

**Deep dive: financial-applications.md** (63→64 lines, 10 patterns). Cross-referenced against bignumber-financial-arithmetic.md (existing See also), api-design.md (idempotency overlap — keyword-discoverable, not cross-ref'd), resilience-patterns.md (error handling/correctness themes — non-obvious vocabulary connection).

**Actions taken (2 MEDIUMs):**
- Added `resilience-patterns.md` to See also — dedup-before-process, domain-typed exceptions, stale-cache correctness patterns complement financial-applications's "fail loudly" and "never default to zero" error handling. Non-obvious from vocabulary.
- Added reverse cross-ref: new See also section in resilience-patterns.md → financial-applications.md.

**All 10 patterns classified standalone reference / keep.** File is concise (~6 lines/pattern average), well-scoped to financial domain, no duplicates across corpus, no compression or genericization candidates.

**Tracker**: financial-applications.md → last_deep_dive_run=8. resilience-patterns.md added with last_deep_dive_run=0 (received new See also section).

**Next**: aws-messaging.md (next in DEEP_DIVE_CANDIDATES). Deep dive invocation #7.
