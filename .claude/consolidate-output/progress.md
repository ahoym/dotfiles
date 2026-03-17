# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 29 |
| CONTENT_TYPE | DEEP_DIVE |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_CANDIDATES | ci-cd.md, gitlab-ci-cd.md |
| DEEP_DIVE_COMPLETED | claude-authoring-skills.md, multi-agent-patterns.md, ralph-loop.md, git-patterns.md, accessibility-patterns.md, aws-patterns.md, claude-authoring-claude-md.md, claude-authoring-learnings.md, claude-authoring-personas.md, claude-authoring-polling-review-skills.md, gitlab-cli.md, java-observability.md, order-book-pricing.md, python-specific.md, quarkus-kotlin.md, react-frontend-gotchas.md, reactive-data-patterns.md, typescript-specific.md, ui-patterns.md, vercel-deployment.md, xrpl-amm.md, xrpl-cross-currency-payments.md, xrpl-dex-data.md, xrpl-gotchas.md, xrpl-permissioned-domains.md, bignumber-financial-arithmetic.md |

## Pre-Flight

```
Recent commits: 9afdbae Consolidation: 2026-03-15, 8ef8b12 consolidate: remove round 2 confirmation pass, a70446e consolidate: prioritize unreviewed files over stale
Learnings files: 58
Skills count: 31
Guidelines files: 4
Persona files: 11
Cadence: recent (3 curation commits in last 5)
Suggested iterations: 10
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
| 1 | LEARNINGS | 0 | 0 | 0 | 0 | Clean — 58 files, 12 clusters, all well-organized |
| 2 | SKILLS | 0 | 0 | 0 | 0 | Clean — 31 skills, 5 clusters, 16 skill-references, no overlap/staleness |
| 3 | GUIDELINES | 0 | 0 | 0 | 0 | Clean — 4 files, all @-referenced, universally applicable. Transitioned to DEEP_DIVE (28 candidates) |
| 4 | DEEP_DIVE | 2 | 2 | 0 | 4 | claude-authoring-skills.md — removed 4 redundant takeaway lines, compressed body-only templates to cross-ref, merged description sections, compressed @ references section. ~30 lines saved. |
| 5 | DEEP_DIVE | 2 | 3 | 2 | 5 | multi-agent-patterns.md — removed 2 takeaway lines, compressed resume pattern details and code block, merged review architecture sections. 2 LOWs (migration candidates). ~20 lines saved. |
| 6 | DEEP_DIVE | 2 | 2 | 0 | 4 | ralph-loop.md — merged 3 section pairs (carryover+MAX_DEEP_DIVES, one-action+validation, sentinel+signal-coherence), compressed consolidation variant. ~20 lines saved. |
| 7 | DEEP_DIVE | 2 | 3 | 0 | 5 | git-patterns.md — removed 2 takeaways, merged stacked PR sections, folded symlink takeaway, merged stash pop sections. ~14 lines saved. |
| 8 | DEEP_DIVE | 0 | 2 | 0 | 2 | accessibility-patterns.md — added bidirectional cross-refs with react-patterns.md. Clean file, no compression needed. |
| 9 | DEEP_DIVE | 0 | 2 | 0 | 2 | aws-patterns.md — added bidirectional cross-refs with aws-messaging.md. 14-line file, already compact. |
| 10 | DEEP_DIVE | 3 | 0 | 0 | 3 | claude-authoring-claude-md.md — removed 2 takeaway lines, deleted section duplicated by path-resolution.md guideline. ~8 lines saved. |
| 11 | DEEP_DIVE | 0 | 2 | 0 | 2 | claude-authoring-learnings.md — merged discoverability stack into cross-ref convention, removed inline examples. ~11 lines saved. |
| 12 | DEEP_DIVE | 0 | 0 | 0 | 0 | claude-authoring-personas.md — clean. 108 lines, 14 sections, all standalone references. No redundancy with persona-design.md (complementary). |
| 13 | DEEP_DIVE | 0 | 0 | 0 | 0 | claude-authoring-polling-review-skills.md — clean. 59 lines, 12 sections. No overlap with corpus. All 4 See also valid. |
| 14 | DEEP_DIVE | 1 | 0 | 1 | 1 | gitlab-cli.md — deleted duplicate "Repointing MR Target Branches" section (canonical in git-patterns.md). 1 LOW: `--name-only` flag contradiction with fetch-review-data.md. |
| 15 | DEEP_DIVE | 0 | 0 | 0 | 0 | java-observability.md — clean. 14 lines, 1 section (Grafana/PromQL patterns). No overlap, already compact. |
| 16 | DEEP_DIVE | 0 | 2 | 0 | 2 | order-book-pricing.md — added bidirectional cross-refs with xrpl-patterns.md. 44 lines, 4 sections, compact and clean. |
| 17 | DEEP_DIVE | 1 | 3 | 0 | 4 | python-specific.md — removed 6 takeaway lines, merged 3 migration sections into "Package Manager Migration", added bidirectional cross-refs with api-design.md. 113→~95 lines. |
| 18 | DEEP_DIVE | 0 | 0 | 0 | 0 | quarkus-kotlin.md — clean. 8 lines, 1 pattern (Quarkus enum hot-reload). No overlap with spring-boot.md enum patterns (different frameworks). |
| 19 | DEEP_DIVE | 0 | 1 | 0 | 1 | react-frontend-gotchas.md — added See also (react-patterns.md, nextjs.md, playwright-patterns.md). 27→32 lines, 14 patterns, all condensed refs to source files. |
| 20 | DEEP_DIVE | 0 | 4 | 0 | 4 | reactive-data-patterns.md — compressed 3 Key Points blocks (folded unique details into prose), added See also (react-patterns.md, order-book-pricing.md). 42→32 lines. |
| 21 | DEEP_DIVE | 0 | 0 | 0 | 0 | typescript-specific.md — clean. 14 lines, 1 pattern (Record/union key extension). No overlap, all 3 See also valid. |
| 22 | DEEP_DIVE | 0 | 2 | 0 | 2 | ui-patterns.md — added See also (react-patterns.md, nextjs.md, accessibility-patterns.md), added reverse cross-ref from react-patterns.md. 61→67 lines. |
| 23 | DEEP_DIVE | 0 | 2 | 0 | 2 | vercel-deployment.md — added See also (typescript-ci-gotchas.md, xrpl-patterns.md). Added See also to typescript-ci-gotchas.md (vercel-deployment.md, ci-cd.md). 14→19 lines. |
| 24 | DEEP_DIVE | 0 | 2 | 0 | 2 | xrpl-amm.md — folded AMM Account subsection into parent bullet, added See also (xrpl-patterns.md, xrpl-gotchas.md, order-book-pricing.md, bignumber-financial-arithmetic.md). 122→~123 lines. |
| 25 | DEEP_DIVE | 0 | 2 | 0 | 2 | xrpl-cross-currency-payments.md — added See also (xrpl-patterns.md, xrpl-gotchas.md, bignumber-financial-arithmetic.md). Added reverse cross-ref from xrpl-patterns.md. 48→53 lines. |
| 26 | DEEP_DIVE | 0 | 1 | 0 | 1 | xrpl-dex-data.md — added See also (xrpl-patterns.md, xrpl-gotchas.md, xrpl-cross-currency-payments.md, order-book-pricing.md). 97→103 lines, 2 sections, clean. |
| 27 | DEEP_DIVE | 0 | 1 | 0 | 1 | xrpl-gotchas.md — added See also (xrpl-patterns.md, xrpl-amm.md, xrpl-dex-data.md, xrpl-cross-currency-payments.md, bignumber-financial-arithmetic.md). 44→51 lines, 6 sections, clean. |
| 28 | DEEP_DIVE | 0 | 2 | 0 | 2 | xrpl-permissioned-domains.md — added See also (xrpl-patterns.md, xrpl-gotchas.md, xrpl-dex-data.md). Added reverse cross-ref from xrpl-patterns.md. 78→83 lines, was cross-ref island. |
| 29 | DEEP_DIVE | 0 | 1 | 0 | 1 | bignumber-financial-arithmetic.md — added See also (order-book-pricing.md). 54→55 lines, compact and clean. |

## Deep Dive Status

<!-- Populated when PHASE transitions to DEEP_DIVE after broad sweeps complete -->

| File | Status | Iter | Summary |
|------|--------|------|---------|
| claude-authoring-skills.md | done | 4 | 2H+2M applied: removed 4 takeaway lines, compressed body-only templates, merged description sections, compressed @ refs. ~432 lines. |
| multi-agent-patterns.md | done | 5 | 2H+3M applied, 2 LOWs. Removed takeaways, compressed resume details+code block, merged review sections. ~286 lines. |
| ralph-loop.md | done | 6 | 2H+2M applied: merged 3 section pairs (carryover+MAX_DEEP_DIVES, one-action+validation, sentinel+signal-coherence), compressed consolidation variant. ~237 lines. |
| git-patterns.md | done | 7 | 2H+3M applied: removed 2 takeaways, merged stacked PR sections, folded symlink takeaway, merged stash pop sections. ~222 lines. |
| accessibility-patterns.md | done | 8 | 0H+2M applied: added bidirectional cross-refs with react-patterns.md. 70 lines, compact and clean. |
| aws-patterns.md | done | 9 | 0H+2M applied: added bidirectional cross-refs with aws-messaging.md. 18 lines, compact and clean. |
| claude-authoring-claude-md.md | done | 10 | 3H applied: removed 2 takeaway lines, deleted @ References section (duplicate of path-resolution.md guideline). ~142 lines. |
| claude-authoring-learnings.md | done | 11 | 0H+2M applied: compressed discoverability stack into cross-ref convention, removed inline examples. ~103 lines. |
| claude-authoring-personas.md | done | 12 | Clean. 108 lines, 14 sections, all standalone references. Cross-ref to hub valid. |
| claude-authoring-polling-review-skills.md | done | 13 | Clean. 59 lines, 12 patterns, all standalone. No overlap with cross-ref targets. |
| gitlab-cli.md | done | 14 | 1H applied: deleted duplicate repointing section (canonical in git-patterns.md). 1 LOW: --name-only flag contradiction with fetch-review-data.md. ~8 lines remaining. |
| java-observability.md | done | 15 | Clean. 14 lines, 1 section. No overlap with corpus. Compact PromQL/Micrometer reference. |
| order-book-pricing.md | done | 16 | 0H+2M applied: added bidirectional cross-refs with xrpl-patterns.md + bignumber-financial-arithmetic.md. 49 lines, clean and compact. |
| python-specific.md | done | 17 | 1H+3M applied: removed 6 takeaway lines, merged 3 migration sections, added bidirectional cross-refs with api-design.md. ~95 lines. |
| quarkus-kotlin.md | done | 18 | Clean. 8 lines, 1 pattern. No overlap, no cross-ref gaps, maximally compact. |
| react-frontend-gotchas.md | done | 19 | 0H+1M applied: added See also → react-patterns.md, nextjs.md, playwright-patterns.md. 32 lines, 14 condensed patterns. |
| reactive-data-patterns.md | done | 20 | 0H+4M applied: compressed 3 Key Points blocks (folded unique details into prose, removed redundant bullets), added See also → react-patterns.md, order-book-pricing.md. 42→32 lines. |
| typescript-specific.md | done | 21 | Clean. 14 lines, 1 pattern. No overlap, no compression, all See also valid. |
| ui-patterns.md | done | 22 | 0H+2M applied: added See also → react-patterns.md, nextjs.md, accessibility-patterns.md. Added reverse cross-ref from react-patterns.md. 67 lines, 3 patterns, compact and clean. |
| vercel-deployment.md | done | 23 | 0H+2M applied: added See also → typescript-ci-gotchas.md, xrpl-patterns.md. Added See also to typescript-ci-gotchas.md → vercel-deployment.md, ci-cd.md. 19 lines, compact and clean. |
| xrpl-amm.md | done | 24 | 0H+2M applied: folded AMM Account subsection into parent bullet, added See also → xrpl-patterns.md, xrpl-gotchas.md, order-book-pricing.md, bignumber-financial-arithmetic.md. ~123 lines. |
| xrpl-cross-currency-payments.md | done | 25 | 0H+2M applied: added See also → xrpl-patterns.md, xrpl-gotchas.md, bignumber-financial-arithmetic.md. Added reverse cross-ref from xrpl-patterns.md. 53 lines, 8 compact sections. |
| xrpl-dex-data.md | done | 26 | 0H+1M applied: added See also → xrpl-patterns.md, xrpl-gotchas.md, xrpl-cross-currency-payments.md, order-book-pricing.md. 103 lines, 2 sections (OnTheDEX API + protocol reference), clean and compact. |
| xrpl-gotchas.md | done | 27 | 0H+1M applied: added See also → xrpl-patterns.md, xrpl-amm.md, xrpl-dex-data.md, xrpl-cross-currency-payments.md, bignumber-financial-arithmetic.md. 51 lines, 6 sections (~20 patterns), clean and compact. |
| xrpl-permissioned-domains.md | done | 28 | 0H+2M applied: added See also → xrpl-patterns.md, xrpl-gotchas.md, xrpl-dex-data.md. Added reverse cross-ref from xrpl-patterns.md. 83 lines, was cross-ref island in XRPL cluster. |
| bignumber-financial-arithmetic.md | done | 29 | 0H+1M applied: added See also → order-book-pricing.md (primary JS application context). 55 lines, compact and clean. |
| ci-cd.md | pending | — | Stale (run 0, never deep-dived) |
| gitlab-ci-cd.md | pending | — | Stale (run 0, never deep-dived) |

## Notes for Next Iteration

<!-- Appended each iteration with ### Iter N heading — do not overwrite -->

### Iter 1

**Methodology loaded** (run_count incremented to 13): Classification model (6-bucket), persona design (4-section, 3+ files/8+ patterns threshold), curation insights (defect + opportunity modes, compression targets, source-vs-echo test), content type routing (hub-spoke authoring cluster).

**LEARNINGS cluster map** (12 clusters, 58 files):
- XRPL+TS (8): xrpl-patterns, xrpl-gotchas, xrpl-amm, xrpl-dex-data, xrpl-cross-currency-payments, xrpl-permissioned-domains, order-book-pricing, bignumber-financial-arithmetic
- React/Next.js (8): react-patterns, react-frontend-gotchas, nextjs, accessibility-patterns, ui-patterns, reactive-data-patterns, typescript-specific, web-session-sync
- Java/Spring (8): spring-boot, spring-boot-gotchas, java-observability, java-observability-gotchas, java-infosec-gotchas, quarkus-kotlin, financial-applications, resilience-patterns
- CI/CD (5): ci-cd, ci-cd-gotchas, gitlab-ci-cd, typescript-ci-gotchas, vercel-deployment
- Claude Config (10): claude-authoring-content-types (hub), claude-authoring-skills, claude-authoring-guidelines, claude-authoring-learnings, claude-authoring-personas, claude-authoring-claude-md, claude-authoring-polling-review-skills, skill-platform-portability, claude-code-hooks, claude-code
- Testing (2): testing-patterns, playwright-patterns
- Git/Process (4): git-patterns, gitlab-cli, process-conventions, code-quality-instincts
- Multi-Agent (3): multi-agent-patterns, parallel-plans, ralph-loop
- Shell/AWS (4): bash-patterns, aws-patterns, aws-messaging, local-dev-seeding
- Other: postgresql-query-patterns, cross-repo-sync, explore-repo, python-specific, api-design, refactoring-patterns, newman-postman

**Cross-ref graph**: 36 connected / 22 isolated (62%/38%). Isolated files are mostly gotchas companions (proactive-loaded via personas) or niche standalone files — no wiring gaps detected.

**Concept-name collision**: None found.

**Polish Opportunities** (deep-dive candidates from quality scan):
- claude-authoring-skills.md (462 lines) — compression candidate
- multi-agent-patterns.md (306 lines) — compression candidate
- ralph-loop.md (257 lines) — compression candidate
- git-patterns.md (236 lines) — compression candidate

**Deep-dive unreviewed files** (23 files not in tracker): accessibility-patterns, aws-patterns, claude-authoring-claude-md, claude-authoring-learnings, claude-authoring-personas, claude-authoring-polling-review-skills, cross-repo-sync, gitlab-cli, java-observability, order-book-pricing, python-specific, quarkus-kotlin, react-frontend-gotchas, reactive-data-patterns, typescript-specific, ui-patterns, vercel-deployment, web-session-sync, xrpl-amm, xrpl-cross-currency-payments, xrpl-dex-data, xrpl-gotchas, xrpl-permissioned-domains

### Iter 2

**SKILLS cluster map** (5 clusters, 31 skills, 16 skill-references):
- git:* (10): address-request-comments, cascade-rebase, code-review-request, create-request, explore-request, prune-merged, repoint-branch, resolve-conflicts, split-commit, split-request
- learnings:* (4): compound, consolidate, curate, distribute
- ralph:* (7): consolidate:init/resume, research:brief/cleanup/compare/init/resume
- parallel-plan:* (2): make, execute
- standalone (8): do-refactor-code, do-security-audit, explore-repo, explore-repo:brief, extract-request-learnings, quantum-tunnel-claudes, session-retro, set-persona

**Shared references** (16 files, 2 platform clusters): Well-deduplicated. platform-detection (all git skills), request-interaction-base (address+review), agent-prompting/code-quality-checklist/subagent-patterns (orchestration skills), GitHub/GitLab cluster files (4 each, partitioned by function).

**Cross-skill checks**: No overlap within or across namespaces. Producer/consumer contracts validated (consolidate→curate, make→execute, repoint-branch↔split-request). All Co-Authored-By references current (Opus 4.6).

**No deep-dive candidates from skills sweep** — all skills well-scoped and current.

### Iter 3

**GUIDELINES sweep**: 4 files, all @-referenced from .claude/CLAUDE.md. All universally applicable behavioral guidelines — no domain specificity, no duplication with learnings, no staleness. communication.md (~200+ lines) and context-aware-learnings.md (~150+ lines) have justified always-on cost. path-resolution.md (~40 lines) and skill-invocation.md (~25 lines) are compact. CLAUDE.md inline Path Resolution table is intentional quick-ref, not duplication.

**Broad sweeps complete** (L→S→G all clean). Transitioned to DEEP_DIVE phase.

**Deep dive candidates** (28 total, prioritized):
- Priority 1 — Polish Opportunities (4): claude-authoring-skills.md (462 lines), multi-agent-patterns.md (306 lines), ralph-loop.md (257 lines), git-patterns.md (236 lines)
- Priority 2 — Unreviewed (21): accessibility-patterns, aws-patterns, claude-authoring-claude-md, claude-authoring-learnings, claude-authoring-personas, claude-authoring-polling-review-skills, gitlab-cli, java-observability, order-book-pricing, python-specific, quarkus-kotlin, react-frontend-gotchas, reactive-data-patterns, typescript-specific, ui-patterns, vercel-deployment, xrpl-amm, xrpl-cross-currency-payments, xrpl-dex-data, xrpl-gotchas, xrpl-permissioned-domains
- Priority 3 — Stale tracked (3): bignumber-financial-arithmetic (run 0), ci-cd (run 0), gitlab-ci-cd (run 0)

**Note**: cross-repo-sync and web-session-sync from iter 1 unreviewed list are actually in the tracker (run 9 and 8 respectively) — corrected to 21 unreviewed.

### Iter 4

**Deep dive: claude-authoring-skills.md** (462→~432 lines, ~60 patterns)

**Applied actions (4):**
- HIGH: Removed 4 redundant `- **Takeaway**:` lines that restated section headings (lines 275, 305, 311, 317)
- HIGH: Compressed "Body-Only Templates" from 3-line duplicate to 1-line cross-ref to `claude-authoring-content-types.md`
- MEDIUM (auto-applied): Merged "Skill Description Frontmatter Optimization" + "Discoverability via Trigger Phrases" into single "Skill Description Optimization & Discoverability" section — both about the `description:` field, no information loss
- MEDIUM (auto-applied): Compressed "`@` References in Skills" — folded "Attention pattern" into "Path resolution" point, removed "Format flexibility" (trivial parsing detail)

**Cross-ref health**: All 5 See Also entries valid and current. No new cross-refs needed — file is the skill design spoke of the authoring hub, well-connected.

**Next candidate**: multi-agent-patterns.md (306 lines, compression)

### Iter 5

**Deep dive: multi-agent-patterns.md** (306→~286 lines, ~30 patterns)

**Applied actions (5):**
- HIGH: Removed 2 redundant takeaway lines ("Partial Batch Completion", "Staging Directory Pattern")
- MEDIUM (auto-applied): Compressed "Subagents Cannot Write .md" resume pattern details — 3 sentences → 2, preserved cost comparison and timing data
- MEDIUM (auto-applied): Compressed "Worktree Agent Merge" code block — removed redundant comments (text above explains both paths), 12 lines → 5
- MEDIUM (auto-applied): Merged "Mutual Agreement Auto-Implementation" + "Agent-to-Agent Review Cycle" → "Agent-to-Agent Review Architecture" — both about same review architecture, 8 lines → 5

**LOWs (2):** "Iterative Testing for Timing-Dependent Autonomous Features" (possible migration to testing-patterns.md) and "Three-Branch Gate Announcements" (possible migration to claude-authoring-learnings.md). Both borderline — learned in multi-agent context but core principles are broader.

**Cross-ref health**: All 3 See Also entries valid and current. parallel-plans.md has bidirectional ref. No new cross-refs needed.

**Overlap check**: Compared against subagent-patterns.md (skill-reference) and parallel-plans.md. All overlapping topics are complementary (different angles/detail levels), no duplication requiring action.

**Next candidate**: ralph-loop.md (257 lines, compression)

### Iter 6

**Deep dive: ralph-loop.md** (257→~237 lines, 48 patterns)

**Applied actions (4):**
- HIGH: Merged "Deep Dive Carryover ≠ Unfinished Work" + "MAX_DEEP_DIVES_HIT Is a Completion Signal" — identical concepts from different angles
- HIGH: Merged "One-Action-Per-Invocation Violations" + "Post-Invocation State Validation" — problem-solution pair, 11→5 lines
- MEDIUM (auto-applied): Merged "Sentinel Value False Positives" + "Spec-Runner Signal Coherence" → "Runner-Spec Signal Contract" — two failure modes of the same contract, 10→6 lines
- MEDIUM (auto-applied): Compressed "Consolidation Loop Variant" — removed 3 spec-redundant bullets (output dir, output files, runner/resume), 12→8 lines

**Cross-ref health**: All 3 See Also entries valid and current (curation-insights.md, claude-code.md, multi-agent-patterns.md). No new cross-refs needed.

**No LOWs** — remaining 44 patterns are compact standalone references with no overlap against claude-code.md, process-conventions.md, curation-insights.md, or multi-agent-patterns.md.

**Next candidate**: git-patterns.md (236 lines, compression)

### Iter 7

**Deep dive: git-patterns.md** (236→~222 lines, ~25 sections)

**Applied actions (5):**
- HIGH: Removed takeaway line from "Dependent PR Chains" (restated section title)
- HIGH: Removed takeaway line from "git mv" (restated section content)
- MEDIUM (auto-applied): Merged "Dependent PR Chains Risk Abandonment" + "Stacked Branch Dependency Model Risks" → "Stacked PR Dependency Risks" — same concern from different angles, 12→3 lines
- MEDIUM (auto-applied): Folded "Symlinked Dirs" takeaway into body as **Fix:** — actionable guidance in standalone takeaway format inconsistent with rest of file
- MEDIUM (auto-applied): Merged "Stash Pop Across Diverged Branches" + "Stash Pop After Rebase" → "Stash Pop Conflict Scenarios" — same pattern, different triggers. 11→6 lines

**Cross-ref health**: Both See Also entries valid (bash-patterns.md, ci-cd-gotchas.md). No new cross-refs needed. Checked process-conventions.md for overlap — complementary, no duplication.

**No LOWs** — remaining ~20 patterns are compact standalone references. Pre-commit hook sections (git add staging, hooks alter commits, amend picks up extras) are related but cover distinct failure modes and are already compact — merging would lose clarity.

**Next candidate**: accessibility-patterns.md (unreviewed)

### Iter 8

**Deep dive: accessibility-patterns.md** (70 lines, 6 patterns + checklist table)

**Applied actions (2):**
- MEDIUM (auto-applied): Added `## See also` to accessibility-patterns.md pointing to react-patterns.md (component patterns complement accessibility awareness)
- MEDIUM (auto-applied): Added reverse cross-ref from react-patterns.md → accessibility-patterns.md (aria attributes and keyboard support)

**Quality**: Already lean at 70 lines. No compression, genericization, or redundancy issues. Each pattern is a compact code snippet + 1-line explanation. Checklist table serves as scannable audit tool (different purpose from code snippets above).

**Cross-ref rationale**: react-frontend persona wires these files together when active, but cross-refs serve navigation when no persona is active. "accessibility" not discoverable from "react" keyword search.

**Tracker**: accessibility-patterns.md added (run 13), react-patterns.md reset to 0 (modified).

**Next candidate**: aws-patterns.md (unreviewed)

### Iter 9

**Deep dive: aws-patterns.md** (14 lines, 2 patterns — EventBridge scheduling floor, ECS Fargate cost defaults)

**Applied actions (2):**
- MEDIUM (auto-applied): Added `## See also` to aws-patterns.md → aws-messaging.md (same AWS cluster, EventBridge topic overlap)
- MEDIUM (auto-applied): Added reverse cross-ref from aws-messaging.md → aws-patterns.md

**Quality**: Already very lean at 14 lines. No compression, genericization, or redundancy. Both patterns are concrete with specific costs/thresholds.

**Cross-ref rationale**: platform-engineer persona wires these files when active, but cross-refs serve navigation without persona. EventBridge appears in both files with different focus (scheduling vs routing).

**Tracker**: aws-patterns.md added (run 13), aws-messaging.md reset to 0 (modified).

**Next candidate**: claude-authoring-claude-md.md (unreviewed)

### Iter 10

**Deep dive: claude-authoring-claude-md.md** (150→~142 lines, 10 sections)

**Applied actions (3):**
- HIGH: Removed takeaway line from "Refactor Monolithic CLAUDE.md" (restated heading)
- HIGH: Removed takeaway line from "Document Conflict Resolution" (restated heading)
- HIGH: Deleted "@ References Resolve Relative to the File, Not the Project Root" section — fully duplicated by always-on `path-resolution.md` guideline (loaded via `@` ref in CLAUDE.md). Guideline version is more comprehensive (covers tilde paths, multiple CLAUDE.md locations).

**Quality**: Remaining 8 sections are well-structured standalone references. No compression candidates — sections are already compact (6-34 lines each). No genericization issues — content is about CLAUDE.md authoring patterns generically.

**Cross-ref health**: See also → `claude-authoring-content-types.md` — valid hub reference. No new cross-refs needed (all authoring cluster files share `claude-authoring-` prefix, discoverable by keyword search).

**Tracker**: claude-authoring-claude-md.md added (run 13).

**Next candidate**: claude-authoring-learnings.md (unreviewed)

### Iter 11

**Deep dive: claude-authoring-learnings.md** (114→~103 lines, 11 sections)

**Applied actions (2):**
- MEDIUM (auto-applied): Compressed "Cross-Ref Discoverability Stack" (10 lines) into 2-line "Prioritize islands" rule, folded into "Cross-Reference Convention" section. The 4-level model (persona→inbound→see-also→keyword) was educational but verbose — the actionable conclusion captures the value.
- MEDIUM (auto-applied): Removed "Example — curation-specific cross-refs" (3 lines) — inline prose-style refs to curation-insights.md that used a different format than the `## See also` convention being taught. Replaced with the folded "Prioritize islands" rule.

**Quality**: Well-structured file with clear section boundaries. Genericization section (25 lines) is the longest but justified — covers table, exceptions, and project-specific instances. Cross-ref convention (now ~30 lines with folded islands rule) is the reference specification for the cross-ref system. No further compression candidates.

**Cross-ref health**: Single See also → `claude-authoring-content-types.md` (hub). Valid. No new cross-refs needed — all authoring cluster files share prefix.

**Tracker**: claude-authoring-learnings.md added (run 13).

**Next candidate**: claude-authoring-personas.md (unreviewed)

### Iter 12

**Deep dive: claude-authoring-personas.md** (108 lines, 14 sections)

**No actions** — clean file. All 14 sections are standalone references with no redundancy, no compression candidates, and no cross-ref gaps.

**Cross-ref check**: persona-design.md (curation methodology) covers creation process formally; this learning captures discovery-oriented patterns (evaluation tests, composition strategies, curation checks). Complementary, not duplicative.

**Evaluated merge candidates**: Sections 11-13 (persona curation checks — gotchas duplication, cross-persona duplication, inherited load noise) are distinct failure modes; merging would lose clarity for ~4 lines saved.

**Tracker**: claude-authoring-personas.md added (run 13).

**Next candidate**: gitlab-cli.md (unreviewed)

### Iter 13

**Deep dive: claude-authoring-polling-review-skills.md** (59 lines, 12 sections)

**No actions** — clean file. All 12 sections are compact standalone references (~4.9 lines/pattern). No overlap with process-conventions.md (footnote template vs detection usage), claude-authoring-skills.md (generic skill design vs polling-specific), or multi-agent-patterns.md (review architecture vs polling mechanics). All 4 See also entries valid and bidirectional. No compression candidates — already maximally compact.

**Tracker**: claude-authoring-polling-review-skills.md added (run 13).

**Next candidate**: gitlab-cli.md (unreviewed)

### Resume (human review)

**All 3 LOWs resolved**:
- L-1, L-2: Keep in multi-agent-patterns.md (agent context is primary consumer)
- L-3: `glab mr diff --name-only` confirmed non-existent. gitlab-cli.md was correct. Fixed `.claude/skill-references/gitlab/fetch-review-data.md` to use `--raw | grep` workaround.

**Next candidate**: java-observability.md (unreviewed)

### Iter 15

**Deep dive: java-observability.md** (14 lines, 1 section)

**No actions** — clean file. Single "Grafana Dashboard Patterns for Micrometer Counters" section with PromQL templates and dashboard structure guidance. Already maximally compact. No overlap anywhere in corpus. Companion gotchas file references this file explicitly.

**Next candidate**: order-book-pricing.md (unreviewed)

### Iter 16

**Deep dive: order-book-pricing.md** (44→49 lines, 4 sections)

**Applied actions (2):**
- MEDIUM (auto-applied): Added `## See also` to order-book-pricing.md → xrpl-patterns.md (upstream data: getOrderbook, funded offers, depth summary) + bignumber-financial-arithmetic.md (arithmetic primitives for slippage/midprice)
- MEDIUM (auto-applied): Added reverse cross-ref from xrpl-patterns.md → order-book-pricing.md (pricing computation layer was missing from existing See also)

**Quality**: Compact file at 44 lines. All 4 sections are standalone references — mid-price approaches (industry standard definitions), slippage estimation (algorithm + code), module design (architecture), OrderBookEntry.quality (xrpl.js type detail). No compression, redundancy, or genericization issues.

**Cross-ref rationale**: xrpl-patterns already referenced bignumber and xrpl-dex-data but not order-book-pricing — the pricing computation layer between raw data and display was a gap. Vocabulary search for "order book" wouldn't find "funded offer fields" or "BigNumber.min".

**Tracker**: order-book-pricing.md added (run 13), xrpl-patterns.md reset to 0 (modified).

**Next candidate**: python-specific.md (unreviewed)

### Iter 17

**Deep dive: python-specific.md** (113→~95 lines, 9→7 sections)

**Applied actions (4):**
- HIGH: Removed 6 redundant takeaway lines (sections 4-9) — same pattern as iters 4,5,7,10
- MEDIUM (auto-applied): Merged "pyproject.toml as stable anchor" + "Dockerfile updates" + "Migration scripts" → "Package Manager Migration" — three 2-line sections about one event, merged to 3-bullet section. ~8 lines saved, no info loss.
- MEDIUM (auto-applied): Added `## See also` → api-design.md (Pydantic serialization implements "consistent shapes"), testing-patterns.md (Python singleton isolation)
- MEDIUM (auto-applied): Added reverse cross-ref from api-design.md → python-specific.md

**Quality**: 7 sections after merge. Pydantic v2 (30 lines) and TypedDict (14 lines) are the densest — justified by code examples. Remaining sections compact (2-6 lines each). "Fix Root Causes" considered for migration to code-quality-instincts.md but the B006/sentinel example is Python-specific — keeps it here.

**Cross-ref health**: api-design.md inline ref formalized as See also. testing-patterns.md has Python module-level singleton section — related but different focus (test isolation vs language patterns). No overlap with explore-repo.md Python/FastAPI content (project-scanning patterns vs language patterns).

**Tracker**: python-specific.md added (run 13), api-design.md reset to 0 (modified).

**Next candidate**: quarkus-kotlin.md (unreviewed)

### Iter 18

**Deep dive: quarkus-kotlin.md** (8 lines, 1 pattern)

**No actions** — clean file. Single "Enum changes require clean build in dev mode" pattern. Already maximally compact. No overlap with spring-boot.md enum patterns (JPA/PostgreSQL enum column mapping vs Quarkus dev mode incremental compilation). No cross-ref gaps — java-backend persona wires Java/Spring cluster files together when active.

**Tracker**: quarkus-kotlin.md added (run 13).

**Next candidate**: react-frontend-gotchas.md (unreviewed)

### Iter 19

**Deep dive: react-frontend-gotchas.md** (27→32 lines, 14 patterns across 3 sections)

**Applied actions (1):**
- MEDIUM (auto-applied): Added `## See also` → react-patterns.md, nextjs.md, playwright-patterns.md. All 14 patterns are condensed 1-line versions of full explanations in these 3 files. Reverse cross-refs already existed in all 3 source files. Forward cross-refs complete the bidirectional navigation.

**Quality**: Maximally compact at 27 lines (now 32 with See also). Each pattern is a single condensed line. No compression, genericization, or redundancy — the file's value IS being a condensed cross-domain quick-ref that loads fewer tokens than all 3 source files combined (~500+ lines).

**Overlap assessment**: Every pattern overlaps with a source file by design. This is a gotchas companion file, not an independent reference. The condensed format serves a different purpose (quick scan vs detailed explanation).

**Tracker**: react-frontend-gotchas.md added (run 13).

**Next candidate**: reactive-data-patterns.md (unreviewed)

### Iter 20

**Deep dive: reactive-data-patterns.md** (42→32 lines, 4 sections)

**Applied actions (4):**
- MEDIUM (auto-applied): Compressed §1 "Reactive Refresh Over Polling" Key Points — all 4 bullets restated prose. Removed block.
- MEDIUM (auto-applied): Compressed §2 "Client-Side Expiration Tracking" Key Points — 3 of 4 bullets restated prose. Folded unique "convert platform-specific epoch" detail into prose paragraph. Removed block.
- MEDIUM (auto-applied): Compressed §3 "Silent Fetch Pattern" Key Points — 2 of 4 bullets restated prose. Folded unique details (default false for backward compat, silent:true/false usage guidance) into prose paragraph. Removed block.
- MEDIUM (auto-applied): Added `## See also` → react-patterns.md (hooks, polling, localStorage — already refs this file), order-book-pricing.md (§4 Balance Validation connects to exchange pricing layer).

**Quality**: 4 sections, all now prose-only (except §4 which had no Key Points). §4 "Balance Validation" is about exchange UX not reactive data per se, but only 5 lines and no better home — order-book-pricing covers math, ui-patterns is general UI. Leave it.

**Cross-ref health**: react-patterns.md:228 already has forward ref. New See also completes bidirectional. order-book-pricing.md already has See also pointing to xrpl-patterns — no reverse needed (different relationship: this file is a consumer of pricing concepts, not a source).

**Tracker**: reactive-data-patterns.md added (run 13).

**Next candidate**: typescript-specific.md (unreviewed)

### Iter 21

**Deep dive: typescript-specific.md** (14 lines, 1 pattern)

**No actions** — clean file. Single "Extending a Union Type Used in Record Keys" pattern with actionable search guidance. Already maximally compact. No overlap anywhere in corpus (Grep confirmed). All 3 See also entries valid: nextjs.md (original context), react-frontend-gotchas.md (condensed tripwires), code-quality-instincts.md (single source of truth principle).

**Tracker**: typescript-specific.md added (run 13).

**Next candidate**: ui-patterns.md (unreviewed)

### Iter 22

**Deep dive: ui-patterns.md** (61→67 lines, 3 sections)

**Applied actions (2):**
- MEDIUM (auto-applied): Added `## See also` → react-patterns.md (component patterns/Tailwind context), nextjs.md (SVG title relates to JSX compilation), accessibility-patterns.md (interaction patterns complement UI styling)
- MEDIUM (auto-applied): Added reverse cross-ref from react-patterns.md → ui-patterns.md (Tailwind tooltips, design token centralization)

**Quality**: Compact file at 61 lines. All 3 sections are standalone patterns with code examples — CSS tooltip (Tailwind group-hover), SVG title gotcha, design token centralization. No compression candidates — code examples are the value. No redundancy with any other corpus file (Grep confirmed). No genericization issues — all patterns are UI-specific.

**Tracker**: ui-patterns.md added (run 13), react-patterns.md reset to 0 (modified).

**Next candidate**: vercel-deployment.md (unreviewed)

### Iter 23

**Deep dive: vercel-deployment.md** (14→19 lines, 2 sections, 5 patterns)

**Applied actions (2):**
- MEDIUM (auto-applied): Added `## See also` to vercel-deployment.md → typescript-ci-gotchas.md (Vercel serverless cold starts, lockfile gotchas), xrpl-patterns.md (Vercel WebSocket connection management for XRPL apps)
- MEDIUM (auto-applied): Added `## See also` to typescript-ci-gotchas.md → vercel-deployment.md (cron limits, Postgres driver patterns), ci-cd.md (general CI/CD patterns)

**Quality**: Already maximally compact at 14 lines. Each bullet is dense with specific values (tier pricing, env var names, SQL operator). No compression, genericization, or redundancy issues. `IS NOT DISTINCT FROM` not in postgresql-query-patterns.md (different focus — query optimization vs serverless DB gotchas).

**Cross-ref rationale**: typescript-ci-gotchas has a 2-pattern Vercel/Serverless section — complementary (cold starts + lockfiles vs crons + postgres). xrpl-patterns has Vercel WebSocket section — relevant when deploying XRPL apps. Both discoverable by "vercel" keyword search but See also provides structured navigation consistent with prior decisions (iters 8, 9, 16).

**Tracker**: vercel-deployment.md added (run 13), typescript-ci-gotchas.md added (run 0 — modified, not yet deep-dived).

**Next candidate**: xrpl-amm.md (unreviewed)

### Iter 24

**Deep dive: xrpl-amm.md** (122→~123 lines, 8 sections + subsections)

**Applied actions (2):**
- MEDIUM (auto-applied): Folded "AMM Account" subsection into parent bullet — subsection restated bullet with minor additions (pseudo-random address, regular key zeroed, master key disabled). Merged unique details into bullet, deleted subsection header. ~4 lines saved.
- MEDIUM (auto-applied): Added `## See also` → xrpl-patterns.md (orderbook fetching, funded offers, WebSocket management), xrpl-gotchas.md (AMM-specific gotchas section), order-book-pricing.md (pricing for interleaved CLOB+AMM fills), bignumber-financial-arithmetic.md (BigNumber.js for AMM formula computations).

**Quality**: Well-structured file at 122 lines. Constant-product formulas (§1) and AMM Overview (§4) have minor overlap (both mention `x * y = k` and fee rate) but serve different audiences — §1 is computational reference, §4 is conceptual context. Merging would damage standalone readability. Error code table, LP token encoding, transaction types, impermanent loss mitigation, and metadata parsing are all unique standalone sections. No genericization issues — all content is XRPL AMM-specific.

**Cross-ref health**: xrpl-patterns.md already back-refs this file (See also line 211). New See also completes bidirectional navigation. All 4 targets confirmed relevant and existing.

**Tracker**: xrpl-amm.md added (run 13).

**Next candidate**: xrpl-cross-currency-payments.md (unreviewed)

### Iter 25

**Deep dive: xrpl-cross-currency-payments.md** (48→53 lines, 8 sections)

**Applied actions (2):**
- MEDIUM (auto-applied): Added `## See also` → xrpl-patterns.md (simulate API, funded offers, WebSocket management), xrpl-gotchas.md (companion tripwires), bignumber-financial-arithmetic.md (payment amount calculations, slippage margins)
- MEDIUM (auto-applied): Added reverse cross-ref from xrpl-patterns.md → xrpl-cross-currency-payments.md (payment engine, pathfinding, TransferRate, SendMax, NoRipple rules)

**Quality**: Compact file at 48 lines. All 8 sections are discrete standalone references covering specific XRPL payment mechanics — delivered_amount, two-pass algorithm, pathfinding, TransferRate formula, tfLimitQuality, SendMax ceiling, NoRipple enter-and-exit rule, DefaultRipple timing, noripple_check API. No compression, redundancy, or genericization issues.

**Overlap check**: `delivered_amount` in xrpl-patterns.md:184 (simulate context) and `DefaultRipple` in xrpl-amm.md:64,99 (AMM prerequisites) — different contexts, complementary not duplicative. Zero hits in xrpl-gotchas.md.

**Tracker**: xrpl-cross-currency-payments.md added (run 13), xrpl-patterns.md reset to 0 (modified).

**Next candidate**: xrpl-dex-data.md (unreviewed)

### Iter 26

**Deep dive: xrpl-dex-data.md** (97→103 lines, 2 sections)

**Applied actions (1):**
- MEDIUM (auto-applied): Added `## See also` → xrpl-patterns.md (funded offer fields, OfferCreate fill detection, orderbook fetching, WebSocket management), xrpl-gotchas.md (TakerGets/TakerPays naming, funded field absence semantics), xrpl-cross-currency-payments.md (payment engine two-pass algorithm, pathfinding, SendMax, NoRipple rules), order-book-pricing.md (mid-price approaches, slippage estimation consuming DEX data)

**Quality**: Two clean sections — OnTheDEX API reference (47 lines, endpoint table + JSON shapes) and XRPL Native DEX protocol reference (33 lines). OfferCreate flags table, Auto-Bridging, Tick Size, funding rules, and trust line auto-creation are all unique to this file. Cross-Currency Payments subsection (2 lines) provides DEX context without duplicating the dedicated file. No compression, genericization, or redundancy issues.

**Cross-ref health**: xrpl-patterns.md:208 already refs this file. No reverse cross-ref needed. xrpl-gotchas.md will get its See also when deep-dived next.

**Tracker**: xrpl-dex-data.md added (run 13).

**Next candidate**: xrpl-gotchas.md (unreviewed)

### Iter 27

**Deep dive: xrpl-gotchas.md** (44→51 lines, 6 sections, ~20 patterns)

**Applied actions (1):**
- MEDIUM (auto-applied): Added `## See also` → xrpl-patterns.md (companion — full integration patterns), xrpl-amm.md (AMM constant-product formulas, transaction types, error codes), xrpl-dex-data.md (OnTheDEX API, native DEX protocol reference), xrpl-cross-currency-payments.md (payment engine, pathfinding, TransferRate, SendMax), bignumber-financial-arithmetic.md (BigNumber.js patterns for XRPL financial calculations)

**Quality**: Maximally compact at 44 lines. Each pattern is a single condensed line — consistent with gotchas companion format (same structure as react-frontend-gotchas.md). Every gotcha has a corresponding longer explanation in a sister file by design. No compression, genericization, or redundancy issues.

**Overlap assessment**: Every pattern overlaps with a source file intentionally. AMM section (3 patterns) overlaps with xrpl-amm.md (AMMCreate fee, amm_info order, amm_info errors). RippleState sign convention overlaps with xrpl-patterns.md §51-64. Funded field semantics overlap with xrpl-patterns.md §36-49. All complementary — gotcha is quick tripwire, source file has full explanation.

**Cross-ref health**: 4 files already referenced xrpl-gotchas.md (xrpl-patterns:207, xrpl-dex-data:101, xrpl-amm:122, xrpl-cross-currency-payments:52). New See also completes bidirectional navigation for the entire XRPL cluster.

**Tracker**: xrpl-gotchas.md added (run 13).

**Next candidate**: xrpl-permissioned-domains.md (unreviewed)

### Iter 28

**Deep dive: xrpl-permissioned-domains.md** (78→83 lines, 6 sections)

**Applied actions (2):**
- MEDIUM (auto-applied): Added `## See also` → xrpl-patterns.md (DomainID typing gaps, book_offers domain param), xrpl-gotchas.md (DomainID availability), xrpl-dex-data.md (native DEX protocol reference)
- MEDIUM (auto-applied): Added reverse cross-ref from xrpl-patterns.md → xrpl-permissioned-domains.md (credentials XLS-70, permissioned domains XLS-80, permissioned DEX XLS-81)

**Quality**: Well-structured file covering 3 XLS standards. Each section is compact and standalone — Status (3 lines), Three Roles (6 lines), Layer Controls (3 lines), Credentials lifecycle+fields (18 lines), Domain mechanics (12 lines), DEX matching+xrpl.js (19 lines). No compression, genericization, or redundancy issues.

**Cross-ref rationale**: File was a complete cross-ref island — no other file referenced it despite DomainID appearing in xrpl-patterns.md (lines 10, 107-110) and xrpl-gotchas.md (line 15). xrpl-patterns.md See also had 6 entries covering all other XRPL files but omitted this one. Now fully connected to XRPL cluster.

**Tracker**: xrpl-permissioned-domains.md added (run 13), xrpl-patterns.md reset to 0 (modified).

**Next candidate**: bignumber-financial-arithmetic.md (stale, run 0)

### Iter 29

**Deep dive: bignumber-financial-arithmetic.md** (54→55 lines, 5 sections + See also)

**Applied actions (1):**
- MEDIUM (auto-applied): Added `order-book-pricing.md` to See also — primary JS application context for BigNumber.js patterns (mid-price computation, slippage estimation, reduce accumulation). Reverse cross-ref already existed from iter 16. Completes bidirectional navigation.

**Quality**: Maximally compact at 54 lines. Code examples are 1-3 lines each — minimum to illustrate. No takeaway lines, no redundancy, no compression candidates. Content is BigNumber.js-generic, not domain-specific.

**Cross-ref analysis**: 5 XRPL files point to this file (xrpl-patterns, xrpl-amm, xrpl-cross-currency-payments, xrpl-gotchas, order-book-pricing). Only order-book-pricing warranted a reverse cross-ref — the others use BigNumber incidentally, adding them would clutter a generic file. financial-applications.md bidirectional ref already existed.

**Tracker**: bignumber-financial-arithmetic.md updated (run 13).

**Next candidate**: ci-cd.md (stale, run 0)
