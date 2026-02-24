# Implementation Plan: Claude Skills Best Practices

## Overview

This plan applies research findings from `info.md`, `codebase-summary.md`, and `assumptions-and-questions.md` to improve the 22-skill collection at `~/.claude/commands/`. Changes are grouped into phases by dependency and risk, with parallelization opportunities marked.

---

## Phase 0: Measure & Validate (Pre-Implementation)

**Goal**: Establish baseline metrics before making changes.

**Why first**: Validates assumptions before mass-editing. ~~Context budget pressure was a key motivator, but~~ [research shows only 31% budget utilization](./skill-context-budget.md) — no pressure exists. Phase 0.1 is now a low-priority confirmation step.

| Task | Description | Depends On | Priority |
|------|-------------|------------|----------|
| **0.1** Confirm context budget | Run `/context` in a live session. Expected: no warning about excluded skills, confirming theoretical analysis (~31% utilization). | None | Low (nice-to-have confirmation) |
| **0.2** ~~Audit SKILL.md line counts~~ | **DONE** — 1 skill over limit: `learnings/consolidate` (640 lines). `learnings/curate` borderline (450). See [skill-context-budget.md](./skill-context-budget.md) §5. | None | Complete |
| **0.3** Build validation script | Create a custom validation script (shell) that checks structural + semantic validity. Budget estimation feature is **low priority** (not needed at 31% utilization). See [skill-testing-validation.md](./skill-testing-validation.md). | None | Medium |

**Outputs**: ~~Baseline context consumption number.~~ Confirmed via research: ~4,908/16,000 chars. Line count audit complete: 1 violation (`learnings/consolidate`). Working validation script.

**Parallelizable**: 0.1 and 0.3 can run concurrently.

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

### 1E: Add `compatibility` Field (Optional, Zero-Cost)

**Ref**: Open Item O18, [cross-platform-compatibility.md](./cross-platform-compatibility.md) §4

Add the spec-standard `compatibility:` field to all 22 skills signaling portability tier and runtime requirements.

**Change per skill**: Add one line to YAML frontmatter:
```yaml
compatibility: <tier-appropriate message>
```

Tier messages:
- **Tier 1** (prune-merged, repoint-branch, do-refactor-code): `Works with any Agent Skills-compatible tool. Requires git and gh CLI.`
- **Tier 2** (10 git/general skills): `Designed for Claude Code. Core workflow may work in other Agent Skills tools.`
- **Tier 3** (9 orchestration-heavy skills): `Requires Claude Code (uses subagent orchestration and interactive tools).`

**Effect**: Signals to non-Claude-Code users what to expect. Zero runtime impact. Spec-standard field recognized by multiple platforms.

**Validation**: Run `skills-ref validate` — `compatibility` is a recognized spec field.

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

Add to these 4 skills:
- `ralph/init` — research project setup, always user-initiated
- `ralph/compare` — directory comparison, always user-initiated
- `quantum-tunnel-claudes` — skill sync, always user-initiated
- `set-persona` — session config, always user-initiated

**Change per skill**: Add one line to YAML frontmatter:
```yaml
disable-model-invocation: true
```

**Effect**: Removes these 4 descriptions from context budget. Claude won't auto-invoke them (nor should it — they're all deliberate user actions).

**Validation**: Run `/context` after applying. Compare to Phase 0 baseline. Verify these skills still appear in `/` menu.

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
- `ralph/init`, `ralph/compare`, `quantum-tunnel-claudes`, `set-persona`

**Validation**: Invoke skills via natural language and verify correct routing.

---

## Phase 3: Reference Architecture Improvements (Medium Risk)

**Goal**: Optimize token usage by restructuring how skills load content.

**Depends on**: Phase 0.2 (line count audit identifies which skills need restructuring).

### 3A: Extract Large Inline Content to Reference Files

If Phase 0.2 identifies SKILL.md files over 500 lines, extract conditional-use content into separate reference files.

**Pattern**:
```markdown
# Before (inline)
## Detailed Reference
(200 lines of reference content used only in edge cases)

# After (extracted)
## Reference Files
- detailed-reference.md - Edge case patterns (read only when needed)
```

**Candidate skills** (likely longest, pending audit):
- `learnings/compound` (6 existing refs — may have grown)
- `parallel-plan/execute` (complex orchestration)
- `ralph/init` (includes full spec template via `@`)

### 3B: Review `@` (Eager) Reference Usage

Currently 2 skills use `@` references:
- `ralph/init` → `@spec-template.md`, `@progress-template.md`
- `explore-repo` → `@agent-prompts.md`

**Evaluate**: Are these files <30 lines AND needed every invocation? If not, switch to conditional references.

### 3C: Add Dynamic Context Injection

**Ref**: [dynamic-context-injection.md](./dynamic-context-injection.md) (deep research completed)

Add `## Context` section with `!`command`` preprocessing to 10 skills:

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

```
Phase 0: [0.1 Measure context] ──────┐
         [0.2 Audit line counts] ─────┤ All parallel
         [0.3 Build validation script]┘
                      │
                      ▼
Phase 1: [1A disable-model-invocation] ─┐
         [1B argument-hint]             ├── All parallel (independent)
         [1C fix stale settings]        │
         [1D add name field]            │
         [1E add compatibility field]   │
         [1F add allowed-tools]        ─┘
                      │
                      ▼
Phase 2: [2A Description quality pass]
                      │
                      ▼
Phase 3: [3A Extract large content] ──┐
         [3B Review @ references]     ├── All parallel
         [3C Dynamic injection eval] ─┘
                      │
                      ▼
Phase 4: [4A model: overrides] ───────┐
         [4B hooks evaluation]        ├── All parallel (independent evaluations)
         [4C agents/ definitions] ────┘
                      │
                      ▼
Phase 5: [5A Context check]  ─────────┐
         [5B Skill validation]        ├── 5A first, then 5B/5C parallel
         [5C Update learnings] ───────┘
                      │
                      ▼
Phase 6: [6A Verify namespace behavior] ──┐
                      │                   │
                      ▼                   │
         [6B Tier 1 plugins] ────────┐    │
         [6C Tier 2 plugins] ────────┤    │ All depend on 6A
                      │              │    │
                      ▼              │    │
         [6D Create marketplace] ────┘    │
                      │                   │
                      ▼                   │
         [6E Test and publish] ───────────┘
         [6F Cross-platform layout] ───────── Optional, after 6B/6C
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

1. **Do first**: Phase 0 (baseline) → Phase 1 (quick wins). These are high-value, low-risk, and inform everything else.
2. **Do next**: Phase 2 (descriptions) → Phase 3 (references). Medium value, builds on Phase 1 data.
3. **Do if time/interest**: Phase 4 (advanced features). Lower priority, higher complexity.
4. **Always do last** (pre-distribution): Phase 5 (validation). Catches regressions.
5. **Distribution**: Phase 6 (plugin packaging). After all improvements are validated, package and publish.

---

## Decisions Requiring User Input

1. **`commands/` → `skills/` migration**: Research says it's functionally equivalent but `skills/` is the newer convention. Worth the rename churn? (See A1, Q2) **ANSWER: Defer.**
2. ~~**Context budget threshold**~~: **RESOLVED** — [Research shows 31% utilization](./skill-context-budget.md). All 22 skills fit comfortably. Phase 1A priority unchanged (invocation control, not budget). Phase 2A deprioritized from budget optimization to routing quality.
3. ~~**Cross-platform portability**~~: **RESOLVED** — [Research shows all planned changes degrade gracefully](./cross-platform-compatibility.md). Frontmatter is maximally portable. Body content is CC-specific but not worth rewriting. Added Phase 1E (`compatibility` field) and Phase 6F (optional `.agents/skills/` layout). No existing plan changes needed. **ANSWER: Plan to share.** Implementation adds `compatibility` field (1E) and optional cross-platform layout (6F).
4. **Model overrides** (Phase 4A): Only worth doing if the user actively wants to reduce costs on simple skills. Otherwise skip.
5. **Plugin name prefix** (Phase 6): All plugins need a consistent prefix (`mahoy-`?). Affects invocation UX. See Q6 in assumptions-and-questions.md.
6. **License** (Phase 6): Needed for all distributed plugins. MIT recommended for open sharing. See [plugin-packaging-strategy.md](./plugin-packaging-strategy.md) §13.
7. **Marketplace repo name** (Phase 6): Where to host the marketplace. Options: `ahoym/mahoy-skills`, `ahoym/claude-plugins`, etc.
8. **Ralph as plugin?** (Phase 6): Should ralph/ skills be packaged as a separate plugin or kept personal-only?
