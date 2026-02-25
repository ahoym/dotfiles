# Implementation Plan: Claude Skills Best Practices

## Overview

This plan applies research findings from `info.md`, `codebase-summary.md`, and `assumptions-and-questions.md` to improve the 26-skill collection at `~/.claude/commands/`. Changes are grouped into phases by dependency and risk, with parallelization opportunities marked.

### Session Decisions (2026-02-24)

Decisions made during implementation planning discussion:
- **`disable-model-invocation` expanded from 4 → 9 skills**: Added consolidate, curate, parallel-plan/execute, ralph/resume, ralph/brief, ralph/cleanup. Kept set-persona auto-invocable (useful for Claude to suggest domain switching).
- **Dynamic context injection extended**: Added ralph/brief and ralph/resume (branch auto-detection for research projects). cascade-rebase explicitly included.
- **Phase 0.1 confirmed live**: `/context` shows 769 tokens (0.4%) for skills, all 25 loaded, no exclusions.
- **Phase 0.3 deferred**: Validation script not needed before Phase 1 (changes are simple YAML additions).
- **Phase 1E deferred**: `compatibility` field — cross-platform knowledge captured but not implementing now.
- **Phase 2A included**: Description quality pass included in first execution round.
- **O8 deferred**: `learnings/consolidate` line count (640 lines) — separate curation effort.
- **Phases 4-6 deferred**: Hooks, agents, model overrides, plugin packaging — future work.
- **Execution approach**: `/parallel-plan:make` + `/parallel-plan:execute` to dogfood the skills. Group by skill file (not task type) so each subagent applies all changes to its batch in one pass.

---

## Phase 0: Measure & Validate (Pre-Implementation)

**Goal**: Establish baseline metrics before making changes.

**Why first**: Validates assumptions before mass-editing. ~~Context budget pressure was a key motivator, but~~ [research shows only 31% budget utilization](./skill-context-budget.md) — no pressure exists. Phase 0.1 is now a low-priority confirmation step.

| Task | Description | Depends On | Status |
|------|-------------|------------|--------|
| **0.1** ~~Confirm context budget~~ | **DONE** — Live `/context` confirmed: 769 tokens (0.4%), all 25 skills loaded, no exclusions. Matches theoretical analysis. | None | **Complete** |
| **0.2** ~~Audit SKILL.md line counts~~ | **DONE** — 1 skill over limit: `learnings/consolidate` (640 lines). `learnings/curate` borderline (450). See [skill-context-budget.md](./skill-context-budget.md) §5. | None | **Complete** |
| **0.3** Build validation script | Deferred — not needed before Phase 1 (changes are simple YAML additions). Future CI safety net. See [skill-testing-validation.md](./skill-testing-validation.md). | None | **Deferred** |

**Outputs**: Phase 0 complete. Budget confirmed live. Line count audit complete.

---

## Phase 1: Quick Wins — Frontmatter Additions (Low Risk)

**Goal**: Add metadata that improves UX and context efficiency with zero behavioral change.

All Phase 1 tasks are independent and can run in parallel.

### 1D: Add `name` Field to All Skills

**Ref**: Open Item O13, [skill-testing-validation.md](./skill-testing-validation.md) §10

Add the spec-required `name:` field to all 22 SKILL.md frontmatter blocks. Set to match immediate parent directory name (e.g., `name: create-pr` for `git/create-pr/SKILL.md`).

**Change per skill**: Add one line to YAML frontmatter:
```yaml
name: <directory-name>
```

**Effect**: Spec compliance, self-documenting skills, enables `skills-ref read-properties` and `to-prompt` commands. Harmless in Claude Code (which accepts explicit `name` or infers from directory).

**Validation**: Run Phase 0.3 validation script. Optionally run `skills-ref validate` on individual skills (will still report Claude Code extension fields as errors, but `name` errors should disappear).

### ~~1E: Add `compatibility` Field~~ — Deferred

**Deferred**: Cross-platform knowledge captured in research but not implementing now. Revisit when plugin distribution is pursued.

### 1F: Add `allowed-tools` to 13 Skills (Intent-Signaling)

**Ref**: Open Item O5, [allowed-tools-adoption.md](./allowed-tools-adoption.md)

Add `allowed-tools` YAML lists to 13 skills as documentation/intent-signaling. Enforcement is broken (#14956) but the field is harmless and prepares for future enforcement.

**Skills**: 5 Tier 1 (read-only: explore-repo, do-security-audit, split-pr, explore-pr, ralph/compare) + 8 Tier 2 (narrowly-scoped: do-refactor-code, learnings/compound, learnings/curate, learnings/distribute, set-persona, ralph/init, prune-merged, repoint-branch).

**Change per skill**: Add YAML list block to frontmatter:
```yaml
allowed-tools:
  - Read
  - Glob
  - Grep
  # ... skill-specific tools
```

**Not applied to** (Tier 3 orchestrators): create-pr, address-pr-review, resolve-conflicts, cascade-rebase, monitor-pr-comments, parallel-plan/make, parallel-plan/execute, learnings/consolidate, quantum-tunnel-claudes.

**Effect**: Documents design intent. Zero runtime impact while enforcement is broken. Trail of Bits uses same pattern.

**Validation**: Verify skills still function normally (no behavioral change expected).

### 1A: Add `disable-model-invocation: true` to Manual-Only Skills

**Ref**: Assumption A6, Open Item O2

Add to these 9 skills:
- `ralph/init` — research project setup, always user-initiated
- `ralph/compare` — directory comparison, always user-initiated
- `ralph/resume` — always explicit invocation
- `ralph/brief` — always explicit invocation
- `ralph/cleanup` — always explicit invocation
- `quantum-tunnel-claudes` — skill sync, always user-initiated
- `learnings/consolidate` — heavyweight multi-sweep, always explicit
- `learnings/curate` — primarily a delegate of consolidate
- `parallel-plan/execute` — always follows make, user-driven

**Kept auto-invocable** (user decision): `set-persona` (useful for Claude to suggest domain switching), `parallel-plan/make` (Claude may suggest parallelizing), `learnings/distribute` (Claude may suggest in new projects), `learnings/compound` (designed for auto-invocation after tasks).

**Change per skill**: Add one line to YAML frontmatter:
```yaml
disable-model-invocation: true
```

**Effect**: Removes 9 skill descriptions from context budget. Reduces noise in Claude's skill selection. Prevents accidental invocation of heavyweight operations.

**Validation**: Run `/context` after applying. Confirm 9 skills no longer listed. Verify they still work via `/skill-name`.

### 1B: Add `argument-hint` to Argument-Taking Skills

**Ref**: Assumption A7, Open Item O3

Add autocomplete hints:

| Skill | Hint |
|-------|------|
| `do-refactor-code` | `[filepath]` |
| `explore-pr` | `[pr-number]` |
| `address-pr-review` | `[pr-number]` |
| `set-persona` | `[persona-name]` |
| `ralph/init` | `[topic]` |
| `ralph/compare` | `[dir1] [dir2]` |
| `monitor-pr-comments` | `[pr-number]` |
| `explore-repo` | `[repo-path]` |

**Change per skill**: Add one line to YAML frontmatter:
```yaml
argument-hint: "[value]"
```

**Effect**: Autocomplete shows the expected argument format when user types `/skill-name`.

**Validation**: Invoke each skill with `/` in a session and verify hint displays.

### 1C: Fix Stale Settings

**Ref**: Assumption A8, Open Item O4

Fix `settings.local.json`:
1. `compound-learnings/` → `learnings/compound/` (stale rename)
2. `Read(~.claude/*)` → `Read(~/.claude/*)` (missing `/`)

**Effect**: Dead permission entries become functional.

**Validation**: Verify no permission regressions by testing Bash/Read access patterns used by affected skills.

---

## Phase 2: Description Quality Pass (Low Risk)

**Goal**: Improve skill descriptions for better **agent routing accuracy**. ~~Context budget savings~~ are not a motivator — [budget is at 31% utilization](./skill-context-budget.md).

**Depends on**: Phase 1A (context budget changes affect which descriptions matter most).

### 2A: Audit & Optimize Descriptions

Review all 22 skill descriptions against these criteria from `info.md`:

1. **Functional** — Describe what the skill does (verb-first). Add "Use when..." routing hints only if the name + description alone isn't sufficient for Claude to infer when to invoke.
2. **No jargon** — Replace internal terminology with widely understood terms.
3. **Action keywords** — Include verbs describing what happens.
4. **Concise** — Prefer shorter descriptions for clarity, but **don't compress aggressively** — budget headroom is ample.

**Priority targets** (skills most likely to be auto-invoked, where description quality matters most):
- `git/create-pr`, `git/address-pr-review`, `git/resolve-conflicts` — high-frequency git workflows
- `learnings/compound`, `learnings/curate` — knowledge management
- `do-refactor-code`, `do-security-audit` — analysis tasks
- `explore-repo` — codebase exploration

**Routing phrase review** — test whether `parallel-plan:make` (222 chars) and `parallel-plan:execute` (225 chars) route correctly without their "Use when..." phrases (~100 chars each). These are the longest descriptions; the routing phrases may be unnecessary given the clear skill names.

**Lower priority** (skills getting `disable-model-invocation: true` don't need routing optimization since their descriptions won't be in context):
- `ralph/init`, `ralph/compare`, `ralph/resume`, `ralph/brief`, `ralph/cleanup`, `quantum-tunnel-claudes`, `learnings/consolidate`, `learnings/curate`, `parallel-plan/execute`

**Included in first execution round** alongside Phase 1 (user decision).

**Validation**: Invoke skills via natural language and verify correct routing.

---

## Phase 3: Reference Architecture Improvements (Medium Risk)

**Goal**: Optimize token usage by restructuring how skills load content.

**Depends on**: Phase 0.2 (line count audit identifies which skills need restructuring).

### ~~3A: Extract Large Inline Content to Reference Files~~ — Deferred

Deferred as separate curation effort. `learnings/consolidate` (640 lines) is the only violation. User will handle individually.

### ~~3B: Review `@` (Eager) Reference Usage~~ — Deferred

Deferred alongside 3A.

### 3C: Add Dynamic Context Injection

**Ref**: [dynamic-context-injection.md](./dynamic-context-injection.md) (deep research completed)

Add `## Context` section with `!`command`` preprocessing to 12 skills:

| Skill | Injection(s) | Tokens Added |
|-------|-------------|-------------|
| `git/create-pr` | branch name, bounded commit log | ~105 |
| `git/address-pr-review` | branch name | ~5 |
| `git/resolve-conflicts` | branch name | ~5 |
| `git/explore-pr` | branch name | ~5 |
| `git/repoint-branch` | branch name, bounded changed files | ~105 |
| `git/split-pr` | branch name | ~5 |
| `git/monitor-pr-comments` | branch name, repo identifier | ~13 |
| `git/cascade-rebase` | branch name | ~5 |
| `explore-repo` | project root, branch name, HEAD hash | ~18 |
| `learnings/distribute` | project root | ~10 |
| `ralph/brief` | branch name (auto-detect research project) | ~5 |
| `ralph/resume` | branch name (auto-detect research project) | ~5 |

**Included in first execution round** alongside Phase 1 (user decision). Grouping by skill file means each subagent applies frontmatter + injection together.

**Implementation pattern:**
```markdown
## Context
- Current branch: !`git branch --show-current 2>/dev/null`
```

**Not recommended** (from research): PR number detection (`gh pr view`), full branch lists, unbounded diffs/logs.

**Validation**: Invoke each modified skill in a git repo AND a non-git directory. Verify graceful degradation with `2>/dev/null`.

---

## Phase 4: Advanced Frontmatter Adoption (Medium Risk)

**Goal**: Adopt Claude Code-specific features where they provide clear value.

**Depends on**: Phases 1-2 completed. These are more nuanced changes.

### 4A: Evaluate `model:` Overrides

**Ref**: Q5 in assumptions-and-questions.md

Consider per-skill model overrides for clear cases:

| Skill | Model | Rationale |
|-------|-------|-----------|
| `prune-merged` | `haiku` | Simple git cleanup — no reasoning needed |
| `distribute` | `haiku` | Straightforward file operations |

**Risk**: Model overrides add maintenance complexity. Default model is usually appropriate. Only apply where there's a clear cost/speed benefit with no quality loss.

**Recommendation**: Low priority. Only implement if the user actively wants to reduce token costs for simple operations.

### 4B: Add `hooks` to Skill Frontmatter

**Ref**: [hooks-integration.md](./hooks-integration.md), Open Item O7

Research completed. Two high-confidence skill-scoped hooks identified. Remaining candidates belong in project/user settings, not skill frontmatter.

**Tier 1 — Implement in skill frontmatter:**

| Skill | Hook | Type | Purpose |
|-------|------|------|---------|
| `git/resolve-conflicts` | PostToolUse(`Edit`) | `command` | Grep for residual conflict markers (`<<<<<<<`) in edited files |
| `quantum-tunnel-claudes` | PostToolUse(`Edit`) | `command` | Section count check — detect if merge dropped content |

**Tier 2 — Implement in settings (not skill-scoped):**

| Hook | Scope | Purpose |
|------|-------|---------|
| PostToolUse(`Edit\|Write`) → formatter | Project settings | Auto-format after any file edit |
| PreToolUse(`Edit\|Write`) → protect secrets | User settings | Block edits to `.env`/credentials |
| PostToolUse(`Edit` → CLAUDE.md) → section check | Project settings | Verify CLAUDE.md sections preserved |

**Tier 3 — Defer** (not worth the complexity): do-refactor-code, learnings/compound, learnings/consolidate, parallel-plan/execute, git/address-pr-review, explore-repo. Either the skill's existing instructions already cover the check, the validation is project-specific, or the check requires prompt/agent hooks whose latency cost isn't justified.

**Risk**: Low for Tier 1 (simple shell commands, PostToolUse can't block execution). Medium for Tier 2 (settings-level hooks affect all sessions).

**Dependencies**: `jq` must be installed for JSON parsing in hook scripts.

**Recommendation**: Medium priority. Implement Tier 1 as proof-of-concept alongside other Phase 4 work. Evaluate Tier 2 after Phase 5 validation.

### 4C: Create `agents/` Custom Subagent Definitions

**Ref**: Codebase summary improvement opportunity #6, [subagent-configuration-patterns.md](./subagent-configuration-patterns.md)

Create custom agent definitions in `~/.claude/agents/` to complement skills that spawn Task subagents. Key value: persistent `memory` that lets agents learn across sessions.

| Step | Agent | Skills Affected | Memory | Model | Risk |
|------|-------|----------------|--------|-------|------|
| 4C.1 | `pr-reviewer` | address-pr-review | `user` | inherit | Low |
| 4C.2 | Extend `pr-reviewer` | explore-pr, monitor-pr-comments | `user` | inherit | Low |
| 4C.3 | `codebase-explorer` | explore-repo, do-security-audit | `project` | haiku | Low-Medium |
| 4C.4 | Evaluate results, decide on further agents | — | — | — | — |

**Critical constraint**: Subagents cannot spawn other subagents. `explore-repo` uses `general-purpose` specifically so agents "can spawn sub-agents if they encounter too many files." Migrating to a custom agent may break this. **Verify empirically before migrating** (4C.3).

**Implementation pattern**: Skills reference custom agents via `subagent_type: "pr-reviewer"` in Task tool calls. The agent definition provides tools, model, memory scope, and system prompt.

**Recommendation**: Medium priority. Start with `pr-reviewer` as proof-of-concept — highest overlap (3 skills), low risk (read-only), and `memory: user` provides immediate value.

---

## Phase 5: Validation & Documentation (Low Risk)

**Goal**: Ensure all changes work correctly and knowledge is captured.

**Depends on**: All previous phases.

### 5A: Post-Implementation Context Budget Check

Run `/context` again. Compare to Phase 0 baseline:
- Confirm `disable-model-invocation` skills are excluded from budget
- Confirm no skills are silently dropped
- Record new baseline for future reference

### 5B: Validate Skill Invocations

Manually test each modified skill:
- `/skill-name` — does it still work?
- Does the argument hint display?
- Do conditional references load correctly?

### 5C: Update Learnings

Capture implementation outcomes in `~/.claude/learnings/`:
- What worked well
- What didn't work as expected
- Updated best practices based on empirical results

---

## Phase 6: Plugin Packaging & Distribution

**Goal**: Convert skill collection into distributable plugins and publish via marketplace.

**Ref**: [plugin-packaging-strategy.md](./plugin-packaging-strategy.md) (deep research completed)

**Depends on**: Phases 1D (name field), 3C (dynamic injection), 4B (hooks), 4C (agents). These should be done first so plugins ship with all improvements.

### 6A: Verify Namespace Behavior

**Ref**: Open Item O17, Assumption A16

Empirically test whether nested skill directories inside a plugin create nested namespaces. Create a minimal test plugin and check with `--plugin-dir`.

**Outcome**: Determines whether Phase 6B must flatten `git/create-pr/` → `create-pr/` or can keep nesting.

### 6B: Create Plugin Directory Structures (Tier 1)

**Ref**: Open Item O14, [plugin-packaging-strategy.md](./plugin-packaging-strategy.md) §12

Create two Tier 1 plugins:

| Plugin | Skills | Agents | Hooks |
|--------|--------|--------|-------|
| `mahoy-git` | 9 git skills | pr-reviewer (from 4C) | conflict-check (from 4B) |
| `mahoy-parallel-plan` | 2 parallel-plan skills | — | — |

For each:
1. Create `.claude-plugin/plugin.json` manifest
2. Copy skills into `skills/` (flatten if 6A requires)
3. Bundle required `skill-references/`
4. Update SKILL.md paths to plugin-relative (O16)
5. Add README.md, LICENSE, CHANGELOG.md

### 6C: Create Plugin Directory Structures (Tier 2)

| Plugin | Skills | Notes |
|--------|--------|-------|
| `mahoy-explore` | explore-repo, do-refactor-code, do-security-audit | Broadly useful |
| `mahoy-learnings` | compound, consolidate, curate, distribute | Knowledge management |

### 6D: Create Marketplace Repository

**Ref**: Open Item O15, [plugin-packaging-strategy.md](./plugin-packaging-strategy.md) §4

1. Create GitHub repo (e.g., `ahoym/mahoy-skills`)
2. Create `.claude-plugin/marketplace.json`
3. Add plugins as subdirectories with relative source paths
4. Test locally: `/plugin marketplace add ./path`

### 6E: Test and Publish

1. Test each plugin with `claude --plugin-dir`
2. Test marketplace installation flow
3. Push to GitHub
4. Document installation in marketplace README

**Parallelizable**: 6B and 6C can run in parallel (independent plugins). 6D depends on both.

### 6F: Cross-Platform Discovery Layout (Optional)

**Ref**: Open Item O19, [cross-platform-compatibility.md](./cross-platform-compatibility.md) §5

If cross-platform distribution beyond Claude Code marketplace is desired:

1. Structure each plugin repo to include `.agents/skills/<name>/SKILL.md` (universal discovery path supported by all 8+ platforms)
2. Add `COMPATIBILITY.md` listing per-skill portability tier (Tier 1/2/3)
3. Add installation instructions for non-Claude-Code platforms
4. Consider SkillPort integration for multi-platform delivery

**Depends on**: 6B/6C (plugin structures exist).
**Priority**: Low — only if cross-platform sharing demand materializes.

---

## Parallelization Map

### First Execution Round (Phases 0-3C + 2A)

Grouped by skill file for parallel execution via `/parallel-plan:execute`:

```
Phase 0: [0.1 DONE] [0.2 DONE] [0.3 Deferred]

         [Stream 1: Git skills (9 files)]     ─┐
         [Stream 2: Ralph skills (5 files)]    ├── All parallel (different files)
         [Stream 3: Learnings skills (4 files)] │
         [Stream 4: Standalone skills (8 files)]│
         [Stream 5: Settings fix (1 file)]    ─┘
                      │
                      ▼
         [Stream 6: Description quality pass] ── Sequential (reviews all descriptions)
                      │
                      ▼
         [Verification: /context + manual testing]
```

Each stream applies ALL applicable changes (name, disable-model-invocation, argument-hint, allowed-tools, dynamic injection) to its batch of skills in a single pass.

### Future Rounds (Deferred)

```
Phase 4: [4A model: overrides] ───────┐
         [4B hooks (2 skills)]        ├── All parallel
         [4C agents/ definitions] ────┘
                      │
                      ▼
Phase 5: [5A Context check]  ─────────┐
         [5B Skill validation]        ├── 5A first, then 5B/5C parallel
         [5C Update learnings] ───────┘
                      │
                      ▼
Phase 6: [6A-6F Plugin packaging] ──── Blocked on user decisions Q8-Q12
```

---

## Effort Estimates

| Phase | Tasks | Complexity | Notes |
|-------|-------|------------|-------|
| **0** | 2 | Trivial | Manual commands in a live session |
| **1** | 3 | Low | One-line frontmatter additions |
| **2** | 1 | Low-Medium | Requires judgment on description quality |
| **3** | 3 | Medium | Requires reading and restructuring skill files |
| **4** | 3 | Medium-High | Requires evaluation and possibly new files |
| **5** | 3 | Low | Verification and documentation |
| **6** | 5 | Medium-High | Plugin packaging, marketplace creation, path migration |

---

## Recommended Execution Order

1. **First round** (ready now): Phases 1A/1B/1C/1D/1F + 3C + 2A. All frontmatter additions, dynamic injection, settings fix, and description quality. Execute via `/parallel-plan:make` + `/parallel-plan:execute`.
2. **Future**: Phase 4 (hooks, agents, model overrides). Lower priority, higher complexity.
3. **Future**: Phase 5 (validation). After Phase 4.
4. **Future**: Phase 6 (plugin packaging). Blocked on user decisions Q8-Q12.

---

## Decisions Requiring User Input

### Resolved

1. **`commands/` → `skills/` migration**: **ANSWER: Defer.** Functionally equivalent.
2. ~~**Context budget threshold**~~: **RESOLVED** — 31% utilization, confirmed live (769 tokens, 0.4%).
3. ~~**Cross-platform portability**~~: **RESOLVED** — Plan to share. `compatibility` field deferred for now.
4. **`disable-model-invocation` list**: **ANSWER: 9 skills.** Added consolidate, curate, parallel-plan/execute, ralph/resume, ralph/brief, ralph/cleanup. Kept set-persona auto-invocable.
5. **Validation script timing**: **ANSWER: Deferred.** Not needed before Phase 1.
6. **O8 (consolidate line count)**: **ANSWER: Separate effort.** User will curate individually.
7. **Dynamic injection scope**: **ANSWER: 12 skills.** Added ralph/brief and ralph/resume for research branch auto-detection.
8. **Phase 2A timing**: **ANSWER: Include in first round** alongside Phase 1.

### Open (Block Phase 4+/6)

9. **Model overrides** (Phase 4A): Only if user wants to reduce costs on simple skills.
10. **Plugin name prefix** (Phase 6): `mahoy-`? See Q6 in assumptions-and-questions.md.
11. **License** (Phase 6): MIT recommended. See [plugin-packaging-strategy.md](./plugin-packaging-strategy.md) §13.
12. **Marketplace repo name** (Phase 6): `ahoym/mahoy-skills`, `ahoym/claude-plugins`, etc.
13. **Ralph as plugin?** (Phase 6): Distribute or keep personal-only?
