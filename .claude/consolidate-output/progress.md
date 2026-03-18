# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 1 |
| CONTENT_TYPE | LEARNINGS |
| PHASE | BROAD_SWEEP |
| DEEP_DIVE_CANDIDATES | typescript-ci-gotchas.md, gitlab-cli.md, claude-code-hooks.md, java-infosec-gotchas.md, java-observability-gotchas.md, spring-boot-gotchas.md, postgresql-query-patterns.md |
| DEEP_DIVE_COMPLETED | — |

## Pre-Flight

```
Recent commits: 824d43d Add more learnings | 7b45ced Consolidation: 2026-03-17 (33 iterations, 8H) | 6a9e0fa Add learnings index and run in parallel with search protocol
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
- **HIGHs applied**: 2
- **MEDIUMs applied**: 1
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
| 1 | LEARNINGS | 2 | 1 | 5 | 3 cross-ref edits | Broad sweep complete; added See Also to 3 isolated Java files; 5 LOWs recorded |

## Deep Dive Status

<!-- Populated when PHASE transitions to DEEP_DIVE after broad sweeps complete -->

| File | Status | Iter | Summary |
|------|--------|------|---------|
| typescript-ci-gotchas.md | pending | — | never deep-dived (run=0) |
| gitlab-cli.md | pending | — | never deep-dived (run=0) |
| claude-code-hooks.md | pending | — | never deep-dived (run=0) |
| java-infosec-gotchas.md | pending | — | never deep-dived (run=0) |
| java-observability-gotchas.md | pending | — | never deep-dived (run=0) |
| spring-boot-gotchas.md | pending | — | never deep-dived (run=0) |
| postgresql-query-patterns.md | pending | — | never deep-dived (run=0) |

## Notes for Next Iteration

### Iter 1

Broad sweep over all 58 learnings files + 11 personas completed. Corpus is in good health overall. Key findings:
- Java cluster has isolated thin files that needed cross-refs (now fixed)
- 7 files have never been deep-dived (run=0) — strong candidates for DEEP_DIVE phase
- 14+ additional files stale (run <= 9, threshold 5 with run_count 15)
- Several very thin files noted (LOW): typescript-specific.md, quarkus-kotlin.md, gitlab-cli.md — watch for growth or candidates for folding
- Cross-ref path inconsistency across learnings files (some use ~/.claude/, some bare filenames, one uses .claude/ CWD-relative) — LOW for human review
