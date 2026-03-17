# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 14 |
| CONTENT_TYPE | — (broad sweeps complete) |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_CANDIDATES | newman-postman.md, local-dev-seeding.md |
| DEEP_DIVE_COMPLETED | claude-authoring-content-types.md, multi-agent-patterns.md, claude-code.md, git-patterns.md, spring-boot.md, process-conventions.md, code-quality-instincts.md, financial-applications.md, java-devops.md, ci-cd-gotchas.md, parallel-plans.md |

## Pre-Flight

<!-- Populated by init skill -->

```
Recent commits: 8ef8b12 consolidate: remove round 2 confirmation pass | 9afdbae Consolidation: 2026-03-15 | d879ade Extract shared request interaction patterns
Learnings files: 58
Skills count: 31
Guidelines files: 4
Persona files: 11
Cadence: moderate (2 curation commits in last 5)
Suggested iterations: 15
```

## Content Type Status

### LEARNINGS
- **Sweeps**: 1
- **HIGHs applied**: 0
- **MEDIUMs applied**: 5
- **MEDIUMs blocked**: 0

### SKILLS
- **Sweeps**: 1
- **HIGHs applied**: 0
- **MEDIUMs applied**: 1
- **MEDIUMs blocked**: 0

### GUIDELINES
- **Sweeps**: 1
- **HIGHs applied**: 0
- **MEDIUMs applied**: 0
- **MEDIUMs blocked**: 0

## Iteration Log

| Iter | Content Type | HIGHs | MEDIUMs | LOWs | Actions | Notes |
|------|-------------|-------|---------|------|---------|-------|
| 1 | LEARNINGS | 0 | 5 | 0 | 5 applied (1 stale ref removal, 4 cross-ref wirings) | Clean collection — no duplicates, no stale content, no misplaced files. 5 cross-ref graph improvements. |
| 2 | SKILLS | 0 | 1 | 0 | 1 applied (persona de-enrichment) | 31 skills, 11 personas, 16 skill-refs evaluated. No skill overlap/staleness. 1 cross-persona dedup: java-devops inline gotchas → reference. |
| 3 | GUIDELINES | 0 | 0 | 0 | 0 (clean) | 4 guidelines, all @-referenced, all behavioral/universal. No duplication, no compression opportunities. Transitioned to DEEP_DIVE phase with 13 candidates. |
| 4 | DEEP_DIVE | 0 | 0 | 0 | 0 (clean) | claude-authoring-content-types.md — hub with 13+ inbound refs. 11 sections all correctly placed. 6 spoke files verified. Hub-spoke layering correct (summary in hub, detail in spokes). No overlap, no compression opportunities. |
| 5 | DEEP_DIVE | 0 | 0 | 0 | 0 (clean) | multi-agent-patterns.md — hub with 7 inbound refs, 43 patterns, 305 lines. All patterns standalone reference / keep. 2 outbound cross-refs valid. 7 inbound refs all bidirectional. No duplicates, no compression opportunities. |
| 6 | DEEP_DIVE | 0 | 1 | 0 | 1 applied (title/framing fix) | claude-code.md — hub with 7 inbound refs, 33 patterns, 292 lines. 1 MEDIUM: "Use TaskOutput" section title/framing contradicted multi-agent-patterns.md re: Bash vs Agent background tasks — clarified. All other patterns standalone reference / keep. 2 outbound cross-refs valid bidirectional. |
| 7 | DEEP_DIVE | 0 | 1 | 0 | 1 applied (cross-ref wiring) | git-patterns.md — 234 lines, 28 patterns. No overlap with claude-code.md (worktree patterns are complementary). 3 inbound refs (bash-patterns, newman-postman, platform-engineer persona). 2 outbound refs: bash-patterns bidirectional ✓, ci-cd-gotchas unidirectional → added back-ref (MEDIUM). |
| 8 | DEEP_DIVE | 0 | 2 | 0 | 2 applied (Takeaway compression + cross-ref) | spring-boot.md — 205→157 lines (~23% compression). 37 patterns, all keep. Removed 24 redundant Takeaway lines, folded 2 valuable ones into body. Added missing cross-ref to spring-boot-gotchas.md. No duplication with other files. |
| 9 | DEEP_DIVE | 0 | 3 | 0 | 3 applied (Takeaway compression) | process-conventions.md — 166→163 lines. 28 patterns, all keep. Removed 3 redundant Takeaway lines. Cross-refs valid bidirectional. 7 inbound refs verified. No duplication. |
| 10 | DEEP_DIVE | 0 | 1 | 0 | 1 applied (Takeaway compression) | code-quality-instincts.md — 131→113 lines (~14% compression). 26 patterns, all keep. Removed 9 redundant Takeaway lines. 12+ inbound refs. 2 outbound cross-refs bidirectional ✓. No duplication. |
| 11 | DEEP_DIVE | 0 | 2 | 0 | 2 applied (Takeaway compression + cross-ref) | financial-applications.md — 64→52 lines (~19% compression). 9 patterns, all keep. Removed 6 redundant Takeaway lines. Added back-ref from bignumber-financial-arithmetic.md. 3 inbound refs verified. No duplication. |
| 12 | DEEP_DIVE | 0 | 0 | 0 | 0 (clean) | java-devops.md — 35 lines, 6 sections. Extends platform-engineer. De-enrichment from sweep 2 verified clean. No overlap with java-backend or platform-engineer. All refs valid. |
| 13 | DEEP_DIVE | 0 | 2 | 0 | 2 applied (cross-ref wiring) | ci-cd-gotchas.md — 36 lines, 19 patterns. 2 MEDIUMs: added See also back-refs from ci-cd.md and gitlab-ci-cd.md. No overlap with companions or typescript-ci-gotchas.md. |
| 14 | DEEP_DIVE | 0 | 1 | 0 | 1 applied (cross-ref wiring) | parallel-plans.md — 146 lines, 15 patterns. 1 MEDIUM: added back-ref from multi-agent-patterns.md. No overlap with multi-agent-patterns, claude-code, or process-conventions. No compression opportunities. |

## Deep Dive Status

| File | Status | Iter | Summary |
|------|--------|------|---------|
| claude-authoring-content-types.md | DONE | 4 | Clean — 11 sections, all keep. 6 spoke refs verified. No overlap/compression. |
| multi-agent-patterns.md | DONE | 5 | Clean — 43 patterns, all keep. 7 inbound refs verified bidirectional. 2 outbound refs valid. Hub-spoke layering correct. |
| claude-code.md | DONE | 6 | 1 MEDIUM applied: TaskOutput section title/framing fix (Bash vs Agent distinction). 33 patterns, all keep. 7 inbound refs, 2 outbound refs verified bidirectional. |
| git-patterns.md | DONE | 7 | 1 MEDIUM applied: cross-ref wiring ci-cd-gotchas.md. No overlap with claude-code.md confirmed. 28 patterns, all keep. |
| spring-boot.md | DONE | 8 | 2 MEDIUMs applied: Takeaway compression (205→157 lines, 24 redundant removed, 2 folded into body) + cross-ref to spring-boot-gotchas.md. 37 patterns, all keep. No duplication. |
| process-conventions.md | DONE | 9 | 3 MEDIUMs applied: Takeaway compression (166→163 lines, 3 redundant removed). Cross-refs valid bidirectional. 28 patterns, all keep. |
| code-quality-instincts.md | DONE | 10 | 1 MEDIUM applied: Takeaway compression (131→113 lines, 9 redundant removed). 26 patterns, all keep. 12+ inbound refs (hub). 2 outbound cross-refs bidirectional ✓. No duplication. |
| financial-applications.md | DONE | 11 | 2 MEDIUMs applied: Takeaway compression (64→52 lines, 6 redundant removed) + cross-ref to bignumber-financial-arithmetic.md. 9 patterns, all keep. No duplication. |
| java-devops.md | DONE | 12 | Clean — 35 lines, 6 sections. Extends platform-engineer correctly (specializes, no duplication). De-enrichment from sweep 2 verified (1-line judgment + reference). No overlap with java-backend. All refs valid. |
| ci-cd-gotchas.md | DONE | 13 | 2 MEDIUMs applied: cross-ref wiring to ci-cd.md and gitlab-ci-cd.md (companion back-refs). 19 patterns, all keep. No overlap with companions or typescript-ci-gotchas.md. |
| parallel-plans.md | DONE | 14 | 1 MEDIUM applied: cross-ref wiring multi-agent-patterns.md back-ref. 15 patterns, all keep. No overlap with multi-agent-patterns.md, claude-code.md, or process-conventions.md. No compression. |
| newman-postman.md | PENDING | — | Stale + modified (sweep 1) |
| local-dev-seeding.md | PENDING | — | Stale + modified (sweep 1) |

## Notes for Next Iteration

<!-- Appended each iteration with ### Iter N heading — do not overwrite -->

### Iter 1

**Classification criteria (condensed from methodology references):**
- 6-bucket model: skill candidate, template for skill, context for skill, guideline candidate, standalone reference, outdated
- Migration litmus test: "Would having this in the target file actually change how I execute?"
- Context cost check: @-referenced files = always-on cost; prefer non-@ for domain-specific content
- Compression targets: provenance notes, self-assessments, debugging trails, verbose code blocks, redundant structural dividers, stale snapshot numbers
- Persona suggestion: 3+ files, 8+ patterns, no existing persona

**LEARNINGS sweep findings:**
- Collection is clean — no duplicates, no stale content, no misplaced files, good genericization
- Cross-reference graph: 27 connected, 31 isolated, 5 hubs (content-types 5, multi-agent-patterns 6, claude-code 5, code-quality-instincts 3, process-conventions 4)
- Applied 5 MEDIUMs: 1 stale ref removal (ci-cd-gotchas.md), 4 cross-ref wirings (parallel-plans, spring-boot, newman-postman, local-dev-seeding)
- java-devops persona duplicates java-observability-gotchas.md inline — persona de-enrichment candidate for SKILLS sweep

**Polish Opportunities (Takeaway compression — deep dive candidates):**
- spring-boot.md (202 lines, ~21 redundant Takeaway lines)
- code-quality-instincts.md (130 lines, ~6 redundant Takeaway lines)
- process-conventions.md (166 lines, ~6 redundant Takeaway lines)
- financial-applications.md (64 lines, ~7 redundant Takeaway lines)

**Deep dive candidates from LEARNINGS sweep:**
- claude-authoring-content-types.md — hub (5+ inbound refs)
- multi-agent-patterns.md — hub (6 inbound refs)
- claude-code.md — hub (5 inbound refs)
- git-patterns.md — 234 lines, potential overlap with claude-code.md on worktree settings
- spring-boot.md — Polish Opportunity (compression)
- process-conventions.md — Polish Opportunity (compression)
- code-quality-instincts.md — Polish Opportunity (compression)
- financial-applications.md — Polish Opportunity (compression)

### Iter 2

**SKILLS sweep findings:**
- All 31 skills evaluated: Keep. No staleness, overlap, or scope issues.
- Skill clusters: git:* (10), learnings:* (4), ralph:* (7), parallel-plan:* (2), standalone (8)
- Cross-skill: request-interaction-base.md properly shared between address-request-comments and code-review-request. No duplication.
- Co-Authored-By strings: all current (Claude Opus 4.6)
- Cross-persona: java-devops inline observability gotchas de-enriched → 1-line summary + reference (content already in proactive-loaded java-observability-gotchas.md)
- Deep dive candidates from SKILLS sweep: java-devops.md (modified — de-enrichment)

### Iter 3

**GUIDELINES sweep findings:**
- 4 guidelines: communication.md, context-aware-learnings.md, path-resolution.md, skill-invocation.md
- All @-referenced from `.claude/CLAUDE.md` (always-on context)
- All behavioral/universal — no domain-specific content, no overlap with learnings/skills/personas
- No compression opportunities: communication.md is largest but detail = value; context-aware-learnings.md is procedural; other 2 are already terse
- No unreferenced guidelines, no reference material masquerading as behavioral guideline
- Clean sweep: 0 HIGHs, 0 MEDIUMs, 0 LOWs

**Transition to DEEP_DIVE:**
- Broad sweeps complete (L→S→G). 13 deep dive candidates identified:
  - Modification-triggered (priority): 3 hubs, 1 size concern, 4 Polish Opportunities, 1 modified persona
  - Staleness fill: 4 files with last_deep_dive_run=0 (all modified in sweep 1)
- Exceeds min_deep_dives=10

### Iter 4

**Deep dive: claude-authoring-content-types.md (clean)**
- Hub file, 123 lines, 11 sections, 13+ inbound refs from skills, personas, learnings spokes, and curate infrastructure
- All 6 spoke files in "Authoring Guides" section verified to exist
- Hub-spoke layering correct: hub has summary/routing, spokes have deep treatment. No duplication.
- "Converting Guidelines to Skills" and `claude-authoring-skills.md` → "Guidelines-to-Skills Migration" are complementary (hub=mechanical process, spoke=decision criteria)
- No compression opportunities — 123 lines is lean for a 13-consumer hub
- Next: multi-agent-patterns.md (hub, 6 inbound refs)

### Iter 5

**Deep dive: multi-agent-patterns.md (clean)**
- Hub file, 305 lines, 43 patterns, 7 inbound refs (parallel-plans, ralph-loop, process-conventions, explore-repo, claude-code, claude-authoring-polling-review-skills, claude-authoring-skills)
- 2 outbound cross-refs (claude-code.md, claude-authoring-skills.md) — both valid, both bidirectional
- All 7 inbound refs have valid bidirectional cross-references back to this file
- No duplicates found — each pattern covers a distinct orchestration concern not replicated in spoke files
- Hub-spoke layering correct: this file covers agent orchestration patterns; claude-code.md handles platform mechanics; claude-authoring-skills.md handles skill design; parallel-plans.md handles DAG/plan-level concerns; etc.
- Minor observation: claude-code.md section "Use TaskOutput, Not Bash, to Check Background Agent Progress" title may tension with this file's "TaskOutput Only Works for Background Bash Tasks" — but bodies are consistent when read carefully. Note for claude-code.md deep dive.
- No compression opportunities — 43 patterns at ~7 lines avg is already dense for a hub
- Next: claude-code.md (hub, 5 inbound refs)

### Iter 6

**Deep dive: claude-code.md (1 MEDIUM applied)**
- Hub file, 292 lines, 33 patterns, 7 inbound refs (ralph-loop, claude-code-hooks, multi-agent-patterns, claude-authoring-skills ×2, bash-patterns, claude-authoring-learnings, skill-platform-portability) + 1 persona ref (claude-config-expert)
- 2 outbound cross-refs (multi-agent-patterns.md, claude-code-hooks.md) — both valid, both bidirectional
- 1 MEDIUM applied: "Use TaskOutput, Not Bash, to Check Background Agent Progress" renamed to "Use TaskOutput, Not Bash, to Check Background Bash Tasks" — title and opening line said "background agents" but TaskOutput only works for background Bash tasks per multi-agent-patterns.md § "TaskOutput Only Works for Background Bash Tasks". Added explicit cross-ref to that section.
- Resolved the tension flagged in iter 5 notes — the inconsistency was real (title-level, not body-level) and is now fixed
- Hub-spoke layering confirmed correct: this file = platform mechanics (permissions, tool behavior, CLI quirks); multi-agent-patterns.md = orchestration; claude-code-hooks.md = hooks system; bash-patterns.md = shell command patterns; git-patterns.md = git workflows
- No compression opportunities — 33 patterns at avg ~7 lines is already dense
- Next: git-patterns.md (234 lines, potential overlap with claude-code.md on worktree settings)

### Iter 7

**Deep dive: git-patterns.md (1 MEDIUM applied)**
- 234 lines, 28 patterns, 3 inbound refs (bash-patterns.md, newman-postman.md, platform-engineer.md persona), 2 outbound refs
- **Overlap check (primary candidacy reason)**: No overlap with claude-code.md. git-patterns covers settings isolation mechanics + parallel rebase worktrees; claude-code covers CWD pinning behavior. Different concerns, complementary.
- **Cross-ref audit**: bash-patterns.md ↔ git-patterns.md bidirectional ✓. ci-cd-gotchas.md was unidirectional (git-patterns→ci-cd-gotchas but not back). Added See also section to ci-cd-gotchas.md with back-ref.
- **Pattern-level**: All 28 patterns standalone reference / keep. No stale content, no misplaced content, no duplication. Stacked PR risk patterns (lines 166-176) are closely related but cover distinct angles (chain invalidation vs dependency divergence).
- No compression opportunities — patterns are already concise
- Next: spring-boot.md (Polish Opportunity — compression)

### Iter 8

**Deep dive: spring-boot.md (2 MEDIUMs applied)**
- 205 lines, 37 patterns, 1 outbound ref (postgresql-query-patterns.md), 1 companion file (spring-boot-gotchas.md)
- **Takeaway compression**: 26 patterns had `- **Takeaway**:` lines. 24 were pure restatements of heading+body — removed. 2 added genuine value (pattern 15: @Data/@Builder Lombok recipe not in body; pattern 25: multi-replica safety reasoning) — folded into body text, then removed Takeaway format. 205→157 lines (~23% compression).
- **Cross-ref gap**: spring-boot-gotchas.md self-describes as "Companion to spring-boot.md" but spring-boot.md had no back-reference. Added to See also.
- **No duplication**: Checked against spring-boot-gotchas.md (different patterns, different detail level), postgresql-query-patterns.md (cross-ref in place), testing-patterns.md (JS/Python-focused, no overlap with Java test patterns), code-quality-instincts.md (generic, no overlap).
- **No cross-file content issues**: All 37 patterns are standalone reference / keep. Test naming convention (pattern 34), validation test pattern (pattern 35), enum copy-paste risk (pattern 36) are Spring/Java-specific — correctly placed here, not in testing-patterns.md.
- Next: process-conventions.md (Polish Opportunity — compression)

### Iter 9

**Deep dive: process-conventions.md (3 MEDIUMs applied)**
- 166 lines, 28 patterns, 2 outbound refs (multi-agent-patterns.md, code-quality-instincts.md), 7 inbound refs (claude-authoring-polling-review-skills, refactoring-patterns, claude-authoring-skills, code-quality-instincts + 3 personas: reviewer, java-backend, claude-config-expert)
- **Takeaway compression**: 3 patterns had `- **Takeaway**:` lines, all pure restatements of heading+body — removed. 166→163 lines (~2% compression). Smaller than spring-boot.md (iter 1 estimated ~6, actual was 3).
- **Cross-ref audit**: Both outbound refs valid. multi-agent-patterns.md is unidirectional (process-conventions→multi-agent-patterns but not reverse) — no back-ref needed because "structured footnote" keyword connects them directly. code-quality-instincts.md is bidirectional ✓.
- **No duplication**: All 28 patterns are process-level conventions. No overlap with code-quality-instincts.md (code-level), refactoring-patterns.md (refactoring methodology), or claude-authoring-skills.md (skill design).
- Next: code-quality-instincts.md (Polish Opportunity — compression)

### Iter 10

**Deep dive: code-quality-instincts.md (1 MEDIUM applied)**
- 131 lines, 26 patterns, 2 outbound refs (process-conventions.md, refactoring-patterns.md), 12+ inbound refs (process-conventions, typescript-specific, testing-patterns, refactoring-patterns, api-design, claude-authoring-personas, 6 personas, extract-request-learnings/writer-prompt) — hub file
- **Takeaway compression**: 9 patterns had `- **Takeaway**:` lines, all pure restatements of heading+body — removed. 131→113 lines (~14% compression). Iter 1 estimated ~6, actual was 9.
- **Cross-ref audit**: Both outbound refs bidirectional ✓. testing-patterns.md → code-quality-instincts.md is unidirectional but keyword-discoverable ("test" in patterns #16, #17) — no back-ref needed per convention.
- **No duplication**: Patterns #1/#5 are conceptually related (don't duplicate / reuse existing) but cover different angles. No overlap with refactoring-patterns.md ("dead code"), testing-patterns.md ("negative test"), or process-conventions.md (different domain level).
- Next: financial-applications.md (Polish Opportunity — compression)

### Iter 11

**Deep dive: financial-applications.md (2 MEDIUMs applied)**
- 64 lines, 9 patterns, 2 outbound refs (bignumber-financial-arithmetic.md, resilience-patterns.md), 3 inbound refs (resilience-patterns.md, api-design.md, java-backend.md persona)
- **Takeaway compression**: 6 patterns had `- **Takeaway**:` lines, all pure restatements of heading+body — removed. 64→52 lines (~19% compression). Iter 1 estimated ~7, actual was 6.
- **Cross-ref gap**: bignumber-financial-arithmetic.md had no See also section and no back-ref to financial-applications.md. Added bidirectional link (JS BigNumber ↔ Java BigDecimal).
- **Cross-ref audit**: resilience-patterns.md bidirectional ✓. api-design.md unidirectional (api-design→financial-applications) — acceptable direction (generic→domain). java-backend.md persona ref — no back-ref needed.
- **No duplication**: All 9 patterns are domain-specific financial/payment patterns. No overlap with resilience-patterns.md (system-level resilience), api-design.md (generic API), or bignumber-financial-arithmetic.md (different language/stack).
- Next: java-devops.md (Modified — de-enrichment in sweep 2)

### Iter 12

**Deep dive: java-devops.md (clean)**
- Persona file, 35 lines, 6 sections. Extends platform-engineer. Modified in sweep 2 (de-enrichment of inline observability gotchas).
- **De-enrichment verification**: Known gotchas § Metrics & Observability now has 1-line judgment summary ("Follow the 6-step metrics discussion process...") + reference to java-observability-gotchas.md. Factual content properly in learning file. Clean.
- **Overlap check**: No duplication with platform-engineer (proper specialization — generic observability narrowed to JVM/Micrometer), java-backend (different lenses — devops=infra/ops, backend=app dev), or any learnings files.
- **Cross-ref audit**: java-observability-gotchas.md in Known gotchas (context) + Proactive loads (trigger). java-observability.md in Detailed references. All files exist.
- **Structure**: Observability approach section (lines 10-15) contains lens-type judgment heuristics — proper persona content, not factual gotchas.
- Next: ci-cd-gotchas.md (Stale + modified in sweep 1)

### Iter 13

**Deep dive: ci-cd-gotchas.md (2 MEDIUMs applied)**
- 36 lines, 19 patterns across 4 sections (GitHub Actions 6, GitLab CI/CD 12, CI Guards 1, See also 1). Companion to ci-cd.md and gitlab-ci-cd.md.
- **Overlap check**: No duplication with ci-cd.md (patterns vs gotchas framing — one overlap on `cancel-in-progress` but different contexts), gitlab-ci-cd.md (diagnostic/API vs config gotchas), or typescript-ci-gotchas.md (pnpm/Node specific).
- **Cross-ref audit**: git-patterns.md ↔ ci-cd-gotchas.md bidirectional ✓ (wired in iter 7). platform-engineer.md inbound (no back-ref needed). ci-cd.md and gitlab-ci-cd.md had NO back-refs despite being declared companions → 2 MEDIUMs applied.
- **No compression opportunities**: All bullet points, already terse. No Takeaway lines.
- Next: parallel-plans.md (Stale + modified in sweep 1)

### Iter 14

**Deep dive: parallel-plans.md (1 MEDIUM applied)**
- 146 lines, 15 patterns, 1 outbound ref (multi-agent-patterns.md), 0 real inbound refs (claude-authoring-learnings.md mentions as example only)
- **Overlap check**: No duplication with multi-agent-patterns.md (confirmed — agent orchestration vs plan-level execution), claude-code.md (platform mechanics vs plan strategy), or process-conventions.md (different domain level). Pattern 13 (Background Agent CLI Permission Gotcha) and claude-code.md's quoted string permission pattern cover different scopes (plan-specific recovery vs general principle). Pattern 14 (Context Compaction) and multi-agent-patterns.md's context compaction section are complementary (state file recovery vs general mitigations).
- **Cross-ref audit**: parallel-plans.md → multi-agent-patterns.md ✓ (wired in sweep 1). multi-agent-patterns.md → parallel-plans.md was MISSING. Added back-ref (MEDIUM). multi-agent-patterns See also now has 3 entries: claude-code, claude-authoring-skills, parallel-plans.
- **No compression opportunities**: All patterns terse, no Takeaway lines, no verbose code blocks.
- Next: newman-postman.md (Stale + modified in sweep 1)
