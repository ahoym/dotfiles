# Implementation Plan: Claude Skills Best Practices

Phased plan for applying best-practice frontmatter to the 22 skills in `~/.claude/commands/`.

**Key research conclusions driving this plan:**
- Stay on `commands/` — no directory rename needed ([commands-to-skills-migration.md](./commands-to-skills-migration.md))
- `disable-model-invocation: true` is highest impact, lowest risk ([disable-model-invocation.md](./disable-model-invocation.md))
- `allowed-tools` enforcement is broken; add for documentation/intent-signaling only ([allowed-tools-scoping.md](./allowed-tools-scoping.md))
- `context: fork` is largely inapplicable; only 1 viable candidate ([context-fork-candidates.md](./context-fork-candidates.md))

---

## Phase 1: `disable-model-invocation: true` on 9 Manual-Only Skills

**Risk:** Minimal — these skills are never auto-invoked today, so disabling auto-invocation changes nothing about how they're used.

**Impact:** Removes 1,464 chars (9.2%) from context budget. More importantly, reduces noise in Claude's skill selection and prevents accidental invocation of heavyweight operations.

**Known bugs to communicate to user:**
- Skills must be invoked at message start (`/skill-name ...`), not mid-sentence (Bug [#19729](https://github.com/anthropics/claude-code/issues/19729))
- Autocomplete shows disabled skills but errors on selection (Bug [#24042](https://github.com/anthropics/claude-code/issues/24042)) — user types the full command anyway

### Changes

Each skill gets a single frontmatter line added. No other changes.

| Skill | File | Chars Saved |
|:------|:-----|:------------|
| `learnings:consolidate` | `~/.claude/commands/learnings/consolidate/SKILL.md` | 259 |
| `parallel-plan:execute` | `~/.claude/commands/parallel-plan/execute/SKILL.md` | 251 |
| `parallel-plan:make` | `~/.claude/commands/parallel-plan/make/SKILL.md` | 247 |
| `learnings:curate` | `~/.claude/commands/learnings/curate/SKILL.md` | 185 |
| `learnings:distribute` | `~/.claude/commands/learnings/distribute/SKILL.md` | 136 |
| `quantum-tunnel-claudes` | `~/.claude/commands/quantum-tunnel-claudes/SKILL.md` | 120 |
| `ralph:compare` | `~/.claude/commands/ralph/compare/SKILL.md` | 100 |
| `ralph:init` | `~/.claude/commands/ralph/init/SKILL.md` | 84 |
| `set-persona` | `~/.claude/commands/set-persona/SKILL.md` | 82 |

### Example diff

```yaml
 ---
 name: ralph:init
 description: Initialize an iterative research project with spec and progress tracking.
+disable-model-invocation: true
 ---
```

### Verification

After adding the flag to each skill:
1. Start a fresh session (flags only evaluated on session start)
2. Run `/context` — confirm the 9 skills are no longer listed in the skill tool's available skills
3. Invoke each skill with `/skill-name` — confirm it still loads and works
4. Confirm the 13 auto-invocable skills still appear and trigger correctly

### Parallelization

All 9 edits are independent. Can be done in a single pass or by multiple agents editing different files in parallel.

---

## Phase 2: `allowed-tools` on 5 Read-Only Auto-Invocable Skills

**Risk:** Low — enforcement is currently broken ([#18837](https://github.com/anthropics/claude-code/issues/18837)), so these declarations are documentation-only today. When enforcement is fixed, these skills correctly should be restricted to read-only tools.

**Impact:** Signals intent that these skills should never mutate files. Prevents accidental writes if/when enforcement starts working. Documents the expected tool surface for each skill.

### Changes

| Skill | File | `allowed-tools` Value |
|:------|:-----|:----------------------|
| `do-security-audit` | `~/.claude/commands/do-security-audit/SKILL.md` | `Read, Grep, Glob, Task` |
| `git:explore-pr` | `~/.claude/commands/git/explore-pr/SKILL.md` | `Read, Bash(gh:*), Bash(git:*), AskUserQuestion` |
| `git:split-pr` | `~/.claude/commands/git/split-pr/SKILL.md` | `Read, Bash(gh:*), Bash(git:*), AskUserQuestion` |
| `ralph:compare` | `~/.claude/commands/ralph/compare/SKILL.md` | `Read, Glob, AskUserQuestion` |
| `set-persona` | `~/.claude/commands/set-persona/SKILL.md` | `Read, Glob` |

**Note:** `ralph:compare` and `set-persona` also get `disable-model-invocation: true` from Phase 1. Both frontmatter fields are added together.

### Example diff

```yaml
 ---
 name: do-security-audit
 description: Run a security audit on one or more projects using parallel agents.
+allowed-tools: Read, Grep, Glob, Task
 ---
```

### Verification

1. Invoke each skill and confirm normal operation (enforcement is broken, so no change expected)
2. Run a security audit — confirm it can still launch Task subagents
3. Run git:explore-pr — confirm Bash(gh) and Bash(git) commands still work

### Parallelization

All 5 edits are independent. Can be done in parallel with Phase 1 since they target different (or overlapping-but-additive) frontmatter fields.

**Phases 1 and 2 can be executed simultaneously** — they touch the same files for `ralph:compare` and `set-persona`, but the edits are additive (both add frontmatter fields in the same block).

---

## Phase 3 (Optional): `context: fork` + `agent: Explore` on `ralph:compare`

**Risk:** Low — `ralph:compare` is manual-only (already has `disable-model-invocation: true` from Phase 1), rarely used, and fully self-contained.

**Impact:** Saves main context from verbose file comparison output. Uses haiku via `agent: Explore` for faster comparison. Experimental — validates `context: fork` pattern for potential future use.

**Prerequisite:** Phase 1 complete (the skill needs `disable-model-invocation: true` first).

### Change

```yaml
 ---
 name: ralph:compare
 description: Compare duplicate research directories to determine which is superseded.
 disable-model-invocation: true
 allowed-tools: Read, Glob, AskUserQuestion
+context: fork
+agent: Explore
 ---
```

### Verification

1. Invoke `/ralph:compare dir1 dir2` — confirm it runs in a subagent (output returns as a single message)
2. Verify the subagent can still read files and compare directories
3. Verify `AskUserQuestion` works from the forked context (it should, in foreground mode)
4. Check that the main conversation context is NOT polluted with the comparison details

### Decision point

**User should decide if this is worth doing.** The value is marginal for a rarely-used skill. The experiment's value is primarily learning whether `context: fork` works smoothly in practice for future skills.

---

## Deferred (No Action Recommended)

These items were researched and found to have insufficient benefit to justify the effort or risk.

### `commands/` → `skills/` Migration

**Why deferred:** All features work identically in `commands/`. Migration is cosmetic — no functional benefit for personal global skills. The sync tool (`quantum-tunnel-claudes`), settings.json permissions, and ~15 files with path references would all need updating. See [commands-to-skills-migration.md](./commands-to-skills-migration.md).

**Revisit when:** Anthropic announces `commands/` deprecation, or distribution as a plugin becomes a goal.

### `{baseDir}` Path Portability

**Why deferred:** `{baseDir}` resolves to the skill's own directory (e.g., `~/.claude/commands/ralph/init/`), NOT `~/.claude/`. Most cross-directory references (to `learnings/`, `skill-references/`, etc.) cannot use `{baseDir}`. Only useful for skill-relative scripts — and only 2 skills have scripts.

### Dynamic Context Injection (`` !`command` ``)

**Why deferred:** Only `explore-repo` currently uses it. Git skills execute git/gh commands procedurally, which works fine. The preprocessing syntax adds complexity without clear UX improvement for existing skills.

### Model Selection Strategy (`model:` overrides)

**Why deferred:** No benchmarking data available. The user's session model choice already reflects their preference. Hardcoded model overrides would be a maintenance burden and could produce worse results than the user's chosen model.

### Size Reduction for Large Skills (>300 lines)

**Why deferred:** 6 skills exceed the recommended 500-line guideline. While extraction to reference files is conceptually beneficial, the effort is significant and the existing skills work. This is a quality-of-life improvement, not a functional gap.

**Revisit when:** Context budget approaches the 16k limit, or skills are being actively modified for other reasons.

---

## Execution Summary

| Phase | Skills Modified | Risk | Effort | Parallelizable |
|:------|:----------------|:-----|:-------|:---------------|
| 1 | 9 (frontmatter addition) | Minimal | ~15 min | Yes — all independent |
| 2 | 5 (frontmatter addition) | Low | ~10 min | Yes — independent, can run with Phase 1 |
| 3 | 1 (frontmatter addition) | Low | ~5 min + testing | No — depends on Phase 1 |

**Total effort:** ~30 min active + verification. Phases 1 and 2 can run in parallel.

**Files modified:** 14 unique SKILL.md files (9 in Phase 1, 5 in Phase 2, with 2 overlapping: `ralph:compare` and `set-persona`).

---

## Questions for User Review

Before executing, these decisions need user input:

1. **Q1: Proceed with Phases 1 and 2 together?** They're independent and low-risk. Recommend executing both. Phase 3 is optional.

2. **Q2: Accept the 9 skills classified as manual-only?** The list is in Phase 1. Any disagreements? Particularly: should `parallel-plan:make` and `parallel-plan:execute` remain auto-invocable? Their descriptions include trigger phrases, but the system prompt already handles routing.

3. **Q3: Accept the 5 read-only skill classifications?** The list is in Phase 2. Any skills that should be added or removed? Note: `allowed-tools` is currently unenforced — this is documentation/future-proofing only.

4. **Q4: Try `context: fork` on `ralph:compare`?** Low risk, low reward. Worth it for learning, but skip if you'd rather not experiment.

5. **Q5: Are any of the 22 skills candidates for removal?** Removing unused skills is simpler than adding `disable-model-invocation`. No usage data exists — this requires your judgment.

6. **Q6: Any interest in the deferred items?** If any deferred item is higher priority than estimated, we can re-sequence.
