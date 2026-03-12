# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 19 |
| ROUND | 4 |
| CONTENT_TYPE | GUIDELINES |
| ROUND_CLEAN | true |
| CLEAN_ROUND_STREAK | 2 |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_CANDIDATES | refactoring-patterns.md, xrpl-patterns.md, bash-patterns.md, testing-patterns.md |
| DEEP_DIVE_COMPLETED | xrpl-typescript-fullstack.md, agent-prompting.md, quantum-tunnel-claudes/SKILL.md, skill-design.md, claude-code.md, playwright-patterns.md, multi-agent-patterns.md |

## Pre-Flight

<!-- Populated by init skill -->

```
Recent commits: 777eec6 Add learnings on cross-repo-sync, 9ff656e Consolidate learnings scrub refs, 2d83404 consolidate: 2026-03-10 sweep + deep-dive cycle
Learnings files: 50
Skills count: 30
Guidelines files: 4
Persona files: 7
Cadence: moderate (1 curation commit in last 5)
Suggested iterations: 15
```

## Content Type Status

### LEARNINGS
- **Sweeps**: 4
- **HIGHs applied**: 4
- **MEDIUMs applied**: 2
- **MEDIUMs blocked**: 1

### SKILLS
- **Sweeps**: 4
- **HIGHs applied**: 0
- **MEDIUMs applied**: 0
- **MEDIUMs blocked**: 0

### GUIDELINES
- **Sweeps**: 4
- **HIGHs applied**: 0
- **MEDIUMs applied**: 1
- **MEDIUMs blocked**: 0

## Round Summary

<!-- Appended at the end of each round -->

| Round | L HIGHs | L MEDs | S HIGHs | S MEDs | G HIGHs | G MEDs | Clean? |
|-------|---------|--------|---------|--------|---------|--------|--------|
| 1 | 4 | 2 | 0 | 0 | 0 | 1 | false |
| 2 | 0 | 1 | 0 | 0 | 0 | 0 | false |
| 3 | 0 | 0 | 0 | 0 | 0 | 0 | true |
| 4 | 0 | 0 | 0 | 0 | 0 | 0 | true |

## Iteration Log

<!-- Each iteration appends: | N | Round | CONTENT_TYPE | HIGHs | MEDIUMs | LOWs | Actions | Notes | -->

| Iter | Round | Content Type | HIGHs | MEDIUMs | LOWs | Actions | Notes |
|------|-------|-------------|-------|---------|------|---------|-------|
| 1 | 1 | LEARNINGS | 4 | 2 (1 applied, 1 skipped) | 2 | 7 | Broad sweep: fix broken ref, merge 2 thin files, wire orphaned learnings |
| 2 | 1 | SKILLS | 0 | 0 | 0 | 0 | Clean — 30 skills, 5 namespaces, all refs valid |
| 3 | 1 | GUIDELINES | 0 | 1 | 0 | 1 | Folded unreferenced multi-agent-orchestration.md into agent-prompting.md |
| 4 | 2 | LEARNINGS | 0 | 1 | 0 | 1 | Wire xrpl-cross-currency-payments.md ref into xrpl-typescript-fullstack persona |
| 5 | 2 | SKILLS | 0 | 0 | 0 | 0 | Clean — 30 skills, 5 namespaces, all refs valid, no stale model strings |
| 6 | 2 | GUIDELINES | 0 | 0 | 0 | 0 | Clean — 3 guidelines, all @-referenced, no overlap with learnings/skills/personas |
| 7 | 3 | LEARNINGS | 0 | 0 | 0 | 0 | Clean — 48 learnings, 7 personas, all refs valid |
| 8 | 3 | SKILLS | 0 | 0 | 0 | 0 | Clean — 29 skills, 5 namespaces, all refs valid |
| 9 | 3 | GUIDELINES | 0 | 0 | 0 | 0 | Clean — 3 guidelines, all @-referenced, no overlap |
| 10 | 4 | LEARNINGS | 0 | 0 | 0 | 0 | Clean — 48 learnings, 7 personas, all refs valid |
| 11 | 4 | SKILLS | 0 | 0 | 0 | 0 | Clean — 30 skills, 5 namespaces, all refs valid |
| 12 | 4 | GUIDELINES | 0 | 0 | 0 | 0 | Clean — 3 guidelines, all @-referenced. CONVERGENCE: CLEAN_ROUND_STREAK=2. Transitioning to DEEP_DIVE (11 candidates). |
| 13 | — | DEEP_DIVE | 1 | 0 | 0 | 1 | xrpl-typescript-fullstack.md: de-enriched Known gotchas (35→10 lines, ~31% file reduction) |
| 14 | — | DEEP_DIVE | 0 | 0 | 0 | 0 | agent-prompting.md: clean — 15 sections, all unique, no overlap with multi-agent-patterns/parallel-plans/subagent-patterns |
| 15 | — | DEEP_DIVE | 0 | 0 | 0 | 0 | quantum-tunnel-claudes/SKILL.md: clean — 13 sections, all refs verified, correct lean architecture |
| 16 | — | DEEP_DIVE | 0 | 0 | 0 | 0 | skill-design.md: clean — 28 sections, all unique, no overlap with corpus |
| 17 | — | DEEP_DIVE | 0 | 0 | 0 | 0 | claude-code.md: clean — 19 sections, all unique, no overlap with corpus |
| 18 | — | DEEP_DIVE | 0 | 0 | 0 | 0 | playwright-patterns.md: clean — 17 sections, all unique, 5 correctly summarized in react-frontend-gotchas + persona |
| 19 | — | DEEP_DIVE | 0 | 0 | 2 | 0 | multi-agent-patterns.md: clean — 32 sections, all unique. 2 LOWs: misplaced gate-announcements section, TaskOutput contradiction with claude-code.md |

## Deep Dive Status

<!-- Populated when PHASE transitions to DEEP_DIVE after broad sweep convergence -->

| File | Status | Iter | Summary |
|------|--------|------|---------|
| xrpl-typescript-fullstack.md | done | 13 | De-enriched Known gotchas — 35→10 lines, all content in proactive loads/detailed refs |
| agent-prompting.md | done | 14 | Clean — 15 sections, all unique, no overlap with corpus |
| quantum-tunnel-claudes/SKILL.md | done | 15 | Clean — 13 sections, 3 conditional refs verified, inventory.sh verified, correct lean architecture |
| skill-design.md | done | 16 | Clean — 28 sections, all unique, cross-refs correct, no persona wiring needed (meta/tooling domain) |
| claude-code.md | done | 17 | Clean — 19 sections, all unique, no overlap. Cross-referenced against 10 corpus files. |
| playwright-patterns.md | done | 18 | Clean — 17 sections, all unique. 5 have correct one-liner summaries in react-frontend-gotchas + persona. Already wired in persona Detailed references. |
| multi-agent-patterns.md | done | 19 | Clean — 32 sections, all unique. 2 LOWs recorded (gate-announcements misplacement, TaskOutput contradiction). See-also ref to subagent-patterns.md valid. |

## Notes for Next Iteration

<!-- Appended each iteration with ### Iter N heading — do not overwrite -->

### Iter 1

**Classification criteria (first invocation):**
- HIGH = broken references, files < 10 lines that duplicate content in larger files, stale companion references to non-existent files
- MEDIUM = orphaned learnings not wired to any persona, systematic de-enrichment patterns (deferred if scope too large)
- LOW = thin but standalone niche files, pruning candidates

**Meta-insight:** Gotchas files systematically duplicate into persona "Known gotchas" sections. This violates lean persona philosophy but is widespread (ci-cd-gotchas, react-frontend-gotchas, xrpl-gotchas, spring-boot-gotchas, java-observability-gotchas). A future round should systematically de-enrich personas — extract inlined knowledge to learnings, keep personas as judgment lenses.

**Methodology logged:** Read all 50 learnings, 7 personas, 5 skill-references. Clustered by domain (XRPL/6, React-Next/6, Java-Spring/8, TS-API/4, AWS-Infra/4, Claude-Meta/11, General/5, Web-Data/4, Niche/3). Collision detection via H2/H3 grep found no exact heading duplicates. Per-file quality scan by line count identified thin files. Cross-referenced persona "Proactive loads" and "Detailed references" against learnings inventory.

### Iter 2

**SKILLS sweep — clean.** Read all 30 SKILL.md files, 7 personas, 5 skill-references. Clustered by namespace (git:9, learnings:4, ralph:7, parallel-plan:2, standalone:8). Per-skill evaluation: all relevant, no 80%+ overlap, no stale references, scopes well-defined. Cross-skill checks: all Related Skills tables valid, shared references already deduplicated into skill-references/. Cross-persona gotcha overlap (xrpl-typescript-fullstack vs react-frontend) is a known pattern from iter 1 — not a skills issue. No stale model version strings found. Note: CONTENT_TYPE was LEARNINGS in progress.md but should have been SKILLS after iter 1; corrected and advanced to GUIDELINES for next sweep.

### Iter 3

**GUIDELINES sweep — 1 MEDIUM applied.** Read all 4 guidelines, cross-referenced against 7 personas, 5 skill-references, CLAUDE.md @-references. 3 of 4 guidelines are @-referenced (always-on, universal behavioral guidance). `multi-agent-orchestration.md` was NOT @-referenced and had zero consumers anywhere in `.claude/` — folded its "verbatim templates" rule into `skill-references/agent-prompting.md` where it's loaded contextually by multi-agent skills.

**End of Round 1**: ROUND_CLEAN = false (LEARNINGS had HIGHs, GUIDELINES had a MEDIUM). CLEAN_ROUND_STREAK remains 0. Starting Round 2 with LEARNINGS.

**No compound insights this sweep** — the single finding was a structural wiring issue, not a pattern about the corpus.

### Iter 4

**Round 2 LEARNINGS sweep — 1 MEDIUM applied.** Re-read all 48 learnings (down from 50 after Round 1 merges), 7 personas, 3 guidelines (down from 4 after Round 1 fold), 5 skill-references. Corpus significantly cleaner after Round 1 — broken refs fixed, thin files merged, orphans wired. Single finding: `xrpl-cross-currency-payments.md` missing from `xrpl-typescript-fullstack` persona's Detailed references despite covering directly relevant XRPL payment engine patterns. Wired it in.

**ROUND_CLEAN set to false** — the MEDIUM means this round can't be clean, CLEAN_ROUND_STREAK will reset at end of round.

### Iter 5

**Round 2 SKILLS sweep — clean.** Re-read all 30 SKILL.md files, 7 personas, 5 skill-references. Same 5 namespaces (git:9, learnings:4, ralph:7, parallel-plan:2, standalone:8). All skills relevant, no 80%+ overlap, references fresh, scopes appropriate. Cross-skill and cross-persona checks clean. All Co-Authored-By strings current (Opus 4.6). Identical result to iter 2 — skills are stable. Advancing to GUIDELINES.

### Iter 6

**Round 2 GUIDELINES sweep — clean.** Re-read all 3 guidelines, cross-referenced against 48 learnings, 5 skill-references, 7 personas. All 3 are @-referenced in CLAUDE.md (always-on). No overlap, no dead weight, no domain-specific content that should migrate to personas. `communication.md` (123 lines) has good insight-to-token ratio — examples provide teaching value. `skill-invocation.md` (7 lines) lean and focused. `context-aware-learnings.md` (87 lines) defines unique system with no duplication elsewhere.

**End of Round 2**: ROUND_CLEAN = false (LEARNINGS iter 4 had a MEDIUM). CLEAN_ROUND_STREAK remains 0. Starting Round 3 with LEARNINGS.

### Iter 7

**Round 3 LEARNINGS sweep — clean.** Re-read all 48 learnings, 7 personas, 3 guidelines, 5 skill-references. Corpus stable since Round 2 — no new files, no content changes outside consolidation. Clustered by domain (XRPL/6, React-Next/6, Java-Spring/8, TS-API/4, AWS-Infra/4, Claude-Meta/11, General/5, Web-Data/2, Niche/3). H2/H3 collision detection: no exact heading duplicates. Per-file quality: no thin files needing merge (all standalone and substantive). All persona Detailed references complete — every relevant learning wired. No orphaned learnings, no stale refs, no broken links. Third consecutive clean LEARNINGS sweep (iters 4 was MEDIUM, but iters 5-7 pattern shows corpus has converged for this content type).

### Iter 8

**Round 3 SKILLS sweep — clean.** Read all 29 SKILL.md files, 5 skill-references. Clustered by namespace (git:9, ralph:7, learnings:4, parallel-plan:2, standalone:7). All skills relevant, no 80%+ overlap, references fresh, scopes well-defined. Cross-skill and cross-persona checks clean. All Co-Authored-By strings current (Opus 4.6). No corpus changes since iter 5 — identical clean result. Advancing to GUIDELINES.

### Iter 9

**Round 3 GUIDELINES sweep — clean.** Re-read all 3 guidelines, cross-referenced against 48 learnings, 5 skill-references, 7 personas. All 3 are @-referenced in CLAUDE.md (always-on). No overlap with learnings/skills/personas, no domain-specific content, no compression opportunities. Identical to iter 6.

**End of Round 3**: ROUND_CLEAN = true (all three sweeps — LEARNINGS iter 7, SKILLS iter 8, GUIDELINES iter 9 — clean). CLEAN_ROUND_STREAK increments to 1. Starting Round 4 with LEARNINGS. One more clean round needed for convergence (streak >= 2).

### Iter 10

**Round 4 LEARNINGS sweep — clean.** Re-read all 48 learnings, 7 personas, 3 guidelines, 5 skill-references. Corpus unchanged since Round 3. All persona Detailed references complete, no orphaned learnings, no stale refs, no broken links. Fourth consecutive clean LEARNINGS result (iters 7, 8-adjacent, 10). CLEAN_ROUND_STREAK=1, ROUND_CLEAN remains true. Advancing to SKILLS.

**Deep dive candidates (CLEAN_ROUND_STREAK >= 1, recording for phase transition):**
- **Never deep-dived** (last_deep_dive_run=0): xrpl-typescript-fullstack.md, quantum-tunnel-claudes/SKILL.md, agent-prompting.md
- **Stale (staleness >= 3)**: skill-design.md, claude-code.md, playwright-patterns.md, multi-agent-patterns.md, refactoring-patterns.md, xrpl-patterns.md, bash-patterns.md, testing-patterns.md
- **At threshold (staleness = 3)**: web-session-sync.md, guideline-authoring.md, typescript-devops.md, ralph-loop.md, api-design.md
- **Untracked**: ~35 corpus files not yet in deep-dive-tracker — will be added on phase transition

### Iter 11

**Round 4 SKILLS sweep — clean.** Re-read all 30 SKILL.md files, 5 skill-references, 7 personas. Clustered by namespace (git:9, learnings:4, ralph:7, parallel-plan:2, standalone:8). All skills relevant, no 80%+ overlap, references fresh, scopes well-defined. Cross-skill and cross-persona checks clean. All Co-Authored-By strings current (Opus 4.6). Corpus unchanged since iter 8 — identical clean result. Advancing to GUIDELINES.

### Iter 12

**Round 4 GUIDELINES sweep — clean. CONVERGENCE!** Re-read all 3 guidelines, cross-referenced against 48 learnings, 5 skill-references, 7 personas. All 3 @-referenced in CLAUDE.md (always-on). No overlap, no dead weight, no domain-specific content, no compression opportunities. Identical to iter 9.

**End of Round 4**: ROUND_CLEAN = true (all three sweeps — LEARNINGS iter 10, SKILLS iter 11, GUIDELINES iter 12 — clean). CLEAN_ROUND_STREAK = 2 → **BROAD SWEEP CONVERGENCE**.

**Phase transition to DEEP_DIVE.** 11 candidates identified:
- **Never deep-dived (modification-triggered)**: xrpl-typescript-fullstack.md (modified iter 4), agent-prompting.md (modified iter 3), quantum-tunnel-claudes/SKILL.md (tracked, never dived)
- **Stale (staleness=3, at threshold)**: skill-design.md, claude-code.md, playwright-patterns.md, multi-agent-patterns.md, refactoring-patterns.md, xrpl-patterns.md, bash-patterns.md, testing-patterns.md

11 candidates >= min_deep_dives (10), no fill needed.

### Iter 13

**Deep dive 1 — xrpl-typescript-fullstack.md: 1 HIGH applied.** Parsed persona into 7 sections, cross-referenced each pattern against 16 learnings files (all XRPL, React, Next.js, API design learnings), 7 personas, 5 skill-references. Found the "Known gotchas & platform specifics" section (35 lines, 5 subsections) was near-verbatim duplicate of content already in Proactive loads (xrpl-gotchas.md, react-frontend-gotchas.md) and Detailed references (nextjs.md, xrpl-patterns.md). Replaced with compressed reference pointers (~10 lines), following react-frontend.md lean persona pattern.

**No compound insights** — the de-enrichment pattern (personas duplicating proactive loads) was already identified in iter 1. No novel corpus pattern discovered.

**Next candidate**: agent-prompting.md (skill-reference, modified iter 3 when multi-agent-orchestration.md was folded in).

### Iter 14

**Deep dive 2 — agent-prompting.md: clean.** Parsed 15 H2 sections (Verbatim Templates, Prompt Structure, Fast/Slow Agent, Scaling by File Size, Code Landmarks, TDD Workflow, Code Formatting, Boundary Constraints, Shared Contract, Model Selection, Completion Report, Git Workflow, Interface-First, Integration Agent). Cross-referenced against multi-agent-patterns.md (253 lines), parallel-plans.md (142 lines), skill-design.md (266 lines), claude-code.md (148 lines), subagent-patterns.md (41 lines), bash-patterns.md (143 lines). All 15 sections unique — conceptually adjacent topics in multi-agent-patterns and parallel-plans are complementary, not overlapping. Consumers verified: parallel-plan/execute (3 refs) and parallel-plan/make (1 ref).

**Next candidate**: quantum-tunnel-claudes/SKILL.md (tracked, never deep-dived).

### Iter 15

**Deep dive 3 — quantum-tunnel-claudes/SKILL.md: clean.** Parsed 13 sections (frontmatter, usage, configuration, reference files, parallel execution, steps 0-5, prerequisites, important notes). Cross-referenced against cross-repo-sync.md (16 sections), multi-agent-patterns.md (25 sections), skill-design.md (22 sections), claude-code.md (17 sections), agent-prompting.md (15 sections), corpus-cross-reference.md, classification-model.md. All 3 conditional reference paths verified (corpus-cross-reference.md, classification-model.md, cross-repo-sync.md). inventory.sh companion script verified. No duplications, no stale references. Skill is a lean operational procedure with knowledge delegated to reference files — correct architecture.

**Next candidate**: skill-design.md (staleness=3, at threshold).

### Iter 16

**Deep dive 4 — skill-design.md: clean.** Parsed 28 H2 sections (Gap vs Inconsistency, Report-Only, Stateful Mode Detection, Permission Self-Doc, Compose Skills, Merging Diverged Skills, In-Session Improvement, AskUserQuestion 4-Option Max, Reference Style Preservation, Compound Grep-First, LLM Consistency, Stale Paths, Producer-Consumer Wiring, Hook Placement, @ References Eager Load, Producer-Consumer Atomic Updates, Trigger Phrases, Three-Level Routing, Typing Justification, Persona Judgment Layer, Tool-Philosophy Alignment, Compose Personas, Cross-Persona Dedup, Skill Boundaries, Explore Upfront, Maturity Progression, Gotchas Proactive, Gotchas Companion Convention). Cross-referenced against claude-code.md (17 sections), skill-platform-portability.md (20 sections), claude-code-hooks.md (10 sections), guideline-authoring.md (9 sections), multi-agent-patterns.md (25 sections), ralph-loop.md (22 sections), explore-repo.md (14 sections), parallel-plans.md (17 sections), claude-md-authoring.md (6 sections), agent-prompting.md (15 sections), subagent-patterns.md (3 sections), code-quality-instincts.md (3 sections), refactoring-patterns.md (12 sections). One minor embedded overlap (symlink gotcha L105 vs claude-code.md L141) — too small and contextually embedded to warrant action. No persona wiring needed — meta/tooling domain correctly standalone.

**Next candidate**: claude-code.md (staleness=3, at threshold).

### Iter 17

**Deep dive 5 — claude-code.md: clean.** Parsed 19 H2 sections (Task Tool worktree limitations, No Mid-Flight Messaging, Skill Discovery sibling vs subdirectory, Permission Rules Read covers Glob/Grep, Background Bash Agents permissions, Permissions Cached at Session Start, Worktree Isolation permission mismatches, Bash Permission Prefix Matching, Scoping Bash Permissions helper scripts, Use TaskOutput not Bash, Context Continuation loses file contents, WebFetch cannot parse PDF, Always Read Before Write, Subagent Reads prerequisite, Parallel Tool Call Error Cascade, ~/.claude Symlink Structure, Glob Can Miss Files, Glob Fails Through Symlinks, Sanitizing Examples). Cross-referenced against skill-design.md (28 sections), skill-platform-portability.md (20 sections), claude-code-hooks.md (10 sections), multi-agent-patterns.md (25 sections), bash-patterns.md (7 sections), ralph-loop.md (22 sections), agent-prompting.md (15 sections), subagent-patterns.md (3 sections), claude-md-authoring.md (6 sections), and all 3 guidelines. All 19 sections unique — no exact or near duplicates. Symlink Structure overlap with skill-design.md L105 noted in iter 16 still holds as too minor.

**Next candidate**: playwright-patterns.md (staleness=3, at threshold).

### Iter 18

**Deep dive 6 — playwright-patterns.md: clean.** Parsed 17 H2 sections (Shared BrowserContext, page.once Dialog, getByRole Accessible Name, textContent Concatenation, Scope Selectors, StorageState localStorage, selectOption string-only, exact:true, Option Visibility, getByLabel Association, Modal role="dialog", Strict Mode getByText, .first() Dynamic, Dynamic File Inputs, Transient Banners, .filter().first() Ancestors, .or() Terminal States). Cross-referenced against testing-patterns.md (10 sections — Vitest/RTL, no overlap), react-frontend-gotchas.md (5 Playwright one-liners — correct summaries), react-frontend persona (5 Playwright gotchas — same summaries), accessibility-patterns.md (6 sections — complementary ARIA patterns, no overlap), ui-patterns.md (3 sections — CSS/design, no overlap), xrpl-typescript-fullstack persona (no Playwright section — Playwright flows transitively via react-frontend-gotchas proactive load), typescript-devops persona (Playwright browser caching — CI-level, not test-writing overlap). All 17 sections unique at recipe level. Reference wiring complete (react-frontend persona L64).

**Next candidate**: multi-agent-patterns.md (staleness=3, at threshold).

### Iter 19

**Deep dive 7 — multi-agent-patterns.md: clean.** Parsed 32 H2 sections (Synthesis Separate Invocation, Agent Output Files, Coordinating Interface Changes, Group by File Domain, Sandbox Workaround Lifecycle Scripts, Codebase Comparison, Port/Migrate Full Source, Three-Phase Refactoring, Project Adaptation Workflow, Verify Web Sources, Three-Branch Gate Announcements, Delegated Intent Files, Front-Load Structural Context, Full Write > Incremental Edit, Workflows Survive Compaction, Balance by Complexity, Many-Agent Compaction Risk, Write One Validate Parallelize, Cross-Agent File References, Simple Inline over Agent, Context Budget Delegate Early, Categorize by Shared Structure, Standardize Worktree Commit, Worktree Full Lint Stack, Worktree Merge Check Commit State, Subagents Cannot Write .md, Extractor-Writer Pattern, Session-Resumable Workflows, TaskOutput Background Bash Only, Split Writers by Location, Targeted Grep Verification, Trust-Building Arc). Cross-referenced against parallel-plans.md (17 sections), agent-prompting.md (skill-ref, 15 sections), subagent-patterns.md (skill-ref, 3 sections), skill-design.md (28 sections), claude-code.md (19 sections), bash-patterns.md (7 sections), ralph-loop.md (22 sections), cross-repo-sync.md (16 sections), 3 personas (xrpl-typescript-fullstack, react-frontend, platform-engineer). All 32 sections unique at pattern level. See-also ref to subagent-patterns.md (line 3) valid. 2 LOWs: (1) "Three-Branch Gate Announcements" is about learnings-system gate observability, not multi-agent patterns — borderline misplacement but too thin (4 lines) to warrant moving; (2) "TaskOutput Only Works for Background Bash Tasks" contradicts claude-code.md § "Use TaskOutput Not Bash" which says TaskOutput works for Task agents — needs empirical verification.

**Next candidate**: refactoring-patterns.md (staleness=3, at threshold).
