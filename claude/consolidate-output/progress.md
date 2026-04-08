# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 4 |
| CONTENT_TYPE | (all broad sweeps complete) |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_GROUPS | see below |
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
- **Sweeps**: 1
- **HIGHs applied**: 0
- **MEDIUMs applied**: 0
- **MEDIUMs blocked**: 1

## Iteration Log

| Iter | Content Type | HIGHs | MEDIUMs | LOWs | Actions | Notes |
|------|-------------|-------|---------|------|---------|-------|
| 1 | LEARNINGS | 9 | 4 | 0 | 13 | Folded 7 thin/unclustered files into clusters, merged 6 thin Java files into 4 new cluster files, moved gitlab-ci-patterns to cicd/, fixed 5 stale tracker paths. Net -13 files. |
| 2 | SKILLS | 1 | 0 | 0 | 1 | Deleted orphaned draft skill-reference sweep-status-design.md (zero consumers). 36 skills, 25 remaining refs, 19 personas all healthy. |
| 3 | GUIDELINES | 0 | 0 (1 blocked) | 0 | 0 | 4 files. communication.md + path-resolution.md @-referenced (clean). skill-invocation.md conditional (clean). context-aware-learnings.md unwired from CLAUDE.md — blocked as BM-1. |
| 4 | TRIAGE | — | — | — | 12 groups, 38 targets | Diff-routed triage: 160+ files changed since 97a6278. 33 diff-routed + 5 stale rotation targets. 12 groups assembled for deep dive phase. |

## Deep Dive Status

### DEEP_DIVE_GROUPS

Triage: 160+ files changed since last consolidation (97a6278). 33 diff-routed curation targets + 5 stale rotation = 38 total targets across 12 groups. Estimated 12 group invocations + 1 housekeeping = 13 deep dive invocations.

- **Group 1 (java/new)**: targets=[java/code-quality.md, java/concurrency.md, java/integration.md], context=[java/spring-boot.md, java/observability.md, java/quarkus-kotlin.md] | Flag: all last_deep_dive_run=0
- **Group 2 (java/modified)**: targets=[java/testing.md, java/infosec-gotchas.md, java/spring-boot-gotchas.md], context=[java/code-quality.md, java/observability-gotchas.md] | Flag: all last_deep_dive_run=0
- **Group 3 (cicd/)**: targets=[cicd/patterns.md, cicd/gitlab-ci-patterns.md, cicd/gitlab.md], context=[cicd/gotchas.md] | Flag: patterns+gitlab-ci-patterns never deep-dived
- **Group 4 (claude-authoring/content)**: targets=[claude-authoring/learnings-content.md, claude-authoring/skill-design.md, claude-authoring/claude-md.md], context=[claude-authoring/guidelines.md, claude-authoring/learnings-organization.md] | Flag: skill-design.md never deep-dived, 60-72 lines added each
- **Group 5 (claude-authoring/org)**: targets=[claude-authoring/learnings-organization.md, claude-authoring/personas.md, claude-authoring/polling-review-skills.md], context=[claude-authoring/skill-references-and-loading.md, claude-authoring/skill-lifecycle.md] | Flag: 32-40 lines added each
- **Group 6 (multi-agent/)**: targets=[multi-agent/director-patterns.md, multi-agent/orchestration.md, multi-agent/headless-nesting.md], context=[multi-agent/coordination.md, multi-agent/quality.md, multi-agent/autonomous-patterns.md] | Flag: 40-117 lines added, all new files
- **Group 7 (claude-code/platform)**: targets=[claude-code/skill-platform-portability.md, claude-code/platform-tools-and-automation.md, claude-code/platform-permissions.md], context=[claude-code/platform-worktrees-and-isolation.md, claude-code/hooks.md] | Flag: 58-102 lines added
- **Group 8 (claude-code/sessions)**: targets=[claude-code/sweep-sessions.md, claude-code/ralph-curation.md, claude-code/ralph-loop.md], context=[claude-code/cross-repo-sync.md, claude-code/shell-patterns.md] | Flag: sweep-sessions 97 lines new
- **Group 9 (unclustered/large)**: targets=[bash-patterns.md, git-patterns.md, review-conventions.md], context=[git-github-api.md, process-conventions.md] | Flag: 30-94 lines added
- **Group 10 (unclustered/thin)**: targets=[architecture-patterns.md, database-patterns.md, framework-patterns.md], context=[postgresql-query-patterns.md, resilience-patterns.md] | Flag: fold-or-index candidates from iter 1
- **Group 11 (unclustered/security)**: targets=[docker-security.md, security.md, documentation-hygiene.md], context=[process.md, messaging-patterns.md] | Flag: thin unclustered, fold-or-index candidates
- **Group 12 (stale rotation)**: targets=[claude-code/web-session-sync.md, testing/playwright-patterns.md, aws/messaging.md, financial/applications.md, testing/newman-postman.md], context=[] | Flag: stalest files not in diff (runs 8-12)

| Group | Targets | Status | Iter | Summary |
|-------|---------|--------|------|---------|

## Notes for Next Iteration

### Iter 4

**Triage results:**
- Diff anchor: 97a6278 (last_consolidation_commit from tracker). Run count: 16 (already incremented at iter 1).
- Diff scope: massive — provider slug migration (07c4608) + session learnings (d5eb763) + sweep 1-3 changes touched ~160 files
- 9 files with last_deep_dive_run=0 (created/modified by sweep 1): java/{code-quality,concurrency,integration,testing,infosec-gotchas,spring-boot-gotchas}.md, cicd/{patterns,gitlab-ci-patterns}.md, claude-authoring/skill-design.md
- 15+ files with >40 lines added (new content, not just migration): multi-agent/{director-patterns,orchestration,headless-nesting}.md, claude-code/{skill-platform-portability,platform-tools-and-automation,sweep-sessions}.md, claude-authoring/{learnings-content,claude-md}.md, bash-patterns.md, cicd/gitlab.md, etc.
- Stale rotation (5 slots, stalest not in diff): web-session-sync.md (run 8), testing/playwright-patterns.md (run 9), aws/messaging.md (run 10), financial/applications.md (run 11), testing/newman-postman.md (run 12)
- Skills/skill-references: broad sweep found healthy. Many new files (sweep/, team-review, director) but no content overlap with learnings flagged. Not added as deep dive targets.
- Unclustered thin files from iter 1 notes included in groups 10-11 for fold-or-index decisions

**Deep dive execution guidance:**
- Groups 1-2 (java/): All 6 files are new cluster files from sweep 1 merges. Verify content quality, cross-refs, keyword accuracy.
- Groups 4-5 (claude-authoring/): Heavily modified cluster. Watch for inter-file overlap after large additions.
- Group 6 (multi-agent/): 3 entirely new files (117+83+40 lines). Check for overlap with existing coordination.md and quality.md context files.
- Groups 10-11 (thin unclustered): These are the fold-or-index candidates from iter 1. Deep dive should make final call: fold into a cluster, leave standalone with proper indexing, or delete if outdated.
- Group 12 (stale rotation): No specific diff context. Standard content mode curation.

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

### Iter 3

**GUIDELINES sweep results:**
- 4 files total. 2 @-referenced (communication.md, path-resolution.md), 1 conditional (skill-invocation.md), 1 unwired (context-aware-learnings.md)
- communication.md: 111 lines, behavioral, universally applicable. Compression candidate for deep dive but nuance matters — not actioned in broad sweep.
- path-resolution.md: 24 lines, clean, properly wired.
- skill-invocation.md: 24 lines, conditional via procedural table. Behavioral one-liner inlined in CLAUDE.md, details lazy-loaded. Matches the "edge case" pattern from `guidelines.md:85`. Clean.
- context-aware-learnings.md: 55 lines, NOT in CLAUDE.md. Defines 6 mandatory learnings search gates. The learning `guidelines.md:87` says it's behavioral and should be @-referenced. But 55 lines always-on is significant. Blocked as BM-1 for human decision.

**TRANSITION**: All 3 broad sweep content types complete (L→S→G). Next invocation: read diff-routed-triage methodology and run triage to determine deep dive candidates.
