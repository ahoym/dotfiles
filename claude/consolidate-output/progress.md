# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 2 |
| CONTENT_TYPE | GUIDELINES |
| PHASE | BROAD_SWEEP |
| DEEP_DIVE_CANDIDATES | — |
| DEEP_DIVE_COMPLETED | — |

## Pre-Flight

<!-- Populated by init skill -->

```
Recent commits: 07c4608 Migrate learnings refs to provider slug scheme, d5eb763 Session learnings + director compound mode relaunch, a2ab7d3 Provider-aware learnings in remaining skills
Learnings files: 110
Skills count: 36
Skill references: 26
Guidelines files: 4
Persona files: 19
Cadence: stale (0 curation commits in last 5)
Suggested iterations: 20
```

## Content Type Status

### LEARNINGS
- **Sweeps**: 1
- **HIGHs applied**: 9
- **MEDIUMs applied**: 4
- **MEDIUMs blocked**: 0

### SKILLS
- **Sweeps**: 1
- **HIGHs applied**: 1
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
| 1 | LEARNINGS | 9 | 4 | 0 | 13 | Folded 7 thin/unclustered files into clusters, merged 6 thin Java files into 4 new cluster files, moved gitlab-ci-patterns to cicd/, fixed 5 stale tracker paths. Net -13 files. |
| 2 | SKILLS | 1 | 0 | 0 | 1 | Deleted orphaned draft skill-reference sweep-status-design.md (zero consumers). 36 skills, 25 remaining refs, 19 personas all healthy. |

## Deep Dive Status

<!-- Populated when PHASE transitions to DEEP_DIVE after broad sweeps complete -->

| Cluster/File | Files | Status | Iter | Summary |
|------|--------|------|---------|

## Notes for Next Iteration

### Iter 1

**Classification criteria (condensed from methodology):**
- 6-bucket model: skill candidate, template for skill, context for skill, guideline candidate, standalone reference, outdated
- Thin files <20 lines with explicit Related pointers → HIGH fold-and-delete
- Unclustered files with existing cluster → HIGH move or MEDIUM merge-and-move
- Migration litmus: "Would having this in the target actually change execution?" — if no, don't migrate
- Context cost: moving TO @-referenced file increases always-on cost; moving FROM reduces it
- Persona coverage ≠ learning obsolescence; keep learnings that prevent wrong approaches

**Remaining unclustered thin learnings files (not in any cluster, not indexed in CLAUDE.md):**
- `architecture-patterns.md` — URL encoding/signing patterns (1 pattern)
- `database-patterns.md` — PostgreSQL partial indexes (2 patterns, overlaps with postgresql-query-patterns.md)
- `docker-security.md` — Docker credential handling (1 pattern)
- `documentation-hygiene.md` — Placeholder UUIDs (1 pattern)
- `framework-patterns.md` — AWS SDK v2, Spring profile (2 patterns, cross-domain)
- `messaging-patterns.md` — AMQP routing (1 pattern)
- `process.md` — AI review division of labor (1 pattern, overlaps with process-conventions.md or review-conventions.md)
- `protobuf-patterns.md` — Proto3 schema evolution (1 pattern)
- `security.md` — SSL/TLS cert-pinned SSLContext (1 pattern)

These are all very thin (1-2 patterns) without clear cluster targets. Deep dive candidates for fold-or-index decisions.

**Cross-ref graph observations:**
- Stale cross-refs from testing files were fixed in tracker but the files themselves may still have old `Related:` paths
- Several unclustered files have `Related:` pointing to correct cluster files — they know where they belong but weren't moved
- cicd/ cluster now has 3 substantive files (gitlab.md, gitlab-ci-patterns.md, patterns.md) plus gotchas.md

**SKILLS sweep next:** Check skill-references consumer wiring, cross-persona gotcha dedup, skill overlap.

### Iter 2

**SKILLS sweep results:**
- 36 skills across 6 namespaces (git:11, learnings:4, ralph:7, parallel-plan:2, sweep:3, standalone:9) — no overlap, no merge/prune candidates
- 25/26 skill-references wired to consumers; deleted orphaned `sweep-status-design.md` (draft, zero consumers)
- All Co-Authored-By strings current (Claude Opus 4.6)
- Cross-persona boundaries clean: Java personas (backend, infosec, fintech extends both, devops extends platform), claude-config personas (expert, author extends expert, reviewer extends reviewer+expert), reviewer personas all distinct
- No reference wiring issues, no inline knowledge needing externalization

**GUIDELINES sweep next:** Check @-reference cost, wiring, behavioral vs reference material, domain-specific content in guidelines
