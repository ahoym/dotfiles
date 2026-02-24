# Deep Research: `allowed-tools` Adoption Strategy

## Executive Summary

This document evaluates all 22 skills for `allowed-tools` adoption — which skills benefit most from tool restrictions, what tool lists to use, and when/how to adopt once enforcement is fixed.

**Key findings:**
- **`allowed-tools` enforcement is broken** — two open issues (#18837 closed as dup of #14956, which remains open). Tool restrictions are not enforced at runtime. Bash auto-approval via `allowed-tools` is also broken.
- **SDK ignores the field entirely** (#18737, closed after doc update). Skills using `allowed-tools` lose restrictions when consumed via the Agent SDK.
- **Trail of Bits is the primary real-world adopter** — their security-focused plugin collection uses `allowed-tools` on 4+ skills with YAML list syntax (not spec's space-delimited format).
- **Anthropic's own 16 reference skills don't use it.**
- **13 of our 22 skills would benefit from tool restrictions** — primarily read-only analysis skills and skills that should only write to specific locations.
- **Recommendation: Add `allowed-tools` now as documentation/intent-signaling.** The field is harmless when unenforced. It communicates design intent, prepares for enforcement landing, and aligns with Trail of Bits' security-first pattern.

---

## 1. Current Status of `allowed-tools`

### Spec Definition

From [Agent Skills Specification](https://agentskills.io/specification):

> `allowed-tools` — A space-delimited list of pre-approved tools the skill may use. (Experimental)

Example: `allowed-tools: Bash(git:*) Bash(jq:*) Read`

### Bug Landscape

| Issue | Status | Summary |
|-------|--------|---------|
| [#18837](https://github.com/anthropics/claude-code/issues/18837) | **Closed** (dup of #14956) | Tool restrictions not enforced — Claude uses Edit/Write despite exclusion |
| [#14956](https://github.com/anthropics/claude-code/issues/14956) | **Open** (9 comments, multi-platform) | Bash commands matching `allowed-tools` patterns still prompt for approval |
| [#18737](https://github.com/anthropics/claude-code/issues/18737) | **Closed** (doc update) | Agent SDK ignores `allowed-tools` entirely — silent security risk |
| [#13494](https://github.com/anthropics/claude-code/issues/13494) | **Closed** (user error) | Syntax confusion — YAML list `["Bash(x:*)"]` doesn't work, must use comma-delimited or space-delimited |
| [#11088](https://github.com/anthropics/claude-code/issues/11088) | Feature request | Proposes `tools` (not `allowed-tools`) for fine-grained permissions |
| [#1271](https://github.com/anthropics/claude-code/issues/1271) | Open | Piped/chained commands bypass `allowed-tools` restrictions |
| [#11366](https://github.com/anthropics/claude-code/issues/11366) | Feature request | `allowed-tools` wildcards don't work with PowerShell (`pwsh`) |

**Bottom line**: Two enforcement bugs remain open (#14956, #1271). No timeline for fixes. The feature works for intent-signaling only.

### Cross-Platform Support

| Platform | `allowed-tools` Support |
|----------|------------------------|
| Claude Code CLI | Parsed, not enforced |
| Claude Code SDK | **Ignored entirely** |
| VS Code / Copilot | Unknown (not in their allowlist) |
| Cursor | Unknown |
| Codex CLI | Unknown |
| Gemini CLI | Unknown |
| Other Agent Skills tools | Unknown |

`allowed-tools` is effectively a Claude Code-only field. Other platforms may parse it (spec-standard) but enforcement is implementation-dependent.

---

## 2. Real-World Adoption Patterns

### Trail of Bits (Primary Adopter)

Trail of Bits' [skills repo](https://github.com/trailofbits/skills) uses `allowed-tools` on multiple security-focused skills:

**`sharp-edges`** (read-only analysis):
```yaml
allowed-tools:
  - Read
  - Grep
  - Glob
```

**`semgrep-rule-creator`** (needs file writes):
```yaml
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - WebFetch
```

**`git-cleanup`** (interactive, destructive):
```yaml
allowed-tools:
  - Bash
  - Read
  - Grep
  - AskUserQuestion
```

**`second-opinion`** (shells out to external LLMs):
```yaml
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
```

**Patterns observed:**
1. **YAML list syntax**, not spec's space-delimited — likely easier to read/maintain
2. **Read-only skills exclude Write/Edit** — clear intent-signaling even without enforcement
3. **Interactive skills include AskUserQuestion** — doesn't forget user interaction tools
4. **No scoped Bash patterns** (`Bash(git:*)`) — just bare `Bash`
5. **Not all skills use it** — `audit-context-building`, `variant-analysis` have description-only frontmatter

### Anthropic Official Skills (Non-Adopter)

All 16 skills in `anthropics/skills` use description-only frontmatter. None use `allowed-tools`. This is consistent with the feature being experimental/broken.

### Community

Most community skills repos don't use `allowed-tools`. The few that do follow Trail of Bits' patterns (YAML list, broad tool categories).

---

## 3. Syntax: Which Format to Use?

The spec says "space-delimited" but multiple formats parse correctly in Claude Code:

| Format | Example | Spec-Compliant | Readable |
|--------|---------|----------------|----------|
| Space-delimited string | `allowed-tools: Read Grep Glob` | Yes | Medium |
| Comma-delimited string | `allowed-tools: Read, Grep, Glob` | Undocumented but works | Better |
| YAML list | `allowed-tools:\n  - Read\n  - Grep` | No (YAML array, not string) | Best |
| Scoped Bash | `allowed-tools: Bash(git:*) Read` | Yes | Medium |

**Recommendation: Use YAML list syntax.** It's the most readable, used by Trail of Bits (the primary real-world adopter), and parses correctly in Claude Code. The spec says "space-delimited" but the validator checks for the field's presence, not format. If/when enforcement lands, YAML list parsing is likely to be maintained (breaking Trail of Bits' skills would be a regression).

**One caveat**: If cross-platform portability matters, use space-delimited string format (spec-compliant). Other Agent Skills implementations may not parse YAML lists correctly. Since we've already established that `allowed-tools` is effectively Claude Code-only (§1), YAML list is fine for our use case.

---

## 4. Per-Skill Evaluation

### Evaluation Framework

For each skill, I evaluate:
1. **Benefit**: How much value does restricting tools provide? (Read-only skills benefit most)
2. **Tool list**: What's the minimum set of tools needed?
3. **Complexity**: How hard is it to define the correct tool list?
4. **Risk when enforced**: Could enforcement break the skill if tool list is wrong?

### Tier 1: High Benefit — Read-Only Analysis Skills

These skills should never write files. `allowed-tools` clearly communicates this.

| Skill | Recommended `allowed-tools` | Rationale |
|-------|----------------------------|-----------|
| `explore-repo` | Read, Glob, Grep, Task, WebFetch | Pure analysis. Spawns subagents via Task but never writes. |
| `do-security-audit` | Read, Glob, Grep, Task, WebFetch | Same pattern — parallel analysis subagents, no writes. |
| `split-pr` | Read, Glob, Grep, Bash(git:*), Bash(gh:*) | Analyzes PR structure, recommends splits. Doesn't execute splits. |
| `explore-pr` | Read, Glob, Grep, Bash(git:*), Bash(gh:*) | Reads PR context. No file modifications. |
| `ralph/compare` | Read, Glob, Grep | Compares two research directories. Pure comparison. |

### Tier 2: Medium Benefit — Narrowly Scoped Write Skills

These skills write to specific locations. `allowed-tools` narrows the blast radius.

| Skill | Recommended `allowed-tools` | Rationale |
|-------|----------------------------|-----------|
| `do-refactor-code` | Read, Glob, Grep, Edit, Write, Bash(python:*), Bash(node:*) | Refactors code — needs Edit/Write but could restrict Bash to test runners |
| `learnings/compound` | Read, Glob, Grep, Edit, Write, AskUserQuestion | Captures learnings to specific directories. No Bash needed. |
| `learnings/curate` | Read, Glob, Grep, Edit, Write | Reorganizes learning files. No Bash, no user interaction. |
| `learnings/distribute` | Read, Glob, Grep, Edit, Write, Bash(cp:*) | Copies files between directories. Minimal Bash. |
| `set-persona` | Read | Reads persona files and sets context. No writes. |
| `ralph/init` | Read, Write, Bash(mkdir:*), Bash(date:*), TodoWrite | Creates directory structure. Narrow Bash scope. |
| `prune-merged` | Read, Bash(git:*), AskUserQuestion | Git-only operations. No file edits. |
| `repoint-branch` | Read, Bash(git:*), Bash(gh:*), AskUserQuestion | Git + GitHub operations. No direct file edits. |

### Tier 3: Low Benefit — Full Tool Access Needed

These skills are orchestrators or need broad tool access. Restricting tools adds complexity with little safety benefit.

| Skill | Reason for Skipping |
|-------|-------------------|
| `create-pr` | Full workflow: reads, writes, git, gh, Task subagents, AskUserQuestion |
| `address-pr-review` | Reads PR feedback, edits code, runs tests — needs everything |
| `resolve-conflicts` | Reads conflicts, edits files, runs git — needs everything |
| `cascade-rebase` | Multi-branch rebase — needs git, edit, possibly conflict resolution |
| `monitor-pr-comments` | Background script, Bash, file writes, Task subagents |
| `parallel-plan/make` | Orchestrator: reads plan, spawns analysis subagents |
| `parallel-plan/execute` | Full orchestrator: spawns subagents that do arbitrary work |
| `learnings/consolidate` | Delegates to curate, spawns subagents, AskUserQuestion |
| `quantum-tunnel-claudes` | Sync tool: reads from source, writes to target, git operations |
| `do-refactor-code` | Listed in Tier 2 above (could go either way) |

---

## 5. Adoption Strategy

### Phase 1: Intent-Signaling (Now, Pre-Enforcement)

Add `allowed-tools` to **Tier 1 and Tier 2 skills** (13 skills) as documentation. No runtime impact while enforcement is broken.

**Benefits:**
- Documents design intent for each skill
- Prepares for when enforcement lands — tool lists are already defined and reviewed
- Aligns with Trail of Bits' approach (the leading community pattern)
- Makes code review easier — reviewers can see intended scope at a glance
- If enforcement is eventually fixed, skills are immediately locked down

**Risks:**
- Tool lists may be incomplete → skills break when enforcement lands. **Mitigation**: test thoroughly when enforcement is announced.
- YAML list syntax may not be supported by future Agent Skills validators. **Mitigation**: trivial to convert format.

**Effort**: ~15 minutes. One YAML block per skill, 13 skills.

### Phase 2: Validation (When Enforcement Lands)

When #14956 is fixed:
1. Test each skill with `allowed-tools` enforced
2. Verify no tool calls are blocked unexpectedly
3. Adjust tool lists as needed
4. Add scoped Bash patterns where appropriate (`Bash(git:*)` instead of bare `Bash`)

### Phase 3: Tighten Scope (Post-Enforcement)

Once enforcement is confirmed working:
1. Replace bare `Bash` with scoped patterns where possible
2. Add `allowed-tools` to Tier 3 skills where feasible
3. Monitor #1271 (piped commands bypass) — affects `Bash(git:*) && Bash(grep:*)` patterns

---

## 6. Recommended Tool Lists (Ready to Apply)

```yaml
# Tier 1: Read-only analysis
explore-repo:
  allowed-tools:
    - Read
    - Glob
    - Grep
    - Task
    - WebFetch

do-security-audit:
  allowed-tools:
    - Read
    - Glob
    - Grep
    - Task
    - WebFetch

split-pr:
  allowed-tools:
    - Read
    - Glob
    - Grep
    - Bash

explore-pr:
  allowed-tools:
    - Read
    - Glob
    - Grep
    - Bash

ralph/compare:
  allowed-tools:
    - Read
    - Glob
    - Grep

# Tier 2: Narrowly scoped writes
do-refactor-code:
  allowed-tools:
    - Read
    - Glob
    - Grep
    - Edit
    - Write
    - Bash

learnings/compound:
  allowed-tools:
    - Read
    - Glob
    - Grep
    - Edit
    - Write
    - AskUserQuestion
    - Skill

learnings/curate:
  allowed-tools:
    - Read
    - Glob
    - Grep
    - Edit
    - Write

learnings/distribute:
  allowed-tools:
    - Read
    - Glob
    - Grep
    - Edit
    - Write
    - Bash

set-persona:
  allowed-tools:
    - Read

ralph/init:
  allowed-tools:
    - Read
    - Write
    - Bash
    - TodoWrite

prune-merged:
  allowed-tools:
    - Read
    - Bash
    - AskUserQuestion

repoint-branch:
  allowed-tools:
    - Read
    - Bash
    - AskUserQuestion
```

**Note on `Bash` scope**: Using bare `Bash` (not `Bash(git:*)`) for now because:
1. Scoped Bash patterns have their own bugs (#11366, #1271)
2. Many skills need multiple Bash commands (git, gh, grep, etc.) — listing all patterns is verbose
3. Tightening to scoped patterns is Phase 3 work (post-enforcement)

**Note on `Task` and `Skill`**: These orchestration tools are needed by skills that delegate work. `explore-repo` and `do-security-audit` use `Task` for parallel subagents. `learnings/compound` invokes `/learnings:curate` via the `Skill` tool.

---

## 7. What NOT to Do

1. **Don't add `allowed-tools` to Tier 3 skills yet** — orchestrators need broad tool access. Restricting them adds maintenance burden with no safety benefit until enforcement works.
2. **Don't use scoped Bash patterns yet** — too many bugs (#1271 piped commands, #11366 pwsh). Bare `Bash` is safer until these are fixed.
3. **Don't rely on `allowed-tools` for security** — enforcement is broken. Use it for documentation only.
4. **Don't block on this** — `allowed-tools` is a nice-to-have, not a prerequisite for any other implementation phase.

---

## 8. Monitoring

Track these issues to know when to move from Phase 1 to Phase 2:

| Issue | What It Blocks |
|-------|---------------|
| [#14956](https://github.com/anthropics/claude-code/issues/14956) | Basic enforcement — everything |
| [#1271](https://github.com/anthropics/claude-code/issues/1271) | Scoped Bash patterns (Phase 3) |
| [#11366](https://github.com/anthropics/claude-code/issues/11366) | Windows/pwsh support |

**Trigger for Phase 2**: When #14956 is closed, test all 13 skill tool lists within a week.

---

## Sources

- [Agent Skills Specification — `allowed-tools` field](https://agentskills.io/specification)
- [GitHub #14956 — Skill allowed-tools doesn't grant permission for Bash commands](https://github.com/anthropics/claude-code/issues/14956) (Open)
- [GitHub #18837 — allowed-tools not enforced](https://github.com/anthropics/claude-code/issues/18837) (Closed, dup of #14956)
- [GitHub #18737 — SDK ignores allowed-tools](https://github.com/anthropics/claude-code/issues/18737) (Closed, doc update)
- [GitHub #13494 — Inconsistent tool permissions](https://github.com/anthropics/claude-code/issues/13494) (Closed, user error — syntax)
- [GitHub #1271 — Piped commands bypass allowed-tools](https://github.com/anthropics/claude-code/issues/1271) (Open)
- [GitHub #11366 — PowerShell wildcard support](https://github.com/anthropics/claude-code/issues/11366) (Open)
- [Trail of Bits skills repo](https://github.com/trailofbits/skills) — Primary real-world `allowed-tools` adopter
- [Anthropic official skills repo](https://github.com/anthropics/skills) — 16 skills, none use `allowed-tools`
