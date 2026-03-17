# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 13 |
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
| 5 | DEEP_DIVE | 0 | 0 | 0 | 0 | communication.md — clean. 14 patterns, all universal behavioral guidelines, KEEP. |
| 6 | DEEP_DIVE | 0 | 0 | 0 | 0 | context-aware-learnings.md — clean. 8 patterns, all universal protocol sections, KEEP. |
| 7 | DEEP_DIVE | 0 | 0 | 0 | 0 | path-resolution.md — clean. 2 patterns, both universal path mechanics, KEEP. |
| 8 | DEEP_DIVE | 0 | 0 | 0 | 0 | skill-invocation.md — clean. 2 patterns, both universal behavioral rules, KEEP. |
| 9 | DEEP_DIVE | 0 | 0 | 0 | 0 | claude-config-author.md — clean. 8 patterns, judgment-lens content, correct authoring-persona structure, KEEP. |
| 10 | DEEP_DIVE | 0 | 0 | 0 | 0 | claude-config-reviewer.md — clean. 8 review sections, all STANDALONE REFERENCE. Child-only-adds-unique-content pattern (extends reviewer + claude-config-expert). All inline refs valid. |
| 11 | DEEP_DIVE | 1 | 0 | 0 | 1 | java-infosec.md — removed 7 redundant tripwires (near-verbatim duplicate of proactive-loaded java-infosec-gotchas.md). Compounded: inline-vs-proactive-load redundancy pattern → curation-insights.md. |
| 12 | DEEP_DIVE | 0 | 0 | 0 | 0 | reviewer.md — clean. 10 patterns all STANDALONE REFERENCE. Base persona pattern confirmed (no Known gotchas; children add domain gotchas). |
| 13 | DEEP_DIVE | 0 | 0 | 0 | 0 | code-quality-checklist.md — clean. 2 patterns both STANDALONE REFERENCE. Extraction heuristics + counter-heuristics. 2 consumers (do-refactor-code, parallel-plan/execute), no inline duplication. KEEP. |

## Deep Dive Status

<!-- 82 total candidates across all tiers. Max guard = 30. Prioritized by spec. -->

| # | File | Tier | Criterion | Status | Iter | Summary |
|---|------|------|-----------|--------|------|---------|
| 1 | .claude/learnings/claude-authoring-content-types.md | 1 | hub (1) | done | 4 | Clean — 11 patterns, all STANDALONE REFERENCE. Hub confirmed well-maintained. |
| 2 | .claude/guidelines/communication.md | 2 | unreviewed (6) | done | 5 | Clean — 14 patterns, all universal behavioral guidelines, KEEP. No duplication, no compression, no cross-refs needed. |
| 3 | .claude/guidelines/context-aware-learnings.md | 2 | unreviewed (6) | done | 6 | Clean — 8 patterns, all universal protocol sections, KEEP. Guideline gate passed. No compression, no cross-refs needed. |
| 4 | .claude/guidelines/path-resolution.md | 2 | unreviewed (6) | done | 7 | Clean — 2 patterns, both STANDALONE REFERENCE. Guideline gate passed. No compression, no cross-refs needed. |
| 5 | .claude/guidelines/skill-invocation.md | 2 | unreviewed (6) | done | 8 | Clean — 2 patterns, both universal behavioral rules, KEEP. Guideline gate passed. No compression, no cross-refs needed. |
| 6 | .claude/commands/set-persona/claude-config-author.md | 2 | unreviewed (6) | done | 9 | Clean — 8 patterns, all judgment-lens, correct authoring-persona structure. Known gotchas absent by design (parent covers). No compression, no See also needed. |
| 7 | .claude/commands/set-persona/claude-config-reviewer.md | 2 | unreviewed (6) | done | 10 | Clean — 8 review sections, all STANDALONE REFERENCE. Structural deviations intentional (parent coverage pattern). All inline refs valid. |
| 8 | .claude/commands/set-persona/java-infosec.md | 2 | unreviewed (6) | done | 11 | 1 HIGH applied — removed 7 redundant tripwires duplicating proactive-loaded java-infosec-gotchas.md. Domain priorities + tradeoffs: KEEP. |
| 9 | .claude/commands/set-persona/reviewer.md | 2 | unreviewed (6) | done | 12 | Clean — 10 patterns, all STANDALONE REFERENCE. Base persona pattern (no Known gotchas; children add domain gotchas). Proactive loads correct. |
| 10 | .claude/skill-references/code-quality-checklist.md | 2 | unreviewed (6) | done | 13 | Clean — 2 patterns both STANDALONE REFERENCE. Extraction heuristics, 2 consumers, no inline duplication in consumers. KEEP. |
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

### Iter 13

**Deep dive 10 of 30**: `code-quality-checklist.md` (skill-reference, unreviewed, tier 2) — CLEAN.
- 2 patterns: "Extract when you see" (4 heuristics: field-subset methods → helper class, duplicated blocks → helper method, repeated test construction → factory, 500+ line files → split) and "Don't extract" (3 counter-heuristics: 3 similar lines fine, single-use helpers rarely justified, obscuring test helpers).
- Both STANDALONE REFERENCE — purely actionable self-review heuristics, no principle explanations, no "why this matters" blocks.
- Reference-file gate: 2 consumers — `do-refactor-code/SKILL.md` (reads and evaluates against it) and `parallel-plan/execute/SKILL.md` (appends to agent prompts). Neither inlines the content — both reference the file as source. No deduplication action needed.
- Corpus cross-reference: `code-quality-instincts.md` covers implementation-time anti-duplication patterns (thematic, different scope). `refactoring-patterns.md` has "Deciding What NOT to Refactor" (thematic, different framing). No exact or partial match — no action needed.
- No compression opportunity (17 lines, already tight — no provenance notes, no verbose examples).
- No See also needed — keyword-discoverable via shared "code quality" vocabulary.
- Key insight: Skill-reference files that consist entirely of detection heuristics (no rationale sections) are correctly sized even at 17 lines. The absence of "why this matters" blocks is a quality signal, not a gap. Curation-insights already captures this for learnings; same applies to skill-references.
- Next: candidate 11 = `corpus-cross-reference.md` (skill-reference, unreviewed, tier 2).

### Iter 12

**Deep dive 9 of 30**: `reviewer.md` (persona, unreviewed, tier 2) — CLEAN.
- 10 patterns: Domain priorities (3), When reviewing (4), When making tradeoffs (3). All STANDALONE REFERENCE — lens directives.
- Missing Known gotchas section is intentional: base persona pattern. Children (claude-config-reviewer, java-infosec) add domain gotchas. Don't flag absence as a gap.
- Proactive loads: `code-quality-instincts.md` + `process-conventions.md` — correct. Covers the two foundational knowledge bases for any code reviewer.
- "Lean over noisy" sub-bullets are shorthand lens prioritization reminders, NOT verbatim duplicates of process-conventions. Key distinction vs java-infosec: tripwires were near-verbatim checklist items; these are one-line condensed headlines.
- No `## See also` needed — proactive loads section already names the two key cross-refs.
- File is 24 lines — correctly sized for a base persona.
- Next: candidate 10 = `code-quality-checklist.md` (skill-reference, unreviewed, tier 2).

### Iter 11

**Deep dive 8 of 30**: `java-infosec.md` (persona, unreviewed, tier 2) — 1 HIGH applied.
- Removed lines 13-19: 7 "When reviewing or writing code" bullets that were near-verbatim duplicates of `java-infosec-gotchas.md`. Gotchas file is in Proactive loads — loaded at persona activation, checklist items available at runtime without inlining. Kept: meta-instruction ("Apply tripwires from gotchas file") and mindset bullet ("Think like attacker").
- Domain priorities (5 focus areas) and When making tradeoffs (4 principles): all lens content, STANDALONE REFERENCE, KEEP.
- No `## See also` needed — gotchas file explicitly referenced in section text AND Proactive loads; other java files (spring-boot, java-observability) keyword-discoverable.
- Compound: added persona-inline-vs-proactive-load redundancy pattern to curation-insights.md (Classification Calibration).
- Next: candidate 9 = `reviewer.md` (persona, unreviewed, tier 2).

### Iter 10

**Deep dive 7 of 30**: `claude-config-reviewer.md` (persona, unreviewed, tier 2) — CLEAN.
- 8 review sections covering every config content type: Skills, Skill references, Templates, Guidelines, Learnings, Personas, CLAUDE.md, Memory.
- All STANDALONE REFERENCE — review-lens checklists unique to this persona's scope.
- Structural pattern: "child only adds what's unique to its domain." No Domain priorities/tradeoffs/proactive loads — inherited from `reviewer` (generic review lens) and `claude-config-expert` (domain knowledge). Same intentional deviation pattern as `claude-config-author.md`.
- All 6 inline `> Full criteria:` refs to `claude-authoring-*.md` learnings are valid (all present in tracker).
- No `## See also` needed — parents + inline refs handle lateral discovery.
- Key insight: When a persona child extends two parents where one supplies domain knowledge (claude-config-expert) and one supplies the review lens (reviewer), the child only needs to add domain-specific review checklists. Don't flag absence of Domain priorities / tradeoffs / proactive loads as gaps — they're structural inheritance, not missing content.
- Next: candidate 8 = `java-infosec.md` (persona, unreviewed, tier 2).

### Iter 9

**Deep dive 6 of 30**: `claude-config-author.md` (persona, unreviewed, tier 2) — CLEAN.
- 8 patterns across Domain priorities, When creating or modifying (6 subsections: Before writing anything, Skills, Guidelines, Learnings, Personas, CLAUDE.md), When making tradeoffs.
- All STANDALONE REFERENCE — judgment lens content, correctly typed for a persona.
- Structural deviation from standard 4-section template is intentional: "When creating or modifying" replaces "When reviewing or writing code" (authoring lens, not review lens). Known gotchas section absent — parent `claude-config-expert` supplies platform gotchas and all learnings references.
- No duplication with parent: parent covers taxonomy/placement/curation philosophy, child covers when/how to author each content type.
- Key insight: Persona structural deviations that reflect the domain's fundamental operation (authoring vs reviewing) are correct deviations, not gaps. Don't flag as missing section just because the standard template doesn't match — the lens type drives the section names.
- Next: candidate 7 = `claude-config-reviewer.md` (persona, unreviewed, tier 2).

### Iter 8

**Deep dive 5 of 30**: `skill-invocation.md` (guidelines, unreviewed, tier 2) — CLEAN.
- 2 patterns: "Always use the Skill tool for slash commands", "Don't ask permission to invoke skills within a skill's instructions". Both STANDALONE REFERENCE.
- Guideline gate passed — pure behavioral rules about skill dispatch, applies equally to any agent regardless of stack.
- No overlap with other guidelines (all 4 guidelines are orthogonal: communication=behavior, path-resolution=tooling, context-aware-learnings=search protocol, skill-invocation=skill dispatch).
- No compression ≥30% — file is 13 lines, tight.
- No `## See also` warranted — "skill", "Skill tool", "slash command" vocabulary is keyword-discoverable.
- Key insight: A small guidelines file (2 patterns, 13 lines) that covers a narrow but critical behavioral rule (always use Skill tool, never bypass) is correctly sized — it's not a thin pointer file. Thin pointers are mostly cross-references; this is pure operational content.
- Next: candidate 6 = `claude-config-author.md` (persona, unreviewed, tier 2).

### Iter 7

**Deep dive 4 of 30**: `path-resolution.md` (guidelines, unreviewed, tier 2) — CLEAN.
- 2 patterns: `@` references in CLAUDE.md files, Resolve relative paths against skill's base directory. Both STANDALONE REFERENCE.
- Guideline gate passed — pure path mechanics, applies equally to any agent regardless of stack.
- No overlap with other guidelines (orthogonal to communication, context-aware-learnings, skill-invocation).
- No compression ≥30% — file is already ~30 lines, minimal.
- No `## See also` warranted — `claude-authoring-claude-md.md` and `claude-authoring-skills.md` are keyword-discoverable via "CLAUDE.md"/"skill" vocabulary.
- Key insight: Small guidelines files (< 3 patterns) may look like fold-and-delete candidates, but if they're orthogonal to all other guidelines and universally needed, size alone is not a signal. Don't conflate "small" with "thin pointer" — thin pointer files are mostly cross-references/pointers, not self-contained operational content.
- Next: candidate 5 = `skill-invocation.md` (guidelines, unreviewed, tier 2).

### Iter 6

**Deep dive 3 of 30**: `context-aware-learnings.md` (guidelines, unreviewed, tier 2) — CLEAN.
- 8 patterns: Hard Gates, Core search pipeline, Gate-specific notes, Confidence-level gate, Friction-triggered, Keyword-based, Observability, Relationship to Personas. All STANDALONE REFERENCE.
- Guideline gate passed — all patterns stack-universal (apply equally to Java, Python, TS agents).
- No duplication with other guidelines (all orthogonal: communication=behavior, path-resolution=tooling, skill-invocation=skill dispatch, context-aware-learnings=search protocol).
- No compression ≥30% — file is 95 lines, dense, each section distinct and non-redundant.
- No `## See also` warranted — subagent persona propagation section connects to multi-agent-patterns.md but link is keyword-discoverable via "subagent" vocabulary.
- Key insight: A guidelines file covering a meta-protocol (when/how to search) is naturally universal and should not have See also refs — it IS the protocol that makes other files discoverable.
- Next: candidate 4 = `path-resolution.md` (guidelines, unreviewed, tier 2).

### Iter 5

**Deep dive 2 of 30**: `communication.md` (guidelines, unreviewed, tier 2) — CLEAN.
- 14 patterns, all universal behavioral guidelines. Guideline gate: passed (no stack-specific content).
- No duplication with other guidelines (context-aware-learnings, path-resolution, skill-invocation are orthogonal domains).
- No compression ≥30% found — file is dense but every sub-bullet carries distinct non-redundant guidance.
- No `## See also` warranted — universal behavioral guideline connects to everything/nothing specifically.
- Key insight: A guidelines file with this many sub-patterns (~8 lines/pattern) is well-calibrated. Don't flag as "compression candidate" just for size — look at insight density per line, not raw line count.
- Next: candidate 3 = `context-aware-learnings.md` (guidelines, unreviewed, tier 2).
