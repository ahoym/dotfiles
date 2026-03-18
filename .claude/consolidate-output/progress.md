# Consolidation Progress

## State

| Variable | Value |
|----------|-------|
| SWEEP_COUNT | 18 |
| CONTENT_TYPE | (all swept) |
| PHASE | DEEP_DIVE |
| DEEP_DIVE_CANDIDATES | agent-prompting.md, quantum-tunnel-claudes/SKILL.md, xrpl-typescript-fullstack.md, react-frontend.md, platform-engineer.md |
| DEEP_DIVE_COMPLETED | git/repoint-branch/SKILL.md, extract-request-learnings/extractor-prompt.md, git/create-request/SKILL.md, typescript-ci-gotchas.md, gitlab-cli.md, claude-code-hooks.md, java-infosec-gotchas.md, java-observability-gotchas.md, spring-boot-gotchas.md, postgresql-query-patterns.md, ralph/consolidate/init/SKILL.md, extract-request-learnings/SKILL.md, git/split-commit/SKILL.md, learnings/consolidate/SKILL.md, typescript-devops.md |

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
| 4 | DEEP_DIVE | 0 | 0 | 0 | none | git/repoint-branch/SKILL.md — Keep; well-scoped extraction skill, no overlap with split-request, all refs current |
| 5 | DEEP_DIVE | 0 | 0 | 0 | none | extract-request-learnings/extractor-prompt.md — Keep; Template for skill, verbatim subagent prompt, single consumer, no action needed |
| 6 | DEEP_DIVE | 0 | 0 | 0 | none | git/create-request/SKILL.md — Keep; well-scoped 12-step PR/MR workflow, all references verified (request-body-template.md direct read; pr-management.md confirmed via tracker+index; platform-detection.md confirmed iter 4) |
| 7 | DEEP_DIVE | 1 | 0 | 0 | bidirectional cross-ref (typescript-ci-gotchas.md ↔ ci-cd-gotchas.md) | typescript-ci-gotchas.md — 1 HIGH: added bidirectional See Also with ci-cd-gotchas.md; all other patterns standalone reference Keep; vercel-deployment.md and ci-cd.md cross-refs valid |
| 8 | DEEP_DIVE | 1 | 0 | 0 | fixed learnings index description for gitlab-cli.md | gitlab-cli.md — 1 HIGH: index entry over-promised (authentication, MR commands); corrected to match actual content; file content clean |
| 9 | DEEP_DIVE | 0 | 0 | 0 | none | claude-code-hooks.md — clean; 10 sections specific/accurate; bidirectional cross-ref with claude-code.md already in place; Keep |
| 10 | DEEP_DIVE | 0 | 0 | 0 | none | java-infosec-gotchas.md — clean; 7 security tripwires, compact and actionable; See Also to api-design.md valid (unidirectional asymmetry intentional — general file shouldn't pull Java-specific); Keep |
| 11 | DEEP_DIVE | 0 | 1 | 0 | added formal See Also section to java-observability-gotchas.md | java-observability-gotchas.md — 1 MEDIUM applied: added formal See Also → java-observability.md; all 4 patterns specific/actionable; index description accurate |
| 12 | DEEP_DIVE | 0 | 1 | 0 | added formal See Also section to spring-boot-gotchas.md | spring-boot-gotchas.md — 1 MEDIUM applied: added formal See Also → spring-boot.md; all 19 patterns standalone reference; bidirectional link now complete |
| 13 | DEEP_DIVE | 0 | 1 | 0 | updated learnings index description for postgresql-query-patterns.md | postgresql-query-patterns.md — 1 MEDIUM applied: index description was incomplete (omitted JSONB, schema design, migration safety); all 30+ patterns across 8 sections are standalone reference (Keep); no See Also needed |
| 14 | DEEP_DIVE | 0 | 0 | 0 | none | ralph/consolidate/init/SKILL.md — clean; all 7 templates valid, wiggum.sh path valid, allowed-tools justified, well-scoped vs resume SKILL; Keep |
| 15 | DEEP_DIVE | 0 | 1 | 0 | generalized hardcoded verification paths | extract-request-learnings/SKILL.md — 1 MEDIUM applied: step 10 verification had hardcoded Java-project filenames (code-review-general.md, spring-boot.md, code-review-patterns.md); replaced with *.md globs; all else clean (producer/consumer contract complete, all refs current); Keep |
| 16 | DEEP_DIVE | 0 | 1 | 0 | added scope clarification for same-file splits | git/split-commit/SKILL.md — 1 MEDIUM applied: steps 5–6 have logical bug for same-file splits ("restore full versions" would duplicate group 1 in second commit); added Important Notes clarification pointing to git add -p for same-file scenarios; relevant, no overlap with peer skills; Keep |
| 17 | DEEP_DIVE | 0 | 0 | 0 | none | learnings/consolidate/SKILL.md — clean; well-structured 653-line orchestrating skill; all phase logic consistent, ref paths valid, safety caps internally coherent; 2 LOWs (lab/ path example for wiggum.sh, cosmetic step numbering); Keep |
| 18 | DEEP_DIVE | 0 | 0 | 0 | none | typescript-devops.md — Keep; clean persona, valid Extends:platform-engineer, all refs current (typescript-ci-gotchas run=15, vercel-deployment run=13) |

## Deep Dive Status

<!-- Populated when PHASE transitions to DEEP_DIVE after broad sweeps complete -->

| File | Status | Iter | Summary |
|------|--------|------|---------|
| git/repoint-branch/SKILL.md | complete | 4 | Keep — well-scoped, no overlap, all refs current; stale ref fixed iter 2 |
| extractor-prompt.md | complete | 5 | Keep — Template for skill (verbatim subagent prompt), single consumer, no corpus overlap, clean |
| git/create-request/SKILL.md | complete | 6 | Keep — well-scoped 12-step workflow, all references verified, no overlap with peer skills |
| typescript-ci-gotchas.md | complete | 7 | 1 HIGH applied — bidirectional cross-ref added with ci-cd-gotchas.md (natural companion pair, pnpm/Node-specific vs stack-agnostic); all other patterns standalone reference, Keep |
| gitlab-cli.md | complete | 8 | 1 HIGH applied — fixed learnings index description (removed inaccurate "authentication, MR commands"); file content clean (3 flag-diff patterns, See Also valid/bidirectional) |
| claude-code-hooks.md | complete | 9 | Keep — 10 sections all specific/accurate; bidirectional cross-ref with claude-code.md confirmed (hooks line 99, code.md line 290); no overlap, no compression needed |
| java-infosec-gotchas.md | complete | 10 | Keep — compact 7-bullet security tripwire list; See Also to api-design.md valid (unidirectional asymmetry intentional); CORS overlap with spring-boot-gotchas complementary; no missing cross-refs |
| java-observability-gotchas.md | complete | 11 | 1 MEDIUM applied — added formal See Also → java-observability.md; informal description was present but formal section enables search protocol cross-ref discovery; all 4 patterns Keep |
| spring-boot-gotchas.md | complete | 12 | 1 MEDIUM applied — added formal See Also → spring-boot.md; all 19 one-liner patterns are standalone reference (Keep); bidirectional link now complete |
| postgresql-query-patterns.md | complete | 13 | 1 MEDIUM applied — updated learnings index description; file content clean (30+ patterns, 8 sections, all Keep); no See Also needed |
| ralph/consolidate/init/SKILL.md | complete | 14 | Keep — all 7 templates valid, wiggum.sh path valid, well-scoped vs resume SKILL, no staleness or overlap |
| extract-request-learnings/SKILL.md | complete | 15 | 1 MEDIUM applied — hardcoded Java-project filenames in step 10 verification replaced with *.md globs; producer/consumer contract verified complete; all refs current; Keep |
| git/split-commit/SKILL.md | complete | 16 | 1 MEDIUM applied — added scope clarification: workflow assumes separate-file splits; same-file splits should use git add -p; classification Keep |
| learnings/consolidate/SKILL.md | complete | 17 | Keep — well-structured orchestrating skill; all phase logic consistent, ref paths valid, safety caps coherent; 2 LOWs (lab/ path example, cosmetic step numbering) |
| typescript-devops.md | complete | 18 | Keep — clean persona; Extends:platform-engineer valid; all refs current; no compression opportunity |
| agent-prompting.md | pending | — | stale skill-ref (run=9, gap=6) |
| quantum-tunnel-claudes/SKILL.md | pending | — | stale skill (run=9, gap=6) |
| xrpl-typescript-fullstack.md | pending | — | stale persona (run=9, gap=6) |
| react-frontend.md | pending | — | stale persona (run=9, gap=6) |
| platform-engineer.md | pending | — | stale persona (run=9, gap=6) |

## Notes for Next Iteration

### Iter 18

typescript-devops.md deep dive — clean (Keep). Key notes:
- Persona is a valid specialization of platform-engineer: inherits 7-priority infra posture, adds TS/Node.js/Playwright/Vercel stack focus
- `## Extends: platform-engineer` — platform-engineer.md exists and is comprehensive (7 domain priorities, 7 review rules, 4 tradeoff rules); relationship is well-designed
- Child adds 4 domain priorities (pnpm CI, TypeScript build tooling, Playwright E2E, Vercel/serverless) not present in parent
- Child adds 3 review rules specific to TS ecosystem: pnpm-lock.yaml, eslint-config-prettier ordering, E2E non-blocking flag — all correct
- Proactive loads: typescript-ci-gotchas.md (run=15, confirmed clean iter 7) ✅
- Detailed references: vercel-deployment.md (run=13) ✅
- No `## When making tradeoffs` section — intentionally inherited from parent, correct
- No compression: all 24 lines are load-bearing; no duplicate with parent content
- Tracker key: `.claude/commands/set-persona/typescript-devops.md` set to last_deep_dive_run=15
- Next candidate: agent-prompting.md (stale skill-ref, run=9, gap=6)

### Iter 17

learnings/consolidate/SKILL.md deep dive — clean (Keep). Key notes:
- Skill is the interactive orchestrator for multi-sweep consolidation; `disable-model-invocation: true` (slash command only, correct)
- Phase logic internally consistent: Phase 1 cap=5, overall cap=15, deep dive budget check at 13 (leaves 2 sweeps for deep dive work)
- All reference paths correct: `../curate/SKILL.md`, `../curate/classification-model.md`, `../curate/persona-design.md` (resolve correctly from commands/learnings/consolidate/)
- State Variables table covers all 9 variables; reset points verified in Step 3.4 and content type transition step 2
- Step 4a cluster table is illustrative (dynamic instruction: "group all skill directories") — not stale
- Related Skills table: all 4 skills current
- LOW: Step 4a mentions `~/.claude/lab/` with wiggum.sh as example; wiggum.sh is at `~/.claude/ralph/consolidate/wiggum.sh` (confirmed iter 14). Example may mislead, but can't verify lab/ contents from worktree. Not worth acting on without certainty.
- LOW: Step numbering cosmetically odd (1, 2, 3, 1d, 4, 5, 6) — functionally clear, not worth restructuring
- Tracker key: `.claude/commands/learnings/consolidate/SKILL.md` set to last_deep_dive_run=15
- Next candidate: typescript-devops.md (stale persona, run=8, gap=7)

### Iter 16

git/split-commit/SKILL.md deep dive — 1 MEDIUM applied. Key notes:
- Skill is well-scoped: splits a single commit with mixed changes, distinct from git:repoint-branch (branch-level extraction) and git:split-request (analysis only)
- No reference files in the skill directory (standalone SKILL.md only)
- Co-Authored-By shows Claude Opus 4.6 (current); steps 1–7 are logically complete
- MEDIUM: Steps 5–6 have a logical bug for same-file splits. After committing group 1 (step 5), step 6 "Restore full versions from /tmp/ originals" would OVERWRITE working directory with the full-change version, causing the second commit to include both groups. For separate-file scenarios (the common case: e.g., docstrings + features in different files), the workflow is correct. Added clarification note to Important Notes pointing to `git add -p` as the correct approach for same-file splits.
- Tracker key: `.claude/commands/git/split-commit/SKILL.md` set to last_deep_dive_run=15
- Next candidate: learnings/consolidate/SKILL.md (stale skill, run=8, gap=7)

### Iter 15

extract-request-learnings/SKILL.md deep dive — 1 MEDIUM applied. Key notes:
- Skill is well-designed: init + continue modes, 12-step orchestration, 3 parallel writer subagents, staging dir workaround for background agent write restrictions
- All 4 reference files current: extractor-prompt.md (run=15), writer-prompt.md (just read), plan-template.md (just read), platform-detection.md (run=14), batch-operations.md (run=14)
- Producer/consumer contract COMPLETE: extractor-prompt.md line 54 produces `Language:` tag; writer-prompt.md line 37 routes by Language tag; fallback for no-tag ("treat as language-agnostic") present
- MEDIUM: Step 10 verification hardcoded Java-project filenames: `code-review-general.md`, `spring-boot.md` (wc -l line), `code-review-patterns.md` (spot-check grep). Both GitHub and GitLab variants. Fixed to `~/.claude/learnings/*.md` and `docs/learnings/*.md` globs.
- $PLAN_FILENAME derivation not defined in SKILL.md — LOW, filed for review (glob docs/plans/*.md works as workaround in practice)
- Tracker key: `.claude/commands/extract-request-learnings/SKILL.md` set to last_deep_dive_run=15
- Next candidate: git/split-commit/SKILL.md (stale skill, run=8, gap=7)

### Iter 14

ralph/consolidate/init/SKILL.md deep dive — clean (Keep). Key notes:
- Skill creates worktree, scaffolds output files from templates, runs pre-flight checks (file counts + cadence), prints launch command
- Template table (7 files) exact match with `.claude/ralph/consolidate/templates/` directory contents ✅
- `bash ~/.claude/ralph/consolidate/wiggum.sh <N>` launch command consistent with resume SKILL step 6 ✅
- allowed-tools (Read, Write, Bash, Glob) all justified: Bash for mkdir+git worktree, Write for scaffolding, Glob for pre-flight file counts
- Scope clearly distinct from resume SKILL (init=setup vs resume=evaluate+relaunch). resume already back-references init via error message.
- Cadence keywords in step 5.3 (`curate`, `compress`, `fold`, `genericize`, `deduplicate`, `prune`, `consolidat`) — not verified against wiggum.sh keyword set, but consistent with actual consolidation commit messages seen in this run's history
- No See Also added (skill file, not learnings — convention doesn't apply)
- Tracker key: `.claude/commands/ralph/consolidate/init/SKILL.md` set to last_deep_dive_run=15
- Next candidate: extract-request-learnings/SKILL.md (stale skill, run=8, gap=7)

### Iter 13

postgresql-query-patterns.md deep dive — 1 MEDIUM applied. Key notes:
- File is well-organized (63 lines, 8 sections, 30+ patterns), all patterns specific and actionable — window functions, CTEs, JSONB, partial indexes, indexing strategy, partitioning, schema design, migration safety
- All patterns → Standalone Reference (Keep). No cross-file duplicates, no compression opportunity.
- MEDIUM: Index description said "window functions, CTEs, query optimization patterns" — omitted JSONB operations, schema design patterns, and migration safety patterns (~half the file). Updated to comprehensive description covering all 8 sections. Type: false-negative (vs iter 8 gitlab-cli which was false-positive).
- Schema Design Patterns section contains project-derived examples ("currency not asset when FK targets currencies") — these are fine as concrete illustrations of general principles.
- No See Also added: no strong companion file exists. local-dev-seeding.md is different domain (seeding vs query patterns). No migration-specific file in corpus.
- Tracker key: `.claude/learnings/postgresql-query-patterns.md` set to last_deep_dive_run=15
- Next candidate: ralph/consolidate/init/SKILL.md (stale skill, run=8, gap=7)

### Iter 12

spring-boot-gotchas.md deep dive — 1 MEDIUM applied. Key notes:
- File is compact (19 bullets + new See Also), all patterns specific and actionable one-liners; no corpus overlap with spring-boot.md (the files are genuinely complementary)
- Pattern coverage: exception handling (@Scheduled/ShedLock), batching, config file format, CORS, Optional misuse, switch-null NPE, Lombok builder, logging, threading (InterruptedException), Map/collection null-safety, timezone, naming convention
- MEDIUM: added formal See Also → spring-boot.md. File had informal "Companion to spring-boot.md" description but no formal section. Corpus convention clear (all 4 other gotchas files have formal See Also). spring-boot.md already references spring-boot-gotchas.md (line 152) — bidirectional link now complete.
- No overlap detected with java-infosec-gotchas.md despite CORS pattern presence (implementation guidance vs security review tripwire — complementary, not redundant). No cross-ref from spring-boot-gotchas → java-infosec-gotchas added (CORS is the only connecting pattern, insufficient for a See Also).
- Tracker key: `.claude/learnings/spring-boot-gotchas.md` set to last_deep_dive_run=15
- Next candidate: postgresql-query-patterns.md (unreviewed learnings file, run=0)

### Iter 11

java-observability-gotchas.md deep dive — 1 MEDIUM applied. Key notes:
- File is compact (4 bullets + new See Also), all patterns specific and actionable; metrics discussion process (6-step) is a useful pre-implementation methodology, not a traditional gotcha but appropriate in the file
- DistributionSummary.builder() vs meterRegistry.summary() SLO bypass gotcha is classic Micrometer footgun — high value
- Timer try/finally outcome variable pattern is specific enough to be useful reference
- SimpleMeterRegistry testing pattern is the canonical "don't mock" gotcha for Micrometer
- MEDIUM: added formal See Also → java-observability.md. Informal "Companion to..." description was present but doesn't trigger the `## See also` search protocol follow step. All peer gotchas files (java-infosec, typescript-ci, gitlab-cli) use formal sections — corpus convention clear.
- java-observability.md → java-observability-gotchas.md: already bidirectional at run=13 (confirmed from tracker). Now fully bidirectional via formal sections.
- Tracker key: `.claude/learnings/java-observability-gotchas.md` set to last_deep_dive_run=15
- Next candidate: spring-boot-gotchas.md (unreviewed learnings file, run=0)

### Iter 10

java-infosec-gotchas.md deep dive — clean (Keep). Key notes:
- File is compact (7 bullets + See Also), all patterns specific and actionable; Jackson + XML external entities (pattern 3) uniquely Java-specific
- See Also to api-design.md is valid: api-design "Security Hardening Patterns for API Routes" is the design counterpart to these review tripwires
- No bidirectional cross-ref added to api-design.md — api-design.md is language-agnostic; adding java-infosec-gotchas to its See Also would cause false-positive loads in non-Java contexts. Asymmetry is intentional.
- CORS pattern (bullet 6) overlaps with spring-boot-gotchas line 8 (cors(Customizer.withDefaults()) bug). Not redundant — spring-boot-gotchas is implementation guidance, java-infosec is review tripwire. Complementary.
- No cross-refs between java-infosec-gotchas and java-observability-gotchas needed — orthogonal domains (security vs observability)
- Tracker key: `.claude/learnings/java-infosec-gotchas.md` set to last_deep_dive_run=15
- Next candidate: java-observability-gotchas.md (unreviewed learnings file, run=0)

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

### Iter 9

claude-code-hooks.md deep dive — clean (Keep). Key notes:
- File is compact (100 lines), 10 sections all specific, actionable, and non-overlapping
- Cross-ref with claude-code.md already bidirectional: hooks→code at line 99, code→hooks at line 290 of claude-code.md. No gap.
- Content is clearly complementary to claude-code.md — hooks API vs permission system are distinct layers; no content overlap
- PreToolUse hook authoring section includes stdin format, script pattern, settings format — complete reference
- Selective Allowlist section (lines 80-91) is a sophisticated pattern used by this very consolidation loop
- No staleness, no compression opportunity, no missing cross-refs
- tracker key: `.claude/learnings/claude-code-hooks.md` set to last_deep_dive_run=15
- Next candidate: java-infosec-gotchas.md (unreviewed learnings file, run=0)

### Iter 8

gitlab-cli.md deep dive — 1 HIGH applied. Key notes:
- File is compact (12 lines), contains exactly 3 flag-difference patterns — all standalone reference, Keep
- Learnings index description was inaccurate: "authentication, MR commands" — neither exists as a section; "authentication" would cause false-positive index loads. Corrected to precise description matching file scope.
- See Also: gitlab-ci-cd.md exists and is valid; already bidirectional (gitlab-ci-cd.md → gitlab-cli.md at line 53). No new cross-refs needed.
- ci-cd-gotchas.md cross-ref not needed (different domain: CI config gotchas vs CLI flag behavior); connected via gitlab-ci-cd.md hub.
- tracker key: `.claude/learnings/gitlab-cli.md` set to last_deep_dive_run=15
- Next candidate: claude-code-hooks.md (unreviewed learnings file, run=0)

### Iter 7

typescript-ci-gotchas.md deep dive — 1 HIGH applied. Key notes:
- File is compact (28 lines), all 10 patterns are specific and useful — Standalone reference, Keep
- No cross-file duplicates found (grep confirmed --frozen-lockfile in git-patterns.md is a different use case: conflict resolution vs CI enforcement)
- See Also staleness check: vercel-deployment.md and ci-cd.md both confirmed in learnings index — valid
- Missing cross-ref detected: ci-cd-gotchas.md (stack-agnostic companion) not referenced directly; only mentioned parenthetically in ci-cd.md entry. Added bidirectional See Also.
- ci-cd-gotchas.md tracker entry reset to 0 per "track touched files" rule (modified by HIGH action)
- Read path constraint reminder: guard blocks tilde reads; must use worktree-absolute paths. Edit requires Read of same path — do NOT mix read path vs edit path.
- Next candidate: gitlab-cli.md (unreviewed learnings file, run=0)

### Iter 6

git/create-request/SKILL.md deep dive — clean (Keep). Key notes:
- Skill is well-scoped: 12-step PR/MR creation workflow, distinct from split-request (analyze), code-review-request (review), explore-request (Q&A), repoint-branch (extract to new PR)
- Grep scope insight: skill-references files can't be globbed (symlink issue) but ARE accessible via Read using worktree `.claude/` path AND Grep finds them. For wiring checks, use Grep for filename patterns rather than Glob.
- All references verified: request-body-template.md (direct read), github/pr-management.md + gitlab/pr-management.md (confirmed via tracker entry at run=14 + commands.md index listing), platform-detection.md (confirmed iter 4)
- No compression needed, no cross-refs missing, no corpus overlap
- Next candidate: typescript-ci-gotchas.md (unreviewed learnings file, run=0)

### Iter 5

extractor-prompt.md deep dive — clean (Keep). Key notes:
- File is a verbatim subagent prompt template; classification = Template for skill (HIGH)
- Single consumer: extract-request-learnings/SKILL.md (step 7 + line 19 reference)
- No corpus overlap, no compression opportunity (all ~68 lines are load-bearing placeholders/instructions)
- No cross-refs needed (prompt templates don't use cross-refs — not a learnings file)
- Next candidate: git/create-request/SKILL.md (skill file, last_deep_dive_run=0)

### Iter 4

git/repoint-branch/SKILL.md deep dive — clean (Keep). Key notes:
- Skill is well-scoped: extracts files from compound branch to new PR, clearly differentiated from /git:split-request (analyze vs execute)
- No reference files to audit; platform-detection.md ref is shared/current
- Stale /pr ref fixed iter 2; all wiring current
- Next candidate: extractor-prompt.md (content file in extract-request-learnings/, last_deep_dive_run=0)

### Iter 3

GUIDELINES broad sweep complete over all 4 guideline files. Corpus in good shape. Key findings:
- All 4 files @-referenced in CLAUDE.md — properly wired, no orphaned guidelines
- skill-invocation.md and path-resolution.md: clean, minimal always-on cost
- communication.md (~180 lines): dense behavioral rules, all universal; LOW compression flag (risk of nuance loss)
- context-aware-learnings.md (~130 lines): large always-on methodology; restructuring blocked — session-start hard gate must fire before first tool call; LOW for growth monitoring
- Broad sweep complete (L→S→G). Transitioning to DEEP_DIVE phase.
- 20 deep-dive candidates: 1 modification-triggered + 2 unreviewed skills + 7 unreviewed learnings + 10 stale skills/personas/skill-refs
