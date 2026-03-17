# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 31 |
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
| 14 | DEEP_DIVE | 1 | 0 | 1 | 1 | corpus-cross-reference.md — 1 HIGH (fixed stale consumer description; learnings:curate not a consumer). 1 LOW: taxonomy overlap with content-mode.md (reference-file gate ambiguous). |
| 15 | DEEP_DIVE | 1 | 0 | 0 | 1 | platform-detection.md — 1 HIGH (added EDIT_CMD="gh pr edit"|"glab mr update" to Usage in Skills; $EDIT_CMD referenced in create-request but undefined). All 3 patterns STANDALONE REFERENCE, KEEP. |
| 16 | DEEP_DIVE | 0 | 0 | 0 | 0 | request-interaction-base.md — clean. 10 patterns all STANDALONE REFERENCE. 2 consumers verified (code-review-request, address-request-comments), no duplication. KEEP. |
| 17 | DEEP_DIVE | 0 | 0 | 0 | 0 | subagent-patterns.md — clean. 3 patterns all STANDALONE REFERENCE. 3 consumers verified, no inline dup. KEEP. |
| 18 | DEEP_DIVE | 0 | 0 | 0 | 0 | github/batch-operations.md — clean. 3 patterns all STANDALONE REFERENCE. 1 consumer (extract-request-learnings) verified, references by section name. No inline dup, no undefined vars. KEEP. |
| 19 | DEEP_DIVE | 1 | 0 | 1 | 1 | github/commands.md — index file clean. 1 HIGH: fixed stale path in extractor-prompt.md (referenced non-existent <PLATFORM>-commands.md; updated to <PLATFORM>/comment-interaction.md + <PLATFORM>/fetch-review-data.md). 1 LOW: index description for fetch-review-data.md omits consolidated variants. |
| 20 | DEEP_DIVE | 0 | 0 | 0 | 0 | github/comment-interaction.md — clean. 9 patterns all STANDALONE REFERENCE, KEEP. 1 consumer (extractor-prompt.md) delegates by section name. No inline dup, no undefined vars, no compression needed. |
| 21 | DEEP_DIVE | 0 | 0 | 0 | 0 | github/fetch-review-data.md — clean. 6 patterns all STANDALONE REFERENCE. 3 consumers (split-request, explore-request, extractor-prompt.md). No inline dup, no undefined vars, no compression needed. |
| 22 | DEEP_DIVE | 1 | 0 | 0 | 1 | github/pr-management.md — 1 HIGH: fixed broken `$LIST_CMD <current-branch>` in create-request step 5 (gh/glab list has no positional branch arg; should delegate to "Check for Existing Review" section). Reference file itself KEEP — 5 patterns all STANDALONE REFERENCE. |
| 23 | DEEP_DIVE | 0 | 0 | 0 | 0 | gitlab/batch-operations.md — clean. 3 patterns all STANDALONE REFERENCE. 1 consumer (extract-request-learnings) verified, references by section name. No inline dup. :id is glab-native auto-substitution. KEEP. |
| 24 | DEEP_DIVE | 0 | 0 | 1 | 0 | gitlab/commands.md — clean index. All 4 cluster files present. No skills reference index directly. 1 LOW: fetch-review-data.md description omits "Fetch Activity Signals (consolidated)" — same style question as [L-2]. extractor-prompt.md path fix from iter 19 covers gitlab. KEEP. |
| 25 | DEEP_DIVE | 0 | 0 | 1 | 0 | gitlab/comment-interaction.md — clean. 8 patterns all STANDALONE REFERENCE. 1 consumer verified (extractor-prompt.md). No inline dup, no undefined vars. 1 LOW: missing Edit Inline Comment section vs github counterpart. KEEP. |
| 26 | DEEP_DIVE | 1 | 0 | 0 | 1 | gitlab/fetch-review-data.md — 1 HIGH: fixed stale cross-reference section name ("Fetch Latest Inline Comment" → "Fetch Recent Inline Comments"). 5 patterns all STANDALONE REFERENCE. 3 consumers verified. KEEP. |
| 27 | DEEP_DIVE | 0 | 0 | 0 | 0 | gitlab/pr-management.md — clean. 5 patterns all STANDALONE REFERENCE. 5 consumers verified (create-request, code-review-request, re-review-mode, address-request-comments, address-request-edge-cases). KEEP. |
| 28 | DEEP_DIVE | 0 | 0 | 0 | 0 | do-refactor-code/SKILL.md — clean. KEEP. Refs valid: code-quality-checklist.md (iter 13 ✅), refactoring-patterns.md (exists ✅). No overlap, scope correct, description accurate. |
| 29 | DEEP_DIVE | 0 | 0 | 0 | 0 | do-security-audit/SKILL.md — clean. KEEP. 1 ref: subagent-patterns.md (iter 17 ✅). 6-step workflow clean, 7-item checklist appropriate scope, allowed-tools match usage, no overlap. |
| 30 | DEEP_DIVE | 1 | 0 | 0 | 1 | explore-repo/SKILL.md — 1 HIGH (added Bash to allowed-tools). Phase 1 git diff staleness detection and stale file deletion need Bash for autonomous execution. References valid. KEEP. |
| 31 | DEEP_DIVE | 0 | 0 | 0 | 0 | explore-repo/brief/SKILL.md — clean. 5 phases, all well-designed. No explicit skill-reference reads. Permissive allowed-tools (no declaration = unrestricted, fine for read-only brief). KEEP. |

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
| 11 | .claude/skill-references/corpus-cross-reference.md | 2 | unreviewed (6) | done | 14 | 1 HIGH applied — fixed stale consumer description (removed learnings:curate claim). 1 LOW: Coverage Match Types taxonomy overlap with content-mode.md step 3. 2 patterns both STANDALONE REFERENCE. KEEP. |
| 12 | .claude/skill-references/platform-detection.md | 2 | unreviewed (6) | done | 15 | 1 HIGH applied — added EDIT_CMD to Usage in Skills variable block ($EDIT_CMD used in create-request but undefined). 7 consumers confirmed. All 3 patterns STANDALONE REFERENCE, KEEP. |
| 13 | .claude/skill-references/request-interaction-base.md | 2 | unreviewed (6) | done | 16 | Clean — 10 patterns all STANDALONE REFERENCE. 2 consumers verified, no duplication, no undefined vars. KEEP. |
| 14 | .claude/skill-references/subagent-patterns.md | 2 | unreviewed (6) | done | 17 | Clean — 3 patterns all STANDALONE REFERENCE. 3 consumers verified (parallel-plan/execute, explore-repo, do-security-audit), no inline dup. Thematic overlap with multi-agent-patterns.md properly handled via existing See also. KEEP. |
| 15 | .claude/skill-references/github/batch-operations.md | 2 | unreviewed (6) | done | 18 | Clean — 3 patterns all STANDALONE REFERENCE. 1 consumer (extract-request-learnings) verified, references by section name, no inline dup. Index description accurate. KEEP. |
| 16 | .claude/skill-references/github/commands.md | 2 | unreviewed (6) | done | 19 | 1 HIGH: fixed stale path ref in extractor-prompt.md (<PLATFORM>-commands.md → <PLATFORM>/comment-interaction.md + fetch-review-data.md). 1 LOW: index description omits consolidated variants. Index itself STANDALONE REFERENCE, KEEP. |
| 17 | .claude/skill-references/github/comment-interaction.md | 2 | unreviewed (6) | done | 20 | Clean — 9 patterns all STANDALONE REFERENCE. 1 consumer (extractor-prompt.md) delegates by section name, no inline dup. No undefined vars, no compression needed. KEEP. |
| 18 | .claude/skill-references/github/fetch-review-data.md | 2 | unreviewed (6) | done | 21 | Clean — 6 patterns all STANDALONE REFERENCE. 3 consumers (split-request, explore-request, extractor-prompt.md), no inline dup. No undefined vars. KEEP. |
| 19 | .claude/skill-references/github/pr-management.md | 2 | unreviewed (6) | done | 22 | 1 HIGH: fixed broken `$LIST_CMD <current-branch>` in create-request step 5 (missing `--head` flag). Reference file clean — 5 patterns all STANDALONE REFERENCE. 4 consumers verified (create-request, code-review-request, address-request-comments, address-request-edge-cases.md), all delegate by section name. KEEP. |
| 20 | .claude/skill-references/gitlab/batch-operations.md | 2 | unreviewed (6) | done | 23 | Clean — 3 patterns all STANDALONE REFERENCE. 1 consumer (extract-request-learnings) verified, references by section name. No inline dup. KEEP. |
| 21 | .claude/skill-references/gitlab/commands.md | 2 | unreviewed (6) | done | 24 | Clean index — all 4 cluster files present, no direct consumers, nav guidance correct. 1 LOW: fetch-review-data.md description omits "Fetch Activity Signals (consolidated)" [L-3]. KEEP. |
| 22 | .claude/skill-references/gitlab/comment-interaction.md | 2 | unreviewed (6) | done | 25 | Clean — 8 patterns all STANDALONE REFERENCE. 1 consumer (extractor-prompt.md), delegates by section name. No inline dup, no undefined vars. 1 LOW: missing Edit Inline Comment vs github counterpart. KEEP. |
| 23 | .claude/skill-references/gitlab/fetch-review-data.md | 2 | unreviewed (6) | done | 26 | 1 HIGH: fixed stale cross-reference section name ("Fetch Latest Inline Comment" → "Fetch Recent Inline Comments" in comment-interaction.md). 5 patterns all STANDALONE REFERENCE. 3 consumers verified (split-request, explore-request, extractor-prompt.md). KEEP. |
| 24 | .claude/skill-references/gitlab/pr-management.md | 2 | unreviewed (6) | done | 27 | Clean — 5 patterns all STANDALONE REFERENCE. 5 consumers verified (create-request, code-review-request, re-review-mode.md, address-request-comments, address-request-edge-cases.md). No undefined vars (:id = glab auto). KEEP. |
| 25 | .claude/commands/do-refactor-code/SKILL.md | 2 | unreviewed (6) | done | 28 | Clean — SKILL.md only, both refs valid, no overlap, KEEP. |
| 26 | .claude/commands/do-security-audit/SKILL.md | 2 | unreviewed (6) | done | 29 | Clean — SKILL.md only, 1 ref (subagent-patterns.md ✅), 6-step workflow, 7-item checklist, allowed-tools match usage. KEEP. |
| 27 | .claude/commands/explore-repo/SKILL.md | 2 | unreviewed (6) | done | 30 | 1 HIGH applied — added Bash to allowed-tools (needed for git diff staleness detection and file deletion in Phase 1). References valid. KEEP. |
| 28 | .claude/commands/explore-repo/brief/SKILL.md | 2 | unreviewed (6) | done | 31 | Clean — 5 phases, all well-designed. No refs, no undefined vars, permissive allowed-tools (fine for read-only brief). KEEP. |
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

### Iter 21

**Deep dive 18 of 30**: `github/fetch-review-data.md` (skill-reference, unreviewed, tier 2) — CLEAN.
- 6 patterns: Fetch Review Details (core metadata), Fetch Review Details with Reviews (consolidated, no --jq), Fetch Activity Signals (consolidated, no --jq), Fetch Diff, Fetch Files Changed (--jq for path extraction), Fetch Commits (--jq with .oid[0:7] truncation). All STANDALONE REFERENCE.
- Consumer verification (reference-file gate): 3 consumers — `split-request/SKILL.md:26-30`, `explore-request/SKILL.md:28-41` (references by section name: "Fetch Review Details", "Fetch Files Changed"), `extractor-prompt.md:26`. None inline content. ✅
- Variable check: `<number>` is the only placeholder — all consumers substitute. No state variables, no undefined names. ✅
- Scope note: `resolve-conflicts` uses inline `gh pr view` commands for different fields (headRefName/baseRefName for rebase workflow, mergeable for post-merge validation). These are not duplication of reference patterns — different purpose, different fields, not a consumer of this file. No action.
- No compression opportunity (48 lines, 6 templates with context comments, maximally concise).
- No See also needed — discoverable via `github/commands.md` index; consumers reference directly.
- Key insight: When a skill-reference has some patterns with "No --jq" and some with "--jq", this is intentional design: "No --jq" annotations document patterns that CAN skip jq (full JSON is agent-parseable), while patterns that need jq for extraction use it. The contrast is documented inline — don't flag as inconsistency. A sibling skill with its own inline `gh pr view` commands for different fields (different purpose, not a declared consumer) is NOT duplication — check consumer declarations before flagging inline usage.
- Next: candidate 19 = `github/pr-management.md` (skill-reference, unreviewed, tier 2).

### Iter 27

**Deep dive 24 of 30**: `gitlab/pr-management.md` (skill-reference, unreviewed, tier 2) — CLEAN.
- 5 patterns: Create or Update MR (Body via File), Post Review with Inline Comments (3-step: inline discussions POST → summary top-level comment → cleanup), Checkout Review Branch, Check for Existing Review, Find Approved Reviewers (LGTM test with jq). All STANDALONE REFERENCE.
- Consumer verification (reference-file gate): 5 consumers — `create-request/SKILL.md` (step 10 = Create or Update MR; step 5 = Check for Existing Review), `code-review-request/SKILL.md:150` (Post Review), `re-review-mode.md:79` (Post Review), `address-request-comments/SKILL.md:43` (Checkout Review Branch), `address-request-edge-cases.md:81` (Find Approved Reviewers). All 5 sections have ≥1 consumer delegating by section name. No inline duplication. ✅
- Variable check: `<BRANCH_NAME>`, `<base-branch>`, `<title>`, `<number>`, `<note_index>`, `<base_sha>`, `<head_sha>`, `<file_path>`, `<line_number>`, `<branch-name>`, `<source_branch>` — all user placeholders, substituted by consumers. `:id` = glab auto-resolution. No undefined state variables. ✅
- Structural symmetry with `github/pr-management.md`: same 5 sections, platform differences correct (glab commands, `--source-branch` vs `--head`, `--description` vs `--body`, discussions POST vs review API). ✅
- `$(cat ...)` in `--description` flag: intentional write-file-first pattern to avoid quoting issues — consistent with GitHub counterpart and spec comment in file. ✅
- `jq test("LGTM"; "i")` in Find Approved Reviewers: case-insensitive regex test, not `!=` — does NOT violate the jq `!=` avoidance rule. ✅
- No compression needed (69 lines, 5 sections with context). No See also needed (discoverable via gitlab/commands.md index).
- Next: candidate 25 = `do-refactor-code/SKILL.md` (skill, unreviewed, tier 2).

### Iter 29

**Deep dive 26 of 30**: `do-security-audit/SKILL.md` (skill, unreviewed, tier 2) — CLEAN.
- SKILL.md only (no additional files in directory).
- References: `~/.claude/skill-references/subagent-patterns.md` (verified iter 17) ✅. Single reference appropriate — skill is a consumer of subagent orchestration patterns.
- 6-step workflow: identify targets → run checklist (parallel Explore subagents) → check dead security code → assess deployment risk → compare (multi-project only) → report. All distinct, non-overlapping.
- 7-item security checklist: API input validation, secrets/credentials, CSP/security headers, rate limiting (wired check), CORS, dependency versions (with WebFetch for CVE lookup), error message leakage. Appropriate scope for surface-level web audit.
- Allowed tools: Read, Glob, Grep (exploration), Task (parallel agents), WebFetch (CVE databases per step 2). All match skill's actual usage.
- "Important Notes" section correctly scopes the skill: surface-level audit, not pen test, extend for domain-specific risks. Appropriate epistemic framing.
- Relevance: security audits are a recurring task. KEEP.
- Next: candidate 27 = `explore-repo/SKILL.md` (skill, unreviewed, tier 2).

### Iter 31

**Deep dive 28 of 30**: `explore-repo/brief/SKILL.md` (skill, unreviewed, tier 2) — CLEAN.
- 5 phases: locate artifacts (Glob + Bash git freshness), load context (Read), print brief (conversation output), persona suggestion (conditional Glob), ready for Q&A.
- No `@` references or skill-reference reads — correct, brief is standalone (reads directly from docs/learnings/ repo path).
- Variable check: `$ARGUMENTS`, `<path>`, `<scan-commit>`, `<artifact-path>`, `<hash>`, `<branch>`, `<date>`, `<current>` — all properly documented. No undefined state variables.
- Git diff syntax `':!<artifact-path>/'` excludes scan artifacts from staleness check — valid git pathspec, correct design.
- No `allowed-tools` in frontmatter (permissive). Sibling explore-repo/SKILL.md has explicit list (after iter 30 fix). Brief is simpler (no Task spawning, no Write) — permissive default is acceptable.
- SYSTEM_OVERVIEW.md gate: 4 error conditions properly handled (no files, partial scan, complete but not synthesized, complete). ✅
- Domain file lazy-loading (through Key Findings only) — good context budget management. ✅
- Persona detection: conversation-based, no state file. ✅
- Overlap: none with explore-repo (generates artifacts), do-security-audit (different domain), any other skill. ✅
- Key insight: A companion skill to a complex orchestrator may legitimately be simpler and omit explicit allowed-tools — check whether the skill spawns subagents or writes files. If read-only (Glob + Read + Bash for git info), permissive default is fine. The issue in explore-repo/SKILL.md was that Bash was LISTED but missing from an existing allowed-tools block — different from absent entirely.
- Next: candidate 29 = `git/address-request-comments/SKILL.md` (skill, unreviewed, tier 2).

### Iter 30

**Deep dive 27 of 30**: `explore-repo/SKILL.md` (skill, unreviewed, tier 2) — 1 HIGH applied.
- Directory contains: SKILL.md + agent-prompts.md (sibling reference) + brief/SKILL.md (companion skill). This deep dive covers SKILL.md only.
- References: @agent-prompts.md (sibling, verified present ✅); `~/.claude/skill-references/subagent-patterns.md` (verified iter 17 ✅).
- HIGH applied: Added Bash to allowed-tools. Phase 1 step 3 (`git diff --stat <stale-commit>..HEAD`) is core to smart staleness detection — runs before relaunching stale domain agents. Phase 1 step 4 (delete stale SYSTEM_OVERVIEW.md and inconsistencies.md) also needs Bash (no dedicated delete tool). Context section injects HEAD/branch/root via `!` commands at load time — Phase 1 step 2 queries don't need Bash.
- WebFetch in allowed-tools: orchestrator doesn't use WebFetch directly in any of the 6 phases. Subagents (launched via Task) have their own tool access. WebFetch presence is benign — LOW, no action.
- 6-phase workflow: mode detection → project detection → parallel exploration (7 domain agents) → scan summary → synthesis → validation & summary. Scan and synthesis are always separate invocations (clean context for synthesis). KEEP.
- Overlap: none with explore-repo:brief (summary mode, reads existing artifacts, different scope) or do-security-audit (different domain). No duplication.
- Key insight: When a skill has `!` command injections in the Context header (project root, branch, HEAD), those values are pre-computed at load time and available to the agent as context. Steps that reference "run git rev-parse --short HEAD" are often satisfied by the injected values — but steps that need *dynamic* git operations (diff since a stored commit hash, staleness comparison) still require Bash. The dividing line: static state injected at load = no Bash; dynamic comparison at runtime = Bash needed.
- Next: candidate 28 = `explore-repo/brief/SKILL.md` (skill, unreviewed, tier 2).

### Iter 28

**Deep dive 25 of 30**: `do-refactor-code/SKILL.md` (skill, unreviewed, tier 2) — CLEAN.
- SKILL.md only (no additional files in directory).
- References: `~/.claude/skill-references/code-quality-checklist.md` (read at step 2, verified iter 13) ✅ and `~/.claude/learnings/refactoring-patterns.md` (read at step 4 for large-file decomposition patterns, exists) ✅. Both paths use `~/.claude/` prefix (correct for Read tool).
- Relevance: active workflow, code refactoring is a common task. KEEP.
- Overlap: none — `do-security-audit` is a different domain; `parallel-plan/execute` shares `code-quality-checklist.md` via skill-references (correct pattern, not duplication). `refactoring-patterns.md` in learnings has 3 See-also cross-refs (react-patterns, code-quality-instincts, claude-authoring-skills) but `do-refactor-code` is the only skill that actually reads it for execution — appropriate as learnings, not skill-references.
- Scope: 6 refactoring categories (helper class, helper method, nested function, test factory, large file decomposition, general structural), all distinct and non-overlapping. Appropriate scope.
- Description accuracy: "Analyze a file for refactoring opportunities and apply selected improvements" matches 5-step workflow. argument-hint "[filepath]" accurate.
- Next: candidate 26 = `do-security-audit/SKILL.md` (skill, unreviewed, tier 2).

### Iter 26

**Deep dive 23 of 30**: `gitlab/fetch-review-data.md` (skill-reference, unreviewed, tier 2) — 1 HIGH applied.
- 5 patterns: Fetch Review Details, Fetch Activity Signals (consolidated), Fetch Diff, Fetch Files Changed (sed pipeline — no `--name-only` flag), Fetch Commits. All STANDALONE REFERENCE.
- Consumer verification: 3 consumers — `split-request/SKILL.md:26,30`, `explore-request/SKILL.md:28,32,41`, `extractor-prompt.md:26`. All delegate by reference/section name; no inline content. ✅
- HIGH applied: "Fetch Activity Signals (consolidated)" cross-reference said "Fetch Latest Inline Comment" — but the actual section in `gitlab/comment-interaction.md` is "Fetch Recent Inline Comments (quick-exit check)". Fixed to correct section name.
- Variable check: `<number>` is the only user placeholder; `:id` is glab auto-resolution. No undefined variables. ✅
- Note: "Fetch Review Details" and "Fetch Activity Signals" use identical commands (`glab mr view <number> --output json`) — intentional, since `glab mr view` returns comprehensive JSON. Distinction is conceptual guidance for consumers.
- No compression needed (45 lines, 5 templates). No See also needed — discoverable via gitlab/commands.md index.
- Next: candidate 24 = `gitlab/pr-management.md` (skill-reference, unreviewed, tier 2).

### Iter 25

**Deep dive 22 of 30**: `gitlab/comment-interaction.md` (skill-reference, unreviewed, tier 2) — CLEAN.
- 8 patterns: pre-header meta-rules (jq `!=` avoidance, use-verbatim mandate), Fetch Inline/Review Comments (full+incremental), Fetch Recent Inline Comments (quick-exit, 3-case with LAST_REVIEW_TS), Fetch General Review Comments (discussions endpoint, no `updated_after`, compare count vs LAST_REVIEW_COUNT), Fetch Issue/Top-Level Comments (`select(.position == null)`, full+incremental), Reply to Inline Comment (write-file-first, `-F body=@` absolute path, POST to `discussions/:id/notes`), React to Comment (award_emoji endpoint), Post Top-Level Comment (`glab mr comment $(cat ...)`, no `--body-file` workaround note). All STANDALONE REFERENCE.
- Consumer verification: 1 consumer — `extractor-prompt.md:26`. References "Fetch Inline/Review Comments" (full variant) and "Fetch Issue/Top-Level Comments" by section name. No inline duplication. ✅
- Variable check: `<number>`, `<TS>`, `<discussion_id>`, `<note_id>`, `<persona>`, `<role>`, `<emoji>` — all placeholders, substituted by consumers. `LAST_REVIEW_TS`/`LAST_REVIEW_COUNT` defined in `request-interaction-base.md`. `:id` is glab auto-resolution. ✅
- LOW [L-4]: Missing "Edit Inline Comment" section vs `github/comment-interaction.md`. GitHub needed it for PATCH endpoint path gotcha (`pulls/comments/<id>` vs `pulls/<num>/comments/<id>`). GitLab equivalent is `PATCH /projects/:id/merge_requests/:iid/notes/:note_id` — simpler, no documented gotcha. Omission may be intentional.
- No compression needed (84 lines, 8 sections, maximally concise). No See also needed.
- Key insight: When a platform counterpart (`gitlab/X.md`) is structurally symmetric to `github/X.md`, the deep dive must still verify independently: (1) consumer list may differ, (2) section coverage may differ (e.g., Edit Inline Comment present in github, absent in gitlab), (3) API differences are always per-platform. Structural symmetry is not equivalence.
- Next: candidate 23 = `gitlab/fetch-review-data.md` (skill-reference, unreviewed, tier 2).

### Iter 24

**Deep dive 21 of 30**: `gitlab/commands.md` (skill-reference index, unreviewed, tier 2) — CLEAN.
- Index file: 4 cluster entries (fetch-review-data, comment-interaction, pr-management, batch-operations). All 4 cluster files confirmed present via Glob. Index description accurate: "Skills should reference specific cluster files, not this index."
- Consumer verification: Grep for `gitlab/commands` found only logs + progress.md — no skills reference this index directly. ✅ Correct — skills reference cluster files directly per the navigation guidance.
- Description accuracy check:
  - batch-operations.md: ✅ (verified iter 23 — 3 patterns match)
  - pr-management.md: ✅ (visible sections match: Create or Update MR, Post Review)
  - comment-interaction.md: ✅ (visible sections match: Fetch Inline/Review Comments)
  - fetch-review-data.md: "Fetch Review Details, Diff, Files Changed, Commits" — omits "Fetch Activity Signals (consolidated)" [L-3]
- extractor-prompt.md path (iter 19 HIGH fix): Uses `<PLATFORM>/comment-interaction.md` + `<PLATFORM>/fetch-review-data.md` — covers gitlab automatically. ✅ No separate fix needed for gitlab.
- LOW [L-3]: Same style question as [L-2] (github/commands.md) — whether index descriptions should be exhaustive or summary-level. Not operationally breaking.
- Key insight: When an index file has a symmetric counterpart (github/commands.md ↔ gitlab/commands.md), the github counterpart's deep dive (iter 19) validates the pattern but NOT the description accuracy of the gitlab version — each index must be checked independently because description accuracy depends on the actual cluster file sections, which may differ between platforms. In this case, `Fetch Activity Signals (consolidated)` exists in both the github AND gitlab `fetch-review-data.md` — the description omission is consistent across both index files and flags the same LOW [L-2] / [L-3] pattern.
- Next: candidate 22 = `gitlab/comment-interaction.md` (skill-reference, unreviewed, tier 2).

### Iter 23

**Deep dive 20 of 30**: `gitlab/batch-operations.md` (skill-reference, unreviewed, tier 2) — CLEAN.
- 3 patterns: Fetch Review Metadata (Batch) (batch `glab api` + `jq` pipeline for MR extraction), Verify Platform Access (Batch) (API access check), Count Total Reviews (x-total header via --include). All STANDALONE REFERENCE.
- Consumer verification (reference-file gate): 1 consumer — `extract-request-learnings/SKILL.md:53-78`. Explicitly listed in Reference Files section. Consumer references by section name (step 2 = "Verify Platform Access (Batch)", step 3 = "Count Total Reviews", step 6 = "Fetch Review Metadata (Batch)"). No inline content duplication. ✅
- Variable check: `:id` is glab-native auto-substitution (NOT a user placeholder — `glab api` resolves it from git remote automatically); `<SIZE>`/`<PAGE>` are explicit placeholders substituted by consumer (`BATCH_SIZE` from plan file, `NEXT_PAGE` calculated). `$API_CMD` referenced in consumer steps is defined in platform-detection.md. No undefined variables. ✅
- Structural symmetry with `github/batch-operations.md`: same 3-pattern structure, same pre-section verbatim-use directive. API differences correct: `glab api` vs `gh api`, `projects/:id/merge_requests` vs `repos/{owner}/{repo}/pulls`, `x-total` header vs `x-total-count`. All per-platform conventions. ✅
- No compression opportunity (29 lines, 3 bash templates with context comments, maximally concise).
- No See also needed — discoverable via consumer's explicit reference; no second index file present.
- Key insight: In `glab api`, `:id` is a magic placeholder auto-resolved from the git remote to the URL-encoded project path — it is NOT a user-substituted placeholder like `<SIZE>` or `<PAGE>`. When reviewing GitLab skill-reference files, do not flag `:id` as an "undefined variable" — it is resolved by the CLI, not the agent. Verify that consumer substitutes only `<UPPERCASE>` or `{braced}` placeholders, not `:lowercase` ones.
- Next: candidate 21 = `gitlab/commands.md` (skill-reference, unreviewed, tier 2).

### Iter 22

**Deep dive 19 of 30**: `github/pr-management.md` (skill-reference, unreviewed, tier 2) — 1 HIGH applied.
- 5 patterns: Create or Update PR (Body via File), Post Review with Inline Comments, Checkout Review Branch, Check for Existing Review, Find Approved Reviewers. All STANDALONE REFERENCE.
- Consumer verification (reference-file gate): 4 consumers — `create-request/SKILL.md` (Create or Update PR at step 10), `code-review-request/SKILL.md` (Post Review at step 11), `re-review-mode.md` (Post Review at step c), `address-request-comments/SKILL.md` (Checkout Review Branch at step 3), `address-request-edge-cases.md` (Find Approved Reviewers). All delegate by section name. `request-interaction-base.md` references for platform cluster loading (not a section consumer). ✅
- HIGH applied: `create-request/SKILL.md:65-66` — `$LIST_CMD <current-branch>` is broken syntax. `gh pr list` and `glab mr list` have no positional branch argument; the `--head` / `--source-branch` filter flag is silently dropped. Fix: replaced inline `$LIST_CMD` invocation with delegation to "Check for Existing Review" section by name, consistent with how steps 10 and 11 reference cluster file sections.
- Variable check: `{owner}/{repo}` (API path params), `<number>`, `<base-branch>`, `<title>`, `<headRefName>`, `<branch-name>` — all placeholders, substituted by consumers. No undefined state variables. EDIT_CMD defined in platform-detection.md (iter 15). ✅
- No compression needed (70 lines, 5 templates with context, maximally concise).
- No See also needed — cluster files discoverable via `github/commands.md` index; consumers reference directly.
- Key insight: When verifying consumers of a platform cluster file, check that consumers using platform-abstracted variables (e.g., `$LIST_CMD`, `$CREATE_CMD`) actually include the required flags. `$LIST_CMD` is `gh pr list` but does NOT include `--head` — so `$LIST_CMD <branch>` silently drops the filter. The reference file correctly shows the full template with flags; the consumer bypassed the template and lost the flag in the process.
- Next: candidate 20 = `gitlab/batch-operations.md` (skill-reference, unreviewed, tier 2).

### Iter 20

**Deep dive 17 of 30**: `github/comment-interaction.md` (skill-reference, unreviewed, tier 2) — CLEAN.
- 9 patterns: pre-header meta-rules (jq != avoidance, use-verbatim mandate), Fetch Inline/Review Comments (full+incremental), Fetch Recent Inline Comments (quick-exit polling with 3-case interpretation), Fetch General Review Comments (no-since-filter + LAST_REVIEW_COUNT workaround), Fetch Issue/Top-Level Comments, Reply to Inline Comment (write-file-first + absolute paths), Edit Inline Comment (PATCH endpoint path gotcha — `pulls/comments/<id>` not `pulls/<num>/comments/<id>`), React to Comment (-f not -F + dual endpoints for inline vs issue), Post Top-Level Comment. All STANDALONE REFERENCE.
- Consumer verification (reference-file gate): 1 consumer — `extractor-prompt.md:26`. Delegates to this file by section name ("use these sections from those files"). No inline duplication. Other references in skill-references/ cluster are index entries or cross-reference pointers, not consumers.
- Variable check: all placeholders (`{owner}/{repo}`, `<number>`, `<TS>`, `<comment_id>`, `<emoji>`) are template params. State vars (`LAST_REVIEW_TS`, `LAST_REVIEW_COUNT`) defined in consumers or `request-interaction-base.md`. No undefined variables.
- No compression opportunity (~10 lines/pattern including bash code examples — already tight).
- No See also needed — cluster files discoverable via `github/commands.md` index; consumers reference directly.
- Key insight: When a skill-reference file has a pre-section meta-instruction block (before any H2 headers), verify it's not duplicated in consumers. In this case, "Never use != in jq" and "Use templates verbatim" are architectural rules for ALL templates in the file — they belong at the top and do NOT need to be repeated per-section. The pre-header location is the correct placement for rules that govern the entire file's usage.
- Next: candidate 18 = `github/fetch-review-data.md` (skill-reference, unreviewed, tier 2).

### Iter 19

**Deep dive 16 of 30**: `github/commands.md` (skill-reference index, unreviewed, tier 2) — 1 HIGH applied.
- Index file: 4 cluster entries (fetch-review-data, comment-interaction, pr-management, batch-operations). All 4 cluster files confirmed present. Index description says "Skills should reference specific cluster files, not this index" — correct navigation guidance.
- HIGH applied: `extractor-prompt.md:26` referenced `~/.claude/skill-references/<PLATFORM>-commands.md` (flat-file pattern, doesn't exist). Actual structure is `<PLATFORM>/comment-interaction.md` + `<PLATFORM>/fetch-review-data.md`. SKILL.md already uses correct subdirectory pattern — extractor-prompt.md was not updated when directory structure was reorganized.
- LOW [L-2]: `fetch-review-data.md` index description omits "Fetch Activity Signals (consolidated)" — unclear whether summaries should list all section names or just core categories.
- Key insight: When a skill has multiple prompt-template files (extractor-prompt.md, writer-prompt.md, plan-template.md) alongside the main SKILL.md, verify each file's paths independently — reorganizations that update SKILL.md often miss the subagent-injected templates.
- Next: candidate 17 = `github/comment-interaction.md` (skill-reference, unreviewed, tier 2).

### Iter 18

**Deep dive 15 of 30**: `github/batch-operations.md` (skill-reference, unreviewed, tier 2) — CLEAN.
- Consumer verification (reference-file gate): 1 consumer — `extract-request-learnings/SKILL.md`. Explicitly referenced in Reference Files section. Consumer uses section names to call specific templates (no inline duplication).
- 3 patterns: Fetch Review Metadata (Batch) (batch `gh api` + `jq` pipeline for multi-PR extraction), Verify Platform Access (Batch) (API access check), Count Total Reviews (Link header pagination count). All STANDALONE REFERENCE.
- Corpus cross-ref: `fetch-review-data.md` covers single-PR `gh pr view` commands — distinct scope, no overlap. `github/commands.md` is the index that correctly categorizes this file. No duplication.
- Variable check: `{owner}`/`{repo}` are API path params; `<SIZE>`/`<PAGE>` are explicit placeholders. Consumer substitutes `$API_CMD` (from platform-detection), `BATCH_SIZE` (from plan file), `NEXT_PAGE` (calculated) — all defined correctly. ✅
- Index description accurate — "Batch operations | batch-operations.md | Fetch Review Metadata, Verify Access, Count Total (for extract-request-learnings)".
- No compression opportunity (29 lines, 3 bash templates, maximally concise).
- No See also needed — cluster files discoverable via commands.md index; consumer references directly.
- Key insight: When a skill-reference cluster file has only 1 consumer (vs. the typical multi-consumer pattern), verify that the clustering is intentional — the operations may be consumer-specific but still benefit from being in a reference file (verbatim templates, versioned alongside other cluster files, discoverable via index). "Single consumer" is not a signal to fold back into the consumer unless the content is truly consumer-specific in a way that makes it non-reusable (e.g., hardcoded to that consumer's state variables).
- Next: candidate 16 = `github/commands.md` (skill-reference, unreviewed, tier 2). Note: this is the index file — likely a lightweight audit (check all clusters listed are present, descriptions accurate).

### Iter 17

**Deep dive 14 of 30**: `subagent-patterns.md` (skill-reference, unreviewed, tier 2) — CLEAN.
- Consumer verification (reference-file gate): 3 consumers — `parallel-plan/execute/SKILL.md`, `explore-repo/SKILL.md`, `do-security-audit/SKILL.md`. All reference via Reference Files sections. No inline content duplication in any consumer.
- 3 patterns: Verify Output Before Acting (spot-check key claim before acting on subagent output), Write Output to Intermediate Files (agents write to disk, return 2-3 sentence summary, synthesis reads files with clean context), Use Structured Templates Over Hard Size Limits (templates naturally constrain output better than hard line counts). All STANDALONE REFERENCE.
- Corpus cross-ref: Pattern 2 ("Write Output to Intermediate Files") has thematic overlap with `multi-agent-patterns.md` §"Dedicated Synthesis Context" — but `multi-agent-patterns.md` already has `## See also` pointing here. Relationship properly established; learnings version provides richer orchestration context, reference version is canonical universal guidance. No action.
- No compression opportunity (40 lines, 3 patterns with Why/Pattern structure, already concise).
- No See also needed — `multi-agent-patterns.md` → `subagent-patterns.md` already exists; reverse is vocabulary-discoverable via "subagent" keyword.
- Key insight: When a skill-reference has thematic overlap with a learnings file, check bidirectionality of cross-refs before flagging as redundancy. If `multi-agent-patterns.md` See also already points to the reference, the relationship is properly established — the learnings version provides richer "why/alternative" context while the reference provides concise universal guidance. This is complementary depth, not duplication.
- Next: candidate 15 = `github/batch-operations.md` (skill-reference, unreviewed, tier 2).

### Iter 16

**Deep dive 13 of 30**: `request-interaction-base.md` (skill-reference, unreviewed, tier 2) — CLEAN.
- Consumer verification (reference-file gate): 2 consumers — `code-review-request/SKILL.md` and `address-request-comments/SKILL.md`. Both explicitly reference the file in their "Reference Files" sections. Description accurate (no stale claims).
- 10 patterns: Platform Detection, Consolidated Fetch, Terminal State Handling, Incremental Fetch Rules, Comment Identity, Footnote Format, Reply File Naming, Mutual Resolution Filter, Quiet No-Op, Stale Poll Auto-Cancel. All STANDALONE REFERENCE — shared operational logic, not duplicated in either consumer.
- Variable cross-check: REQUEST_NUMBER/TITLE/HEAD_BRANCH/BASE_BASE_BRANCH defined in Consolidated Fetch ✅; LAST_FETCH_TS/LAST_REVIEW_COUNT defined in Incremental Fetch Rules ✅; POLL_LAST_ACTIVITY_<N> defined in Stale Poll Auto-Cancel ✅; REVIEW_UNIT/CLI supplied by platform-detection.md (deep-dived at iter 15) ✅; YOUR_ROLE/OTHER_ROLE defined in each consumer ✅. No undefined variables.
- Quiet No-Op format in base reference differs from code-review-request's "no changes since last review" message — these are different scenarios (incremental fetch vs. re-review detection), not duplication.
- No compression opportunity (110 lines, 10 distinct patterns, no provenance, no redundant rationale).
- No See also needed — platform-detection.md and cluster files referenced explicitly in Platform Detection section.
- Key insight: Skill-references serving polling skills need to distinguish between two structurally similar but semantically different no-op scenarios: (a) incremental fetch returned zero new comments (Quiet No-Op), (b) re-review mode detected nothing changed since last review. Don't conflate these — they use different state variables (LAST_FETCH_TS vs LAST_REVIEW_TS) and have different skip conditions. When reviewing polling skill-references, check that these two scenarios are handled separately.
- Next: candidate 14 = `subagent-patterns.md` (skill-reference, unreviewed, tier 2).

### Iter 15

**Deep dive 12 of 30**: `platform-detection.md` (skill-reference, unreviewed, tier 2) — 1 HIGH applied.
- Reference-file gate: 7 consumers — create-request, resolve-conflicts, split-request, explore-request, repoint-branch, extract-request-learnings (6 skills) + request-interaction-base.md (skill-ref). Neither inlines detection logic — all delegate to this file.
- HIGH applied: `$EDIT_CMD` was used in `create-request/SKILL.md:69` but not defined in any reference file. Added `EDIT_CMD="gh pr edit"|"glab mr update"` (GitHub from github/pr-management.md, GitLab from gitlab/pr-management.md).
- 3 patterns: Detection Logic (ordered checks: git remote → directory markers → ask user), Platform Mapping (lookup table), Usage in Skills (variable naming convention). All STANDALONE REFERENCE, KEEP.
- Key insight: When a skill-reference defines platform variable names (CLI, REVIEW_UNIT, CREATE_CMD, etc.), verify all variable names used in consumers are actually defined. Self-referential gaps are easy to miss because the variable name ($EDIT_CMD) looks plausible — the missing definition is invisible until you cross-check consumer usage.
- Next: candidate 13 = `request-interaction-base.md` (skill-reference, unreviewed, tier 2).

### Iter 14

**Deep dive 11 of 30**: `corpus-cross-reference.md` (skill-reference, unreviewed, tier 2) — 1 HIGH applied.
- Consumer verification (reference-file gate): only 1 actual consumer — `quantum-tunnel-claudes/SKILL.md` (conditionally, >5 candidates). Despite the file's own body text claiming "Used by learnings:curate," Grep confirmed no reference to `corpus-cross-reference` in `learnings:curate/SKILL.md` or `content-mode.md`. content-mode.md inlines its own corpus loading at step 2.
- HIGH applied: updated body description to remove stale `learnings:curate` consumer claim and note the inline duplicate in content-mode.md.
- LOW recorded [L-1]: Coverage Match Types table (Exact/Partial/Thematic/No match) has near-identical taxonomy in content-mode.md step 3 — same vocabulary, different framing. Reference-file gate doesn't cleanly apply since content-mode.md is not a declared consumer. Flagged for human review.
- Both patterns (Loading the Corpus, Cross-Referencing Content): STANDALONE REFERENCE — KEEP.
- Key insight: When a skill-reference file's self-description lists consumers, verify against Grep — self-descriptions can drift as consumer skills are refactored. Consumer claims are more reliable when backed by a dedicated "Reference Files" section in the consumer's SKILL.md.
- Next: candidate 12 = `platform-detection.md` (skill-reference, unreviewed, tier 2).

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
