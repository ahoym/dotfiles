# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 8 |
| CONTENT_TYPE | (all broad sweeps complete) |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_GROUPS | see below |
| DEEP_DIVE_COMPLETED | Group 1 (java/new), Group 2 (java/modified), Group 3 (cicd/), Group 4 (claude-authoring/content) |

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
| 5 | DEEP_DIVE | 1 | 0 | 0 | 1 | Group 1 (java/new): 3 files, 8 patterns all clean. Fixed stale Related in protobuf-patterns.md. |
| 6 | DEEP_DIVE | 0 | 0 | 0 | 0 | Group 2 (java/modified): 3 files, 25+ patterns. All clean — testing.md well-scoped, infosec-gotchas.md cross-refs valid, spring-boot-gotchas.md dense but cohesive. |
| 7 | DEEP_DIVE | 3 | 0 | 0 | 3 | Group 3 (cicd/): 3 targets + 1 context. Deleted gotchas.md — GitLab sections verbatim duplicate of gitlab.md, GitHub Actions folded into patterns.md. Net -1 file. gitlab.md (204 lines) cohesive, no split. gitlab-ci-patterns.md clean. |
| 8 | DEEP_DIVE | 5 | 0 | 0 | 5 | Group 4 (claude-authoring/content): 3 targets + 2 context. Removed 2 verbatim dupes from learnings-content.md (cross-ref types → organization, maintenance cost → organization). Removed 3 verbatim dupes from claude-md.md (signpost, modular refactor, conflict resolution → all in claude-md-advanced.md). skill-design.md (209 lines, 26 sections) clean — density exemption. |

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
| Group 1 (java/new) | code-quality, concurrency, integration | complete | 5 | 1 HIGH (stale ref fix in protobuf-patterns.md), 8 patterns clean |
| Group 2 (java/modified) | testing, infosec-gotchas, spring-boot-gotchas | complete | 6 | Clean — 25+ patterns all well-structured, no overlap |
| Group 3 (cicd/) | patterns, gitlab-ci-patterns, gitlab | complete | 7 | 3 HIGHs: deleted gotchas.md (verbatim GitLab dupes of gitlab.md), folded GitHub Actions into patterns.md. Net -1 file. |
| Group 4 (claude-authoring/content) | learnings-content, skill-design, claude-md | complete | 8 | 5 HIGHs: removed 5 verbatim duplicate sections (2 from learnings-content.md, 3 from claude-md.md). skill-design.md clean (density exemption). |

## Notes for Next Iteration

### Iter 8

**Group 4 (claude-authoring/content) results:**
- 3 targets + 2 context files examined. Primary finding: verbatim duplicate sections from prior file splits that weren't cleaned up.
- learnings-content.md: removed "Cross-Reference Types: Semantic vs Discovery" (verbatim in learnings-organization.md, better fit there as cross-ref convention) and orphaned "Maintenance cost" line (belongs to CLAUDE.md index pattern in learnings-organization.md, not standardized header format). Now ~148 lines.
- claude-md.md: removed 3 sections already in claude-md-advanced.md (Signpost Pattern, Refactor Monolithic, Document Conflict Resolution). Cluster CLAUDE.md routing table already directs these to the advanced file. Now ~139 lines.
- skill-design.md (209 lines, 26 sections): clean. Above 150-line split threshold but ~8 lines/section average = density exemption. All patterns serve "skill design" search intent. Cross-ref to multi-agent/orchestration.md valid. Routing signposts to skill-platform-portability.md and polling-review-skills.md correctly siphon off adjacent topics.
- Context files (guidelines.md, learnings-organization.md): both clean, no issues detected.
- Pattern: claude-authoring cluster had verbatim duplicates from file splits (claude-md.md → claude-md-advanced.md split, learnings.md → learnings-content.md + learnings-organization.md split). Future splits should grep for section headings across both halves to catch stranded copies.

**Enriched keywords:**

| File | Keywords |
|------|----------|
| learnings-content.md | genericize, project-specific, scope classification, language-awareness, persona-learning boundary, provenance, header format, sniff window, standardized header, file naming drift, domain naming, overlap detection, deep coverage analysis, team learnings, batch import sanitization, CLI references, self-contained descriptions, implementation patterns, operationalization pruning |
| skill-design.md | skill design, compose, AskUserQuestion 4-option max, skill responsibility boundaries, stateful mode, file existence, gap vs inconsistency, exploration report-only, portable, bash commands, HEREDOC, validation, intake gate, triage, open contribution, $ARGUMENTS, disable-model-invocation, irreversible, director playbook, headless agent, learnings search, security audit, skill improvement, half-steps, file operations, deduplicate shared references, merging diverged, security-critical prominence |
| claude-md.md | CLAUDE.md, @ reference, eager load, conditional reference, subdirectory criteria, state machines, navigational hub, relationships, pointers, single source of truth, symlink, README, state conclusions, index files, breadcrumb pattern, consumer agents, symlinked repos |

### Iter 7

**Group 3 (cicd/) results:**
- 3 targets + 1 context file examined. Primary finding: gotchas.md was a dedup hazard — its GitLab CI/CD section (12 bullets) and CI Guards section were verbatim copies of gitlab.md Configuration Patterns and CI Guards sections.
- After removing GitLab duplicates, gotchas.md had only 6 GitHub Actions bullets. Folded these into patterns.md (5 bullets — dropped cancel-in-progress duplicate already in patterns.md's lint-first section). Deleted gotchas.md.
- gitlab.md at 204 lines exceeds 150-line split threshold but content is cohesive — all GitLab-specific (glab CLI, API, GraphQL, pipeline config). No split warranted.
- gitlab-ci-patterns.md (54 lines) is complementary to gitlab.md — pipeline optimization vs tooling/API. No overlap.
- patterns.md now covers both platform-agnostic CI patterns and GitHub Actions config. Cross-refs valid.

**Enriched keywords:**

| File | Keywords |
|------|----------|
| patterns.md | Docker build push, composite action, lint gate, needs dependency chain, Ruff formatter, CI pipeline structure, cancel-in-progress, test gating, selective tests, latent bugs, iterative validation, GitHub Actions, paths-ignore, continue-on-error, job timeout, gh run view |
| gitlab-ci-patterns.md | GitLab CI, YAML anchors, reference tags, Maven, artifacts, cache, BuildKit, SonarQube, timeout, needs optional, artifact scoping, test shards, docker-push DAG, Maven -pl, Maven cache key, maven -U |
| gitlab.md | GitLab, glab, CI/CD, job trace, merge request, DinD, Testcontainers, Surefire, Failsafe, glab api, pipeline stages, rules, cache, artifacts, interruptible, needs, DAG, glab issue create, file-based description, single quotes, permission prompts, GraphQL createDiffNote, emoji reactions, MR repointing, discussion 404 |

### Iter 6

**Group 2 (java/modified) results:**
- All 3 targets clean. testing.md (3 patterns), infosec-gotchas.md (7 bullets + 5 detailed), spring-boot-gotchas.md (20+ gotchas).
- infosec-gotchas.md Related→api-design.md validated. Cross-Refs section consistent with Related header.
- Spring Security 6 overlap between infosec-gotchas.md (scanner false positives) and integration.md (mechanics) confirmed as acceptable — different perspectives, adjudicated in Group 1.
- spring-boot-gotchas.md is dense (54 lines) but all patterns are Spring Boot-specific. Financial/PostgreSQL patterns contextualized through Spring Boot lens.
- No structural opportunities: no merge candidates (distinct domains), no split candidates (max 54 lines < 150 threshold).
- Observation: spring-boot-gotchas.md has self-aware cross-references between its own patterns (e.g., Optional.orElse(null) explicitly acknowledges the .orElseThrow() rule). Good internal consistency.

**Enriched keywords:**

| File | Keywords |
|------|----------|
| testing.md | duplicate assertions, TestNG, AfterClass, AfterMethod, BeforeMethod, test naming, lifecycle, resource leak, test method naming, behaviour-under-test |
| infosec-gotchas.md | authentication, authorization, CORS, deserialization, Jackson, XXE, Spring Security, @PreAuthorize, private method helper, HMAC timing attack, CWE-208, MessageDigest.isEqual, SpEL, security scanner, false positive, financial data logging, PII |
| spring-boot-gotchas.md | @Scheduled, ShedLock, CORS Customizer, Optional, switch null, Lombok builder, InterruptedException, SLF4J, Map.get null, ZoneId DST, properties quoting, MethodArgumentNotValidException, @ConfigurationProperties, @EnableConfigurationProperties, CGLIB, exception logging, stack trace, @Retryable RestClientException, @Data JPA, PostgreSQL transaction abort, @Transactional REQUIRES_NEW, financial fail-fast, @ExceptionHandler IllegalArgumentException, TransactionTemplate detached entities, ZoneOffset fixed-offset, log.debug WebSocket, LocalTime clock, Optional.orElse null, format string $n |

### Iter 5

**Group 1 (java/new) results:**
- All 3 target files well-structured from sweep 1 merges. 8 patterns, all standalone references, no overlap issues.
- Fixed stale Related in protobuf-patterns.md: `java-integration-patterns.md` → `java/integration.md` (pre-cluster flat name survived sweep 1).
- Spring Security 6 interceptor concept appears in both integration.md (mechanics) and infosec-gotchas.md (scanner false positive). Different perspectives, same cluster — no cross-ref needed.
- Observation: code-quality-instincts.md has 3 patterns appended after its Cross-Refs section (lines 116-123) — structurally misplaced, and 2 are domain-specific (Java timestamps, financial denomination). Not a target in this group, noted for future deep dive.

**Enriched keywords:**

| File | Keywords |
|------|----------|
| code-quality.md | fully-qualified imports, type prefix, TODO cleanup, dead code removal, method naming, refactor naming, Objects.equals, null-safe equality, SonarQube, boxing overhead |
| concurrency.md | ConcurrentHashMap, per-entity sync, polling throttle, sync interval, timestamp tracking, thread safety, HashSet race condition, TOCTOU, check-and-add, computeIfAbsent |
| integration.md | gRPC, proto builder, NullPointerException, null string field, Protobuf setter, Spring Security 6, EnableMethodSecurity, AuthorizationManager, interceptor stacking, PreAuthorize, AOP chain |

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
