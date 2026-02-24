# Deep Research: Hooks Integration with Skills

## Executive Summary

This document evaluates all 22 skills against Claude Code's hooks system to identify which skills would benefit from skill-scoped `hooks:` frontmatter. The analysis covers three hook placement strategies (skill frontmatter, settings files, and agent definitions), evaluates each skill against a practical value framework, and provides concrete implementation recommendations.

**Key finding**: Skill-scoped hooks are best suited for **deterministic validation** tied to a specific skill's workflow — not general-purpose quality checks. Most valuable hooks are PostToolUse validators that catch silent failures (bad merges, broken formatting, failed template substitution). The highest-value candidates are skills that modify files based on external input (PR reviews, merge operations, learning capture).

**Recommendation**: Start with 2-3 high-confidence hooks as proof-of-concept, measure friction vs. value, then expand. Do not add hooks speculatively.

---

## 1. Hooks System Reference (Condensed)

### What Hooks Are

Hooks are shell commands, LLM prompts, or subagent invocations that execute automatically at lifecycle points. Three types:
- **`command`** — Shell script. Receives JSON on stdin, returns exit code + optional JSON on stdout.
- **`prompt`** — Single LLM call (Haiku default). Returns `{ok: true/false, reason: "..."}`.
- **`agent`** — Multi-turn subagent with tool access. Same response format as prompt. 60s default timeout.

### Where Hooks Can Live

| Location | Scope | Best For |
|----------|-------|----------|
| `~/.claude/settings.json` | All projects | Universal checks (notification, logging) |
| `.claude/settings.json` | Per project | Project-specific validation (lint, format) |
| Skill `hooks:` frontmatter | While skill is active | Skill-specific validation |
| Agent `hooks:` frontmatter | While agent is active | Agent-scoped checks |
| Plugin `hooks/hooks.json` | While plugin enabled | Distributable validation |

### Events Relevant to Skills

| Event | Fires When | Can Block? | Matcher |
|-------|-----------|------------|---------|
| **PreToolUse** | Before tool executes | Yes (deny/allow/ask) | Tool name (`Bash`, `Edit\|Write`, etc.) |
| **PostToolUse** | After tool succeeds | No (stderr → Claude) | Tool name |
| **PostToolUseFailure** | After tool fails | No | Tool name |
| **Stop** | Claude finishes responding | Yes (continue conversation) | None |
| **SubagentStop** | Subagent finishes | Yes (prevent stopping) | Agent type |

### Skill-Scoped Hooks Syntax

```yaml
---
name: my-skill
description: Does something
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/lint-check.sh"
  Stop:
    - hooks:
        - type: prompt
          prompt: "Verify all tasks are complete. $ARGUMENTS"
---
```

**Key behaviors:**
- Skill-scoped hooks are active only while the skill is running
- `Stop` hooks in skill frontmatter auto-convert to `SubagentStop` (for fork context)
- `once: true` field runs hook only once per session (skills only, not agents)
- All matching hooks run in parallel; identical commands deduplicated
- Hook timeout: 600s (command), 30s (prompt), 60s (agent)

### Hook Script Mechanics

```bash
#!/bin/bash
# Receives JSON on stdin with tool_name, tool_input, session_id, cwd, etc.
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Exit 0 = allow, Exit 2 = block (stderr → Claude), Other = log only
if [[ "$FILE_PATH" == *".env"* ]]; then
  echo "Blocked: cannot modify .env files" >&2
  exit 2
fi
exit 0
```

For structured control, exit 0 with JSON on stdout:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Reason shown to Claude"
  }
}
```

---

## 2. Evaluation Framework

### When Skill-Scoped Hooks Add Value

A hook is worth adding when ALL of these are true:

1. **Deterministic** — The check has a clear pass/fail criterion, not a judgment call
2. **Skill-specific** — The check only makes sense during this skill's execution, not globally
3. **Silent failure risk** — Without the hook, the failure would go unnoticed
4. **Low friction** — The hook doesn't slow down the skill significantly (<5s per invocation)
5. **Not already handled** — The skill doesn't already perform this check in its instructions

### When NOT to Use Skill-Scoped Hooks

- **General-purpose formatting/linting** — Put in project settings, not skill frontmatter. Formatting applies to ALL file edits, not just those from one skill.
- **Permission enforcement** — Use settings-level hooks or permission rules. Skill frontmatter is the wrong scope.
- **Judgment calls** — Prompt/agent hooks are expensive (LLM calls). Only use when the judgment is well-scoped and the cost of a miss is high.
- **Already in skill instructions** — If the SKILL.md already tells Claude to "verify tests pass" or "check formatting," a hook duplicates the effort. Hooks add value when Claude might *forget* or *skip* the check, not when it's already instructed.

### Hook Type Selection

| Hook Type | Cost | Latency | Best For |
|-----------|------|---------|----------|
| `command` | Zero (shell) | <1s | Deterministic checks: file existence, JSON parsing, regex validation |
| `prompt` | ~1K tokens | ~2-5s | Simple judgment: "Is this PR title clear?" |
| `agent` | ~5-50K tokens | ~10-60s | Complex verification: "Do all tests pass?" |

**Default to `command` hooks.** Only escalate to `prompt`/`agent` when shell logic can't express the check.

---

## 3. Skill-by-Skill Evaluation

### Evaluation Key

- **Verdict**: YES (clear value), MAYBE (value exists but low priority), NO (not worth it)
- **Hook placement**: `skill` (frontmatter), `settings` (project/user settings), `N/A`

### Git Skills (9)

#### git/create-pr

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | No — uses git/gh commands only |
| **Silent failure risk?** | Medium — PR could be created with missing labels, bad title |
| **Candidate hooks** | PostToolUse(Bash → `gh pr create`) to verify PR URL returned |
| **Verdict** | **MAYBE** — The skill already has a pre-PR checklist. The main risk (bad PR metadata) is better caught by a project-level CI check or GitHub Actions, not a hook. |
| **Hook placement** | `settings` (if anything) — PR validation isn't skill-specific |

#### git/address-pr-review

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | Yes — modifies code based on reviewer comments |
| **Silent failure risk?** | High — code change could mismatch reviewer intent, lint/format could break |
| **Candidate hooks** | PostToolUse(`Edit`) → run project linter/formatter on modified file |
| **Verdict** | **MAYBE** — Valuable, but this is a general "format after edit" pattern that belongs in project settings, not skill frontmatter. The skill-specific check (does the edit match the comment intent?) requires a prompt hook, which adds latency per edit. |
| **Hook placement** | `settings` for format/lint; `skill` only if prompt-based intent verification is deemed worth the cost |

#### git/resolve-conflicts

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | Yes — resolves merge conflicts |
| **Silent failure risk?** | High — residual conflict markers (`<<<<<<<`) in committed code |
| **Candidate hooks** | PostToolUse(`Edit`) → grep for conflict markers in edited files |
| **Verdict** | **YES** — Simple, deterministic, high-value. A shell hook that greps for `<<<<<<<` in the file after edit catches the most common silent failure in merge resolution. |
| **Hook placement** | `skill` — only relevant during conflict resolution |

**Proposed hook:**
```yaml
hooks:
  PostToolUse:
    - matcher: "Edit"
      hooks:
        - type: command
          command: "jq -r '.tool_input.file_path' | xargs grep -l '<<<<<<<' 2>/dev/null && echo 'WARNING: Residual conflict markers detected' >&2 || true"
```

#### git/cascade-rebase

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | No (rebases, doesn't directly edit files) |
| **Silent failure risk?** | Medium — rebase could silently fail or no-op |
| **Candidate hooks** | None that are skill-specific |
| **Verdict** | **NO** — Rebase failures are loud (non-zero exit). The skill's risk is operational (wrong branch order), not something hooks can catch. |

#### git/explore-pr, git/split-pr, git/prune-merged, git/repoint-branch, git/monitor-pr-comments

| Skill | Verdict | Reason |
|-------|---------|--------|
| explore-pr | **NO** | Read-only; no silent failures |
| split-pr | **NO** | Analysis-only; no file modifications |
| prune-merged | **NO** | Branch deletion is explicit; failures are loud |
| repoint-branch | **NO** | Git cherry-pick failures are loud |
| monitor-pr-comments | **NO** | Background polling; hook timing doesn't align with async workflow |

### Learnings Skills (4)

#### learnings/compound

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | Yes — writes to ~/.claude/learnings/, guidelines/, commands/ |
| **Silent failure risk?** | Medium — could write duplicate content, corrupt existing file formatting |
| **Candidate hooks** | PostToolUse(`Edit`) → verify edited file is still valid markdown (no broken headers, no orphaned list items) |
| **Verdict** | **MAYBE** — The risk is real (appending learnings could break formatting), but the check is hard to express as a deterministic shell command. Markdown "validity" is subjective. |
| **Hook placement** | `skill` if implemented — only relevant during learning capture |

#### learnings/consolidate

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | Yes — reorganizes, merges, deletes learning files |
| **Silent failure risk?** | High — could lose content during reorganization |
| **Candidate hooks** | PreToolUse(`Edit`) → backup file before edit; PostToolUse(`Edit`) → verify file size didn't decrease dramatically (content loss indicator) |
| **Verdict** | **MAYBE** — Content loss is a real risk, but the "dramatic size decrease" heuristic has false positives (legitimate consolidation reduces file size). A backup-before-edit hook is more robust but adds operational complexity. |
| **Hook placement** | `skill` — only relevant during consolidation sweeps |

#### learnings/curate, learnings/distribute

| Skill | Verdict | Reason |
|-------|---------|--------|
| curate | **NO** | Similar to consolidate but lower volume; risk doesn't justify hook complexity |
| distribute | **NO** | Simple file copy/merge; failures are visible |

### Parallel-Plan Skills (2)

#### parallel-plan/execute

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | Yes — via subagents |
| **Silent failure risk?** | High — subagent could silently produce bad output, contract violations |
| **Candidate hooks** | SubagentStop → verify each agent's output against expected format |
| **Verdict** | **MAYBE** — The skill already has extensive verification (scorecard, build check, integration tests). Adding hooks would duplicate effort. The main gap is *real-time* subagent output validation, but SubagentStop hooks can't inspect the subagent's actual file changes — they only get the return message. |
| **Hook placement** | N/A — existing instruction-based validation is sufficient |

#### parallel-plan/make

| Verdict | **NO** | Analysis-only; produces a plan file, doesn't execute. |

### Research Skills (2)

#### ralph/init

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | Yes — creates spec.md and progress.md from templates |
| **Silent failure risk?** | Low — template substitution is straightforward, and the user sees the output immediately |
| **Verdict** | **NO** — Template creation is simple; failures are immediately visible. |

#### ralph/compare

| Verdict | **NO** | Read-only comparison; no modifications. |

### Standalone Skills (5)

#### do-refactor-code

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | Yes — refactors code |
| **Silent failure risk?** | Medium — could break behavior while preserving syntax |
| **Candidate hooks** | PostToolUse(`Edit`) → run project-specific linter/formatter |
| **Verdict** | **MAYBE** — The skill already instructs Claude to run tests after each refactoring. A hook could enforce this, but it duplicates the instruction. The value is in *guaranteeing* the check happens (hooks are deterministic, instructions are probabilistic). However, the skill's format/lint check is project-specific and can't be encoded in a universal hook script. |
| **Hook placement** | `settings` — format/lint is project-level, not skill-specific |

#### do-security-audit

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | No — produces reports |
| **Silent failure risk?** | Low — subagent outputs are synthesized into visible report |
| **Verdict** | **NO** — Read-only analysis; hook doesn't add value. |

#### explore-repo

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | Yes — creates/updates docs/learnings/*.md, updates CLAUDE.md |
| **Silent failure risk?** | Medium — scan metadata could be malformed, CLAUDE.md sections could be accidentally deleted |
| **Candidate hooks** | PostToolUse(`Edit` → CLAUDE.md) → verify key sections still present |
| **Verdict** | **MAYBE** — CLAUDE.md is the highest-value file in the repo. Accidentally deleting a section during explore-repo is a real risk. But the check ("are all expected sections present?") is project-specific and hard to generalize. |
| **Hook placement** | `settings` — CLAUDE.md protection applies to all skills, not just explore-repo |

#### quantum-tunnel-claudes

| Aspect | Assessment |
|--------|-----------|
| **Modifies files?** | Yes — merges content from sync source |
| **Silent failure risk?** | High — content-aware merge could silently drop sections |
| **Candidate hooks** | PostToolUse(`Edit`) → verify file section count didn't decrease |
| **Verdict** | **YES** — Merge operations are the highest-risk category for silent content loss. A hook that counts markdown headers (##) before and after edit can catch dropped sections. |
| **Hook placement** | `skill` — only relevant during sync/merge operations |

**Proposed hook:**
```yaml
hooks:
  PostToolUse:
    - matcher: "Edit"
      hooks:
        - type: command
          command: "jq -r '.tool_input.file_path' | xargs -I{} sh -c 'grep -c \"^##\" \"{}\" 2>/dev/null || echo 0'"
          statusMessage: "Verifying merge integrity"
```

*Note: This is a lightweight indicator, not a blocker. It outputs section counts for Claude to see (via PostToolUse stdout shown in verbose mode). A more sophisticated version would compare pre/post counts, but that requires state between pre/post hooks that the current hook system doesn't provide.*

#### set-persona

| Verdict | **NO** | Read-only; loads persona files into context. |

---

## 4. Consolidated Recommendations

### Tier 1: High-Confidence Skill-Scoped Hooks (Implement)

| Skill | Hook | Type | What It Does |
|-------|------|------|-------------|
| `git/resolve-conflicts` | PostToolUse(`Edit`) | `command` | Greps for residual conflict markers (`<<<<<<<`) in edited files |
| `quantum-tunnel-claudes` | PostToolUse(`Edit`) | `command` | Section count check — detects if merge accidentally dropped content |

**Why these two:**
- Both have **high silent failure risk** with **deterministic** checks
- Both are **skill-specific** (not general-purpose)
- Both are **simple shell commands** (<1s, zero token cost)
- Both catch failures that the skill instructions alone can't guarantee

### Tier 2: Settings-Level Hooks (Not Skill-Scoped)

These are valuable checks, but they belong in project/user settings, not skill frontmatter:

| Hook | Scope | What It Does |
|------|-------|-------------|
| PostToolUse(`Edit\|Write`) → run formatter | Project settings | Auto-format after any file edit |
| PreToolUse(`Edit\|Write`) → protect `.env`/secrets | User settings | Block edits to sensitive files |
| PostToolUse(`Edit` → CLAUDE.md) → section check | Project settings | Verify CLAUDE.md sections after any edit |
| Stop → prompt "Are all tasks complete?" | User settings | Catch incomplete work before Claude stops |

**Why settings-level:** These apply to ALL skills, not specific ones. Putting them in skill frontmatter means maintaining 22 copies.

### Tier 3: Defer (Research-Only Value)

| Skill | Hook Idea | Why Defer |
|-------|-----------|-----------|
| learnings/compound | PostToolUse(`Edit`) → markdown validity | Markdown "validity" is subjective; hard to express as deterministic check |
| learnings/consolidate | PreToolUse(`Edit`) → backup before edit | Adds operational complexity (backup management); content loss risk is real but infrequent |
| parallel-plan/execute | SubagentStop → verify output format | Skill already has extensive verification in instructions; hooks would duplicate |
| do-refactor-code | PostToolUse(`Edit`) → run tests | Project-specific; belongs in settings, not skill frontmatter |
| git/address-pr-review | PostToolUse(`Edit`) → format check | General format/lint; belongs in settings |
| explore-repo | PostToolUse(`Edit` → docs) → metadata check | Metadata format is custom; hard to validate generically |

---

## 5. Implementation Considerations

### Hook Script Location

Skill-scoped hook commands reference scripts relative to the skill directory or `$CLAUDE_PROJECT_DIR`. For personal skills in `~/.claude/commands/`:

```yaml
# Inline command (simple checks)
hooks:
  PostToolUse:
    - matcher: "Edit"
      hooks:
        - type: command
          command: "jq -r '.tool_input.file_path' | xargs grep -l '<<<<<<<' && exit 2 || exit 0"

# External script (complex checks)
hooks:
  PostToolUse:
    - matcher: "Edit"
      hooks:
        - type: command
          command: "~/.claude/commands/git/resolve-conflicts/scripts/check-markers.sh"
```

**Recommendation**: Inline simple checks (single-line grep/jq). Use external scripts only when logic requires multiple steps or state.

### Dependency: `jq`

Most hook examples depend on `jq` for JSON parsing. This is a reasonable dependency:
- Pre-installed on most dev machines
- Available via `brew install jq` (macOS), `apt install jq` (Linux)
- Lightweight, no runtime dependencies

**Alternative**: Use Python for complex JSON parsing, but `jq` is preferred for single-field extraction.

### Hook Debugging

- Toggle verbose mode (`Ctrl+O`) to see hook output in the transcript
- `claude --debug` shows which hooks matched and their exit codes
- Test hooks manually: `echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.txt"}}' | ./my-hook.sh`

### PostToolUse Limitation

**Critical constraint**: PostToolUse hooks **cannot undo actions** — the tool has already executed. They can only:
1. Write to stderr (which becomes Claude's feedback)
2. Write to stdout (visible in verbose mode)
3. Return JSON with `decision: "block"` (but the edit already happened — this just signals Claude)

For PostToolUse hooks, the value is **feedback**, not prevention. Claude receives the stderr message and can take corrective action (e.g., undo the edit, re-run with fixes).

### Stop Hook Infinite Loop Risk

Stop hooks that block Claude from stopping (exit 2 or `decision: "block"`) can create infinite loops. Always check `stop_hook_active`:

```bash
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Allow stop on re-check
fi
# ... actual check logic
```

### Prompt/Agent Hook Cost

- Prompt hooks cost ~1K tokens per invocation (Haiku by default)
- Agent hooks cost ~5-50K tokens per invocation (with tool use)
- Both add latency (2-5s for prompt, 10-60s for agent)
- Use sparingly — only for checks that can't be expressed as shell commands

---

## 6. Hooks vs. Skill Instructions: When to Use Which

| Dimension | Skill Instructions | Hooks |
|-----------|-------------------|-------|
| **Guarantee** | Probabilistic — Claude may skip | Deterministic — always runs |
| **Flexibility** | Can adapt to context | Fixed logic per invocation |
| **Cost** | Zero | Shell = zero; prompt = ~1K tokens; agent = ~5-50K tokens |
| **Maintenance** | In SKILL.md (easy to update) | Separate scripts or inline commands |
| **Debugging** | Visible in conversation | Requires verbose mode or --debug |
| **Scope** | Runs within Claude's reasoning | Runs outside Claude's context |

**Rule of thumb**: Use instructions for flexible, context-dependent checks. Use hooks for invariants that must always hold regardless of context.

**Examples:**
- "Run tests after refactoring" → **Instruction** (which tests to run depends on the project)
- "No conflict markers in committed files" → **Hook** (invariant, deterministic, context-independent)
- "Format code after editing" → **Settings-level hook** (applies to all edits, not skill-specific)
- "Verify merge didn't drop sections" → **Skill-scoped hook** (only relevant during merge operations)

---

## 7. What Doesn't Exist Yet (Gaps in the Hooks System)

### No Pre/Post State Comparison

The hooks system doesn't provide a way to compare file state before and after a tool execution within a single hook invocation. PreToolUse and PostToolUse fire independently — there's no shared state between them.

**Workaround**: PreToolUse hook writes file state to a temp file; PostToolUse hook reads it and compares. But this is fragile (cleanup, race conditions in parallel hooks).

### No Skill-Level `once: true` for PostToolUse

The `once: true` field only works for skills, but it fires the hook only once per session. There's no "once per invocation" — if a skill runs multiple Edit calls, the hook fires for each one.

### No Hook Chaining

Hooks can't invoke other hooks or chain decisions. Each hook is independent. If you need "run lint, then run tests, then check coverage," that must be a single script, not three chained hooks.

### No File Content in PostToolUse Input

PostToolUse receives `tool_input` (what was requested) and `tool_result` (what happened), but `tool_result` for Edit/Write doesn't include the final file content. The hook must re-read the file to inspect it.

---

## Sources

- [Claude Code Hooks reference](https://code.claude.com/docs/en/hooks) — Full event schemas, JSON I/O, configuration
- [Claude Code Hooks guide](https://code.claude.com/docs/en/hooks-guide) — Practical examples and patterns
- [Claude Code Skills docs](https://code.claude.com/docs/en/skills) — Hooks in skill frontmatter
- [Bash command validator example](https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py) — Reference implementation
- Repo analysis: All 22 SKILL.md files in `~/.claude/commands/`
