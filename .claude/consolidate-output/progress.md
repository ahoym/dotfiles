# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 1 |
| CONTENT_TYPE | SKILLS |
| PHASE | BROAD_SWEEP |
| DEEP_DIVE_CANDIDATES | — |
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

| Iter | Content Type | HIGHs | MEDIUMs | LOWs | Actions | Notes |
|------|-------------|-------|---------|------|---------|-------|
| 1 | LEARNINGS | 0 | 5 | 0 | 5 applied (1 stale ref removal, 4 cross-ref wirings) | Clean collection — no duplicates, no stale content, no misplaced files. 5 cross-ref graph improvements. |

## Deep Dive Status

<!-- Populated when PHASE transitions to DEEP_DIVE after broad sweeps complete -->

| File | Status | Iter | Summary |
|------|--------|------|---------|

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
