# Deep Research: `allowed-tools` Scoping Strategy

Analysis of whether and how to add `allowed-tools` frontmatter to the 22 skills in this repo.

---

## 1. How `allowed-tools` Works (and Doesn't)

### Intended Behavior

From the [official docs](https://code.claude.com/docs/en/skills):

> "Tools Claude can use without asking permission when this skill is active."
> "Use the `allowed-tools` field to limit which tools Claude can use when a skill is active."

Two purposes:
1. **Grant auto-approval** — listed tools skip per-use permission prompts during the skill
2. **Restrict access** — Claude should only use listed tools, not others

### Current Reality: Enforcement Is Broken

| Aspect | Intended | Actual (Feb 2026) |
|:---|:---|:---|
| Restriction (only use listed tools) | Enforced | **Not enforced** — Claude freely uses unlisted tools ([#18837](https://github.com/anthropics/claude-code/issues/18837)) |
| Bash auto-approval | Listed Bash patterns auto-approved | **Broken** — Bash still prompts for approval ([#14956](https://github.com/anthropics/claude-code/issues/14956)) |
| Non-Bash auto-approval | Listed tools auto-approved | Partially works (via `alwaysAllowRules` injection) |
| Agent SDK support | Same as CLI | **Silently ignored** in SDK ([#18737](https://github.com/anthropics/claude-code/issues/18737)) |

The [Agent Skills spec](https://agentskills.io/specification) marks the field as **Experimental**.

### Syntax

Three valid forms (all work in Claude Code):

```yaml
# Comma-delimited (docs style)
allowed-tools: Read, Grep, Glob

# YAML list (Trail of Bits style)
allowed-tools:
  - Bash
  - Read
  - Glob

# Scoped Bash patterns
allowed-tools: Bash(gh:*), Bash(git:*), Read
```

Tool patterns: `ToolName` (full access), `Bash(prefix:*)` (scoped Bash), `Bash({baseDir}/script.sh:*)` (skill-relative script), `mcp__server__tool` (MCP tools).

---

## 2. Ecosystem Adoption

| Collection | Uses `allowed-tools`? | Pattern |
|:---|:---|:---|
| [anthropics/skills](https://github.com/anthropics/skills) (16 skills) | **No** — 0/16 skills use it | Only `name`, `description`, `license` |
| [anthropics/claude-code plugins](https://github.com/anthropics/claude-code) | **No** — 0/3 dev skills use it | Only `name`, `description`, `version` |
| [trailofbits/skills](https://github.com/trailofbits/skills) | **Yes** — ~8+ skills | Principle of least privilege; YAML list form; scoped `Bash({baseDir}/script:*)` |
| [obra/superpowers](https://github.com/obra/superpowers-chrome) | **Yes** — MCP scoping | `allowed-tools: mcp__chrome__use_browser` |
| [anthropics/claude-agent-sdk-demos](https://github.com/anthropics/claude-agent-sdk-demos) | **Yes** — 1 skill | `allowed-tools: Write, Edit, Read, Glob` |
| **This repo** (22 skills) | **No** — 0/22 | Only `description` frontmatter used |

**Key insight:** Anthropic's own public skills don't use it. Trail of Bits uses it most, driven by their security focus. The feature is too experimental for widespread adoption.

---

## 3. Tool Usage Map: Our 22 Skills

Detailed analysis of which tools each skill actually requires.

### Read-Only Skills (best `allowed-tools` candidates)

| Skill | Tools Used | Proposed `allowed-tools` |
|:---|:---|:---|
| `git:explore-pr` | Bash(gh, git), Read, AskUserQuestion | `Read, Bash(gh:*), Bash(git:*), AskUserQuestion` |
| `git:split-pr` | Bash(gh, git), Read, AskUserQuestion | `Read, Bash(gh:*), Bash(git:*), AskUserQuestion` |
| `do-security-audit` | Task, Read, Grep, Glob | `Read, Grep, Glob, Task` |
| `ralph:compare` | Read, Glob, AskUserQuestion | `Read, Glob, AskUserQuestion` |
| `set-persona` | Read, Glob | `Read, Glob` |

### Read-Heavy Skills (some mutations)

| Skill | Tools Used | Notes |
|:---|:---|:---|
| `git:prune-merged` | Bash(git), AskUserQuestion | Only mutates via `git branch -d` |
| `do-refactor-code` | Read, Edit, Bash(tests/lint), AskUserQuestion | Edits files + runs tests |
| `explore-repo` | Task, Read, Glob, Grep, Write, Edit, Bash(git, mkdir) | Nearly everything — subagents write output files, edits CLAUDE.md |

### Full-Access Skills (broad tool needs)

| Skill | Key Tools | Why Broad |
|:---|:---|:---|
| `git:create-pr` | Bash(git, gh), Read, AskUserQuestion | Pushes, creates PRs |
| `git:address-pr-review` | Bash(git, gh api), Read, Edit, AskUserQuestion | Reads, edits code, pushes, replies to comments |
| `git:resolve-conflicts` | Bash(git, gh), Read, Edit, AskUserQuestion | Reads conflicted files, resolves, commits |
| `git:repoint-branch` | Bash(git, gh, mkdir), Read, AskUserQuestion | Creates branches, copies files, pushes |
| `git:cascade-rebase` | Bash(git), Read, AskUserQuestion | Rebases chain, force-pushes |
| `git:monitor-pr-comments` | Bash(gh, scripts), Read, Task, TaskStop | Background polling + comment processing |
| `learnings:compound` | Read, Write, Edit, AskUserQuestion, Glob | Reads corpus, writes to multiple locations |
| `learnings:consolidate` | Read, Write, Edit, AskUserQuestion, Glob, Grep, Task | Full corpus sweep + subagents |
| `learnings:curate` | Read, Write, Edit, AskUserQuestion, Glob, Grep, Task | Same as consolidate |
| `learnings:distribute` | Read, Write, Edit, Glob, Bash(git), AskUserQuestion | Cross-directory file sync |
| `parallel-plan:make` | Read, Write, Glob, Grep, Bash, AskUserQuestion | Analyzes codebase, writes plan |
| `parallel-plan:execute` | Read, Write, Edit, Task, TaskOutput, Bash, AskUserQuestion | Full orchestration |
| `ralph:init` | Read, Write, Bash(mkdir), AskUserQuestion | Creates project directory |
| `quantum-tunnel-claudes` | Read, Write, Edit, Bash(git, script), Grep, Glob, AskUserQuestion | Cross-repo sync |

---

## 4. Security/UX Tradeoff Analysis

### Security Benefit

| Scenario | Risk Without Scoping | Benefit of Scoping |
|:---|:---|:---|
| Auto-invoked read-only skill (explore-pr, split-pr) | Claude could Write/Edit when it shouldn't | Prevents accidental file mutations during analysis |
| Auto-invoked mutation skill (address-pr-review) | Claude might use tools beyond scope | Minimal — skill legitimately needs broad access |
| Manual-only skill (ralph:init, consolidate) | User explicitly invoked — they trust the skill | None — user already opted in |
| `context: fork` skill | Subagent inherits session tools | Could restrict subagent's tool access |

### UX Risk

| Risk | Description | Severity |
|:---|:---|:---|
| Silent breakage when enforcement is fixed | If we add strict `allowed-tools` now and enforcement starts working, skills that occasionally need an unlisted tool will fail silently | **High** |
| Maintenance burden | Every skill change must update the tool list; forgetting a tool causes failures | **Medium** |
| False security | Users might trust scoping that isn't enforced | **Medium** |
| Debugging difficulty | When a skill fails, "is the tool list too restrictive?" becomes a debugging dimension | **Medium** |

---

## 5. Recommendation

### Priority Order

1. **`disable-model-invocation: true`** (higher impact, no risk) — prevents accidental invocation of heavyweight skills. Already researched in [disable-model-invocation.md](./disable-model-invocation.md). Do this first for the 9 identified manual-only skills.

2. **`allowed-tools` on 3–5 read-only auto-invocable skills** (low risk, documentation value) — these skills should never mutate files:

   | Skill | Proposed `allowed-tools` | Rationale |
   |:---|:---|:---|
   | `do-security-audit` | `Read, Grep, Glob, Task` | Audit must be read-only; mutations would be a security anti-pattern |
   | `git:explore-pr` | `Read, Bash(gh:*), Bash(git:*), AskUserQuestion` | Exploration skill; writes are never appropriate |
   | `git:split-pr` | `Read, Bash(gh:*), Bash(git:*), AskUserQuestion` | Analysis-only; no file mutations expected |
   | `ralph:compare` | `Read, Glob, AskUserQuestion` | Pure comparison; never writes |
   | `set-persona` | `Read, Glob` | Reads persona files; no mutations |

3. **Wait for enforcement to be fixed** before adding `allowed-tools` to mutation-capable skills. When enforcement works:
   - Scoped Bash patterns (e.g., `Bash(gh:*)`, `Bash(git:*)`) become the highest-value pattern
   - Skills that delegate to subagents need `Task` in the list
   - Skills using `@` references need `Read` (implicit today, but explicit in a restricted world)

4. **Do NOT add `allowed-tools` to broad-access skills** (explore-repo, learnings:*, parallel-plan:*, quantum-tunnel-claudes, git:address-pr-review, git:resolve-conflicts) — the tool list would be nearly everything, providing no restriction value and high maintenance cost.

### Implementation Notes

- Use **comma-delimited inline format** (matches the official docs style, more compact than YAML list):
  ```yaml
  allowed-tools: Read, Grep, Glob, Task
  ```
- Include `AskUserQuestion` for any skill that has interactive decision points
- Include `Task` for skills that launch subagents
- For Bash-using skills, prefer scoped patterns (`Bash(gh:*)`) over bare `Bash`
- `{baseDir}` is only useful for skill-relative scripts — our 2 scripts (in quantum-tunnel-claudes and git:monitor-pr-comments) are the only candidates

### What This Means for the Implementation Plan

- **Phase 1 (safe, do now):** Add `disable-model-invocation: true` to 9 manual-only skills
- **Phase 2 (low risk):** Add `allowed-tools` to the 5 read-only skills above
- **Phase 3 (wait for enforcement fix):** Expand `allowed-tools` to mutation-capable skills
- **No phase needed:** Full-access skills — `allowed-tools` adds no value

---

## 6. Assumptions Updated

| Assumption | Old | New |
|:---|:---|:---|
| A6: `allowed-tools` improves security without hurting UX | Medium confidence | **Partially validated**: improves security *intent signaling* for read-only skills, but enforcement is broken. For broad-access skills, UX risk > security benefit. |

---

## Sources

- [Extend Claude with skills — Official Docs](https://code.claude.com/docs/en/skills)
- [Agent Skills Specification](https://agentskills.io/specification)
- [Claude Agent Skills: A First Principles Deep Dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
- [GitHub Issue #18837: allowed-tools not enforced](https://github.com/anthropics/claude-code/issues/18837)
- [GitHub Issue #14956: Bash auto-approval broken](https://github.com/anthropics/claude-code/issues/14956)
- [GitHub Issue #18737: CLI vs SDK inconsistency](https://github.com/anthropics/claude-code/issues/18737)
- [Trail of Bits skills repo](https://github.com/trailofbits/skills)
- [obra/superpowers-chrome](https://github.com/obra/superpowers-chrome)
