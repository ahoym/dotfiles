# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 3 |
| CONTENT_TYPE | (all swept) |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_CANDIDATES | git/repoint-branch/SKILL.md, extractor-prompt.md, git/create-request/SKILL.md, typescript-ci-gotchas.md, gitlab-cli.md, claude-code-hooks.md, java-infosec-gotchas.md, java-observability-gotchas.md, spring-boot-gotchas.md, postgresql-query-patterns.md, ralph/consolidate/init/SKILL.md, extract-request-learnings/SKILL.md, git/split-commit/SKILL.md, learnings/consolidate/SKILL.md, typescript-devops.md, agent-prompting.md, quantum-tunnel-claudes/SKILL.md, xrpl-typescript-fullstack.md, react-frontend.md, platform-engineer.md |
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
- **Sweeps**: 1
- **HIGHs applied**: 1
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
| 1 | LEARNINGS | 2 | 1 | 5 | 3 cross-ref edits | Broad sweep complete; added See Also to 3 isolated Java files; 5 LOWs recorded |
| 2 | SKILLS | 1 | 0 | 2 | 1 stale ref fix | All 31 skills healthy; fixed stale /pr reference in git:repoint-branch; skill-refs symlink check skipped |
| 3 | GUIDELINES | 0 | 0 | 2 | none | Clean sweep; all 4 guidelines healthy, @-referenced; 2 LOWs — large always-on files; transitioning to DEEP_DIVE with 20 candidates |

## Deep Dive Status

<!-- Populated when PHASE transitions to DEEP_DIVE after broad sweeps complete -->

| File | Status | Iter | Summary |
|------|--------|------|---------|
| git/repoint-branch/SKILL.md | pending | — | modified iter 2 + unreviewed (not in tracker) |
| extractor-prompt.md | pending | — | never deep-dived (run=0) |
| git/create-request/SKILL.md | pending | — | never deep-dived (run=0) |
| typescript-ci-gotchas.md | pending | — | never deep-dived (run=0) |
| gitlab-cli.md | pending | — | never deep-dived (run=0) |
| claude-code-hooks.md | pending | — | never deep-dived (run=0) |
| java-infosec-gotchas.md | pending | — | never deep-dived (run=0) |
| java-observability-gotchas.md | pending | — | never deep-dived (run=0) |
| spring-boot-gotchas.md | pending | — | never deep-dived (run=0) |
| postgresql-query-patterns.md | pending | — | never deep-dived (run=0) |
| ralph/consolidate/init/SKILL.md | pending | — | stale skill (run=8, gap=7) |
| extract-request-learnings/SKILL.md | pending | — | stale skill (run=8, gap=7) |
| git/split-commit/SKILL.md | pending | — | stale skill (run=8, gap=7) |
| learnings/consolidate/SKILL.md | pending | — | stale skill (run=8, gap=7) |
| typescript-devops.md | pending | — | stale persona (run=8, gap=7) |
| agent-prompting.md | pending | — | stale skill-ref (run=9, gap=6) |
| quantum-tunnel-claudes/SKILL.md | pending | — | stale skill (run=9, gap=6) |
| xrpl-typescript-fullstack.md | pending | — | stale persona (run=9, gap=6) |
| react-frontend.md | pending | — | stale persona (run=9, gap=6) |
| platform-engineer.md | pending | — | stale persona (run=9, gap=6) |

## Notes for Next Iteration

### Iter 1

Broad sweep over all 58 learnings files + 11 personas completed. Corpus is in good health overall. Key findings:
- Java cluster has isolated thin files that needed cross-refs (now fixed)
- 7 files have never been deep-dived (run=0) — strong candidates for DEEP_DIVE phase
- 14+ additional files stale (run <= 9, threshold 5 with run_count 15)
- Several very thin files noted (LOW): typescript-specific.md, quarkus-kotlin.md, gitlab-cli.md — watch for growth or candidates for folding
- Cross-ref path inconsistency across learnings files (some use ~/.claude/, some bare filenames, one uses .claude/ CWD-relative) — LOW for human review

### Iter 2

SKILLS broad sweep complete over all 31 skills + reference files. Corpus is in good health. Key findings:
- All 31 skills healthy — active, no overlaps, complexity justified
- Co-Authored-By model versions: all current (Claude Opus 4.6) — no bulk update needed
- 1 HIGH fixed: git:repoint-branch had stale `/pr` reference (renamed to `/git:create-request`)
- skill-references symlink can't be traversed by Glob — consumer wiring check was skipped; needs human verification that skill-references files still exist and are current
- learnings:consolidate (interactive) and wiggum.sh autonomous loop coexist intentionally — different use cases
- Next: GUIDELINES sweep (4 files, always-on context cost focus)

### Iter 3

GUIDELINES broad sweep complete over all 4 guideline files. Corpus in good shape. Key findings:
- All 4 files @-referenced in CLAUDE.md — properly wired, no orphaned guidelines
- skill-invocation.md and path-resolution.md: clean, minimal always-on cost
- communication.md (~180 lines): dense behavioral rules, all universal; LOW compression flag (risk of nuance loss)
- context-aware-learnings.md (~130 lines): large always-on methodology; restructuring blocked — session-start hard gate must fire before first tool call; LOW for growth monitoring
- Broad sweep complete (L→S→G). Transitioning to DEEP_DIVE phase.
- 20 deep-dive candidates: 1 modification-triggered + 2 unreviewed skills + 7 unreviewed learnings + 10 stale skills/personas/skill-refs
