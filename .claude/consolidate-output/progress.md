# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 3 |
| CONTENT_TYPE | — (broad sweeps complete) |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_CANDIDATES | claude-authoring-content-types.md, multi-agent-patterns.md, claude-code.md, git-patterns.md, spring-boot.md, process-conventions.md, code-quality-instincts.md, financial-applications.md, java-devops.md, ci-cd-gotchas.md, parallel-plans.md, newman-postman.md, local-dev-seeding.md |
| DEEP_DIVE_COMPLETED | — |

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

## Deep Dive Status

| File | Status | Iter | Summary |
|------|--------|------|---------|
| claude-authoring-content-types.md | PENDING | — | Hub (5+ inbound refs) |
| multi-agent-patterns.md | PENDING | — | Hub (6 inbound refs) |
| claude-code.md | PENDING | — | Hub (5 inbound refs) |
| git-patterns.md | PENDING | — | 234 lines, potential overlap with claude-code.md |
| spring-boot.md | PENDING | — | Polish Opportunity (compression) |
| process-conventions.md | PENDING | — | Polish Opportunity (compression) |
| code-quality-instincts.md | PENDING | — | Polish Opportunity (compression) |
| financial-applications.md | PENDING | — | Polish Opportunity (compression) |
| java-devops.md | PENDING | — | Modified (de-enrichment in sweep 2) |
| ci-cd-gotchas.md | PENDING | — | Stale + modified (sweep 1) |
| parallel-plans.md | PENDING | — | Stale + modified (sweep 1) |
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
