# Deep Research: Subagent Configuration Patterns

## Overview

Custom subagent definitions live in `~/.claude/agents/` (user-scope) or `.claude/agents/` (project-scope). They are Markdown files with YAML frontmatter — structurally identical to skills but serving a different purpose: subagents define **who does the work** (identity, tools, memory), while skills define **what work to do** (instructions, workflow).

This research evaluates how custom agents can complement the repo's 22 existing skills, and documents the full configuration surface.

---

## 1. Anatomy of a Custom Agent

### File Format

```markdown
---
name: code-reviewer
description: Expert code review specialist. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
model: sonnet
memory: user
---

You are a senior code reviewer. When invoked, analyze the code and provide
specific, actionable feedback on quality, security, and best practices.
```

- **Frontmatter** = configuration (who the agent is, what it can do)
- **Body** = system prompt (how the agent behaves)
- Subagents receive only their system prompt + basic environment details (CWD, etc.), NOT the full Claude Code system prompt or parent conversation history

### Where Agents Live (Priority Order)

| Location | Scope | Priority | Notes |
|----------|-------|----------|-------|
| `--agents` CLI flag | Current session only | 1 (highest) | JSON format, not saved to disk |
| `.claude/agents/` | Current project | 2 | Check into VCS for team sharing |
| `~/.claude/agents/` | All projects | 3 | Personal agents |
| Plugin `agents/` | Where plugin enabled | 4 (lowest) | Distributed via plugins |

When multiple agents share the same name, higher-priority wins. Use `/agents` command to view all agents and create/edit interactively.

### Session Loading

Agents are **loaded at session start**. Manually adding a file requires session restart unless created via `/agents`. No hot-reload like skills from `--add-dir`.

---

## 2. Complete Frontmatter Reference

| Field | Required | Description | Default |
|-------|----------|-------------|---------|
| `name` | Yes | Unique identifier. Lowercase + hyphens. | — |
| `description` | Yes | When Claude should delegate. Used for auto-routing. | — |
| `tools` | No | Allowlist of tools the agent can use. | Inherits all tools from parent |
| `disallowedTools` | No | Denylist — removed from inherited/specified tools. | None |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit`. | `inherit` |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`. | Inherits from parent |
| `maxTurns` | No | Max agentic turns before the agent stops. | Unlimited |
| `skills` | No | Skills to preload into context at startup. Full content injected, not just made available. | None (agents don't inherit parent's skills) |
| `mcpServers` | No | MCP servers available. Either a name referencing a configured server, or inline definition. | None |
| `hooks` | No | Lifecycle hooks scoped to this agent (PreToolUse, PostToolUse, Stop). | None |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local`. | None (stateless) |
| `background` | No | `true` = always run as background task. | `false` |
| `isolation` | No | `worktree` = runs in temporary git worktree. Auto-cleaned if no changes. | None (shares CWD) |

### Field Interactions and Constraints

- **`tools` vs `disallowedTools`**: Use `tools` for narrow allowlists, `disallowedTools` for "everything except X". Can't use both meaningfully.
- **`tools` with `Task(agent_type)`**: Restricts which subagents this agent can spawn. Only meaningful for agents run as main thread via `claude --agent`. Subagents cannot spawn other subagents regardless.
- **`skills` injection**: Full skill content is injected into context, not just made available for discovery. This is the **inverse** of `context: fork` in skills. Agents don't inherit skills from parent — must list explicitly.
- **`memory` enables Read/Write/Edit**: When memory is set, these tools are automatically enabled so the agent can manage its memory files.
- **`background: true` + permissions**: Background agents get permissions upfront at launch. Auto-deny anything not pre-approved. No AskUserQuestion. No MCP tools.
- **`isolation: worktree`**: Creates temp git worktree. Worktree auto-cleaned if agent makes no changes. If changes exist, worktree path and branch returned.
- **`permissionMode: bypassPermissions`**: If the parent uses this, it takes precedence and can't be overridden by the agent.

---

## 3. Built-in Agents Reference

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| **Explore** | Haiku | Read-only (denied Write, Edit) | Fast codebase search/analysis |
| **Plan** | Inherit | Read-only (denied Write, Edit) | Codebase research during plan mode |
| **general-purpose** | Inherit | All tools | Complex multi-step tasks |
| **Bash** | Inherit | Bash | Terminal commands in separate context |
| **statusline-setup** | Sonnet | Read, Edit | `/statusline` config |
| **Claude Code Guide** | Haiku | — | Questions about Claude Code features |

Key constraint: **Subagents cannot spawn other subagents.** No Task nesting.

---

## 4. Skill ↔ Agent Relationship

There are two ways skills and agents interact:

### Pattern A: Skill runs in agent (`context: fork` + `agent:`)

The skill's SKILL.md content becomes the task delegated to the specified agent type. The agent's system prompt + skill content form the complete context.

```yaml
# In a SKILL.md
---
context: fork
agent: code-reviewer   # references a custom agent or built-in
---
Instructions become the task for the agent...
```

- Skill controls **what** to do
- Agent controls **who** does it (model, tools, memory)
- No conversation history, no Task nesting, no AskUserQuestion
- Output is a deliverable returned to main conversation

### Pattern B: Agent preloads skills (`skills:` field)

The agent's markdown body is the system prompt. Skills are loaded as additional context.

```yaml
# In an agents/*.md file
---
name: api-developer
skills:
  - api-conventions
  - error-handling-patterns
---
Agent system prompt here. Use the preloaded skills for domain knowledge.
```

- Agent controls **who** and **how**
- Skills provide **domain knowledge** (preloaded, not discovered)
- Agent can still use all its tools normally
- Full agentic behavior (multi-turn, tool calls, etc.)

### Pattern C: Skill orchestrates agents via Task tool

The skill runs in the main conversation and spawns agents using the Task tool with `subagent_type`. This is what most of the repo's complex skills do.

```markdown
# In a SKILL.md (no context: fork)
Launch parallel agents using the Task tool with `subagent_type: "general-purpose"`.
```

- Skill controls **orchestration** (what agents to spawn, how to coordinate)
- Uses built-in or custom agent types via `subagent_type` parameter
- Most flexible — supports parallel agents, coordination, error handling
- But agents are defined inline via Task prompts, not via reusable agent definitions

### Decision Matrix

| Need | Use Pattern |
|------|------------|
| Simple task → report back | A: `context: fork` + `agent:` |
| Agent needs domain knowledge from skills | B: Agent `skills:` field |
| Complex orchestration, parallel workers | C: Skill + Task tool |
| Agent needs persistent memory/learning | B: Agent with `memory:` |
| Want tool restrictions on workers | A or B: Agent `tools:` field |

---

## 5. Evaluation: Custom Agents for This Repo's Skills

### Current State

- **0/22 skills** use `context: fork` or reference custom agents
- **0 custom agents** exist (`~/.claude/agents/` directory doesn't exist)
- Skills that spawn subagents use the built-in `general-purpose` and `Explore` types exclusively
- Subagent behavior is defined inline in skill prompts, not via reusable agent definitions

### Candidate Analysis

For each skill that spawns subagents, I evaluated whether a custom agent definition would add value over inline Task prompts.

#### High-Value Candidates

**1. `pr-reviewer` agent**
- **Used by**: `git/address-pr-review`, `git/explore-pr`, `git/monitor-pr-comments`
- **Specialization**: PR diff interpretation, review comment parsing, GitHub API patterns
- **Agent definition**:
  ```yaml
  name: pr-reviewer
  description: PR review specialist. Reviews diffs, interprets comments, and suggests changes.
  tools: Read, Grep, Glob, Bash
  model: inherit
  memory: user
  ```
- **Value**: Three skills share similar subagent needs for PR review. A reusable agent with persistent memory could learn project-specific review patterns over time. The `memory: user` scope means learnings carry across projects.
- **Risk**: Low — read-heavy with targeted Bash (gh commands). No Write/Edit needed for review analysis.

**2. `codebase-explorer` agent**
- **Used by**: `explore-repo`, `do-security-audit`
- **Specialization**: Systematic codebase scanning with structured output
- **Agent definition**:
  ```yaml
  name: codebase-explorer
  description: Systematic codebase analyzer. Scans directories, identifies patterns, reports findings.
  tools: Read, Grep, Glob, Bash
  model: haiku
  memory: project
  ```
- **Value**: Both skills need agents that systematically scan code and produce structured reports. A shared agent with `memory: project` could build up knowledge of the codebase structure over time, making repeated scans faster and more accurate.
- **Risk**: Low — read-only analysis. Using `haiku` for cost savings on bulk scanning.
- **Concern**: `explore-repo` currently uses `general-purpose` so agents can spawn sub-agents. Custom agents, being subagents themselves, cannot nest. This is a **breaking change** if the exploration agents need to sub-delegate. Need to verify whether this nesting actually occurs in practice.

**3. `code-implementer` agent**
- **Used by**: `parallel-plan/execute`, `do-refactor-code`
- **Specialization**: Code modification with quality checks
- **Agent definition**:
  ```yaml
  name: code-implementer
  description: Implements code changes following quality standards. Use proactively for code modifications.
  tools: Read, Edit, Write, Grep, Glob, Bash
  model: inherit
  skills:
    - do-refactor-code  # Preload refactoring checklist
  ```
- **Value**: Skills that delegate code changes could benefit from a standardized agent with quality checklist preloaded via `skills:` field.
- **Risk**: Medium — this agent has Write/Edit access. The `skills:` preload adds token cost to every invocation.
- **Concern**: `parallel-plan/execute` already reads code-quality-checklist as a reference file and injects it into Task prompts. Moving to a custom agent changes the injection mechanism but provides the same content.

#### Medium-Value Candidates

**4. `learnings-analyst` agent**
- **Used by**: `learnings/curate`, `learnings/consolidate`, `learnings/compound`
- **Specialization**: Analyzing, classifying, and consolidating learning files
- **Agent definition**:
  ```yaml
  name: learnings-analyst
  description: Analyzes and classifies learning documents for consolidation and curation.
  tools: Read, Grep, Glob
  model: inherit
  memory: user
  ```
- **Value**: The learnings skills share a common need for pattern recognition across learning files. A persistent-memory agent could learn the user's preferred organization style.
- **Risk**: Low — read-only analysis.
- **Why medium**: The learnings skills already have well-structured inline prompts. The benefit of a custom agent is mainly the `memory: user` persistent learning, which could be achieved other ways.

#### Low-Value Candidates (Defer)

**5. Generic research agent for `ralph/` skills**: Not worth it — ralph skills already define comprehensive inline prompts, and the research context is too variable to benefit from a reusable agent.

**6. Plan analysis agent for `parallel-plan/make`**: The planning agent's behavior is heavily prompt-dependent and changes per plan context. A static agent definition would be too generic.

### Recommendation: Start with `pr-reviewer`

**Why**: Highest overlap across skills (3 skills), clear specialization (PR review is a well-defined domain), low risk (read-only), and `memory: user` provides the most immediate value — the agent can learn review patterns that improve across projects.

**Proof-of-concept scope**:
1. Create `~/.claude/agents/pr-reviewer.md`
2. Update `git/address-pr-review` to reference it via `subagent_type: "pr-reviewer"` in Task calls
3. Validate that Claude auto-delegates PR review tasks to this agent
4. If successful, extend to `git/explore-pr` and `git/monitor-pr-comments`

---

## 6. Key Patterns and Anti-Patterns

### Patterns (Do)

1. **Use `memory: user` for cross-project learning**. Agents that review code, analyze patterns, or explore codebases benefit most. The memory builds institutional knowledge over time.

2. **Use `tools:` for least-privilege**. Read-only agents (`tools: Read, Grep, Glob`) are safer for analysis tasks. Only add Write/Edit when the agent genuinely needs to modify files.

3. **Use `model:` for cost optimization**. Bulk scanning tasks (security audit, exploration) work well with `haiku`. Reasoning-heavy tasks (code review, refactoring) should `inherit` or use `opus`.

4. **Use `background: true` for long-running, non-interactive agents**. Good for monitoring tasks (PR comment watcher) or batch analysis. But remember: no AskUserQuestion, no MCP tools, auto-deny unapproved permissions.

5. **Use `isolation: worktree` for agents that make code changes**. Prevents agents from stepping on each other or the main working directory. Auto-cleaned if no changes.

6. **Use `skills:` to preload domain knowledge**. When an agent needs specific conventions or checklists, preload them rather than hoping the agent discovers them.

7. **Write detailed descriptions for auto-routing**. Claude uses the description to decide when to delegate. Include "use proactively" if the agent should be auto-delegated.

### Anti-Patterns (Don't)

1. **Don't create agents that are just renamed built-ins**. If the agent is `general-purpose` with no specialization, don't create a custom definition — just use the built-in.

2. **Don't preload too many skills via `skills:`**. Each preloaded skill's full content is injected into context. Loading 5 skills at 200 lines each = 1000 lines of preloaded context that may not all be needed.

3. **Don't assume agents inherit parent skills**. They don't. If an agent needs skill knowledge, it must be explicitly listed in `skills:`.

4. **Don't use `background: true` for interactive workflows**. Background agents can't ask questions or request permissions dynamically.

5. **Don't overfit agents to single skills**. The value of a custom agent comes from reuse across multiple skills. A one-off agent is better defined inline.

6. **Don't nest agents that need sub-delegation**. Subagents can't spawn other subagents. If the workflow requires orchestration, keep it in the skill (Pattern C), not the agent.

---

## 7. Memory System Deep Dive

### How It Works

When `memory:` is set, Claude Code:
1. Creates a directory at the scope-appropriate path
2. Injects instructions for reading/writing to that directory into the agent's system prompt
3. Auto-loads first 200 lines of `MEMORY.md` from the memory directory
4. Enables Read, Write, Edit tools for memory file management

### Memory Scopes

| Scope | Path | Best For |
|-------|------|----------|
| `user` | `~/.claude/agent-memory/<agent-name>/` | Cross-project patterns (review style, common bugs, preferences) |
| `project` | `.claude/agent-memory/<agent-name>/` | Project-specific knowledge (architecture, naming conventions) |
| `local` | `.claude/agent-memory-local/<agent-name>/` | Project-specific, not VCS-tracked (credentials context, local infra) |

### Memory Strategy for This Repo

For a personal dotfiles repo where skills are used across all projects:

- **`pr-reviewer`**: `memory: user` — review patterns should transfer across projects
- **`codebase-explorer`**: `memory: project` — codebase knowledge is project-specific
- **`code-implementer`**: No memory — implementation context is too task-specific to persist usefully
- **`learnings-analyst`**: `memory: user` — organizational preferences are personal, not project-bound

### Memory Effectiveness Tips (from docs)

- Include memory instructions in the agent's system prompt: "Update your agent memory as you discover patterns..."
- Ask the agent to consult memory before starting: "Review this PR, and check your memory for patterns you've seen before"
- Ask the agent to save learnings after completing: "Now that you're done, save what you learned"
- Keep MEMORY.md under 200 lines — longer content is truncated

---

## 8. Agent Teams vs Custom Agents vs Skills

| Feature | Skills | Custom Agents (Subagents) | Agent Teams |
|---------|--------|--------------------------|-------------|
| **Status** | Stable | Stable | Experimental |
| **Context** | Main conversation or fork | Isolated context | Fully independent sessions |
| **Communication** | In-conversation | Report to parent only | Direct inter-agent messaging |
| **Memory** | No persistent state | `memory:` field | Each teammate has own context |
| **Best for** | Reusable workflows/knowledge | Focused, delegated tasks | Complex multi-agent collaboration |
| **Token cost** | Lowest (shared context) | Medium (own context per agent) | Highest (separate sessions) |
| **Coordination** | Via skill orchestration | Via parent Task tool | Shared task list, mailbox |
| **Can spawn sub-agents** | Yes (via Task tool) | No | No (teammates can't nest) |
| **Nesting** | Not applicable | Cannot nest | Cannot nest teams |

### When to Use Agent Teams

Agent teams are **experimental** (behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` flag) and best for:
- Research/review with multiple competing perspectives
- New features where teammates each own a separate piece
- Debugging with competing hypotheses
- Cross-layer coordination (frontend, backend, tests)

For this repo: Agent teams are overkill for current skills. The orchestration patterns in `parallel-plan/execute` and `explore-repo` handle parallelism well with subagents. Agent teams become relevant if skills need **inter-agent discussion** (e.g., "security reviewer debates with performance reviewer about a trade-off").

---

## 9. Impact on Implementation Plan

### Phase 4C Updates

The original implementation plan (Phase 4C) proposed:
- `code-reviewer` agent for address-pr-review, explore-pr
- `refactoring-agent` for do-refactor-code

Based on this research, the recommended changes:

1. **Rename `code-reviewer` → `pr-reviewer`** — more specific to actual use case (PR review, not general code review)
2. **Add `memory: user`** — the key differentiator over inline Task prompts
3. **Start with 1 agent, not 2** — `pr-reviewer` as proof-of-concept, then expand based on results
4. **Add `codebase-explorer`** as second agent — used by `explore-repo` and `do-security-audit`
5. **Defer `code-implementer`** — medium risk, lower value without persistent memory
6. **Document the nesting constraint** — skills that spawn `general-purpose` agents for orchestration CANNOT be migrated to custom agents without verifying no Task nesting occurs

### New Phase 4C Task Breakdown

| Step | Agent | Skills Affected | Memory | Risk |
|------|-------|----------------|--------|------|
| 4C.1 | `pr-reviewer` | address-pr-review | `user` | Low |
| 4C.2 | Extend `pr-reviewer` | explore-pr, monitor-pr-comments | `user` | Low |
| 4C.3 | `codebase-explorer` | explore-repo, do-security-audit | `project` | Low-Medium (nesting concern) |
| 4C.4 | Evaluate results | — | — | — |

---

## 10. Open Questions

1. **Does `explore-repo` actually use Task nesting?** The skill says `subagent_type: "general-purpose"` "allows them to spawn sub-agents if they encounter too many files." If this nesting occurs in practice, migrating to a custom agent (which can't nest) would break the skill. Needs empirical testing.

2. **How does `subagent_type: "pr-reviewer"` interact with skills?** When a skill's Task call uses `subagent_type: "pr-reviewer"`, does Claude use the custom agent definition from `~/.claude/agents/pr-reviewer.md`? The docs say custom agents are available as subagent types, but the exact Task tool integration isn't explicitly documented for skill-spawned subagents.

3. **Memory directory and gitignore**: For `memory: project` scope, should `.claude/agent-memory/` be gitignored? It contains agent-generated notes that may not be suitable for version control in all projects.

4. **Description budget impact**: Custom agents have descriptions that go into Claude's context (for auto-routing). Adding 4 agents adds ~4 descriptions to the context budget. Is this already tight with 22 skills?

---

## Sources

- [Claude Code Sub-agents docs](https://code.claude.com/docs/en/sub-agents) — Official reference (Feb 2026)
- [Claude Code Agent Teams docs](https://code.claude.com/docs/en/agent-teams) — Experimental feature reference
- [Claude Code Skills docs](https://code.claude.com/docs/en/skills) — Skill ↔ agent integration
- This repo: `~/.claude/commands/parallel-plan/execute/SKILL.md`, `~/.claude/commands/explore-repo/SKILL.md`, `~/.claude/commands/do-security-audit/SKILL.md`
