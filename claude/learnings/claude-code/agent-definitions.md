Custom agent definitions and agent-skill integration — ~/.claude/agents/ frontmatter, memory scopes, and skill preloading patterns.
- **Keywords:** agents, agent definition, ~/.claude/agents/, memory, user memory, project memory, skills field, model override, background agent, isolation worktree, maxTurns, permissionMode
- **Related:** none

---

## Custom Agent Definitions (`~/.claude/agents/`)

Custom agents are Markdown files with YAML frontmatter in `~/.claude/agents/` (user-scope) or `.claude/agents/` (project-scope). They define **who does the work** — identity, tools, memory — while skills define **what work to do**.

### Key Frontmatter Fields

| Field | Description |
|-------|-------------|
| `name`, `description` | Required. Description used for auto-routing (Claude decides when to delegate). |
| `tools` / `disallowedTools` | Tool allowlist/denylist. Defaults to inheriting all parent tools. |
| `model` | `sonnet`, `opus`, `haiku`, or `inherit` (default). |
| `skills` | Preload skill content into agent context. Full content injected, not just made available. **Agents don't inherit parent's skills** — must list explicitly. |
| `memory` | `user` / `project` / `local` — persistent directory that survives across sessions. Auto-loads first 200 lines of MEMORY.md. Auto-enables Read/Write/Edit. |
| `background` | `true` = always background. No AskUserQuestion, no MCP, auto-deny unapproved permissions. |
| `isolation` | `worktree` = temp git worktree. Auto-cleaned if no changes. |
| `hooks` | PreToolUse/PostToolUse/Stop hooks scoped to this agent. |
| `permissionMode` | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`. |
| `maxTurns` | Max agentic turns before stopping. |

### Critical Constraints

- Agents loaded at **session start** — manual file additions require restart (or use `/agents`).
- Subagents **cannot spawn other subagents** (no Task nesting). Skills using `general-purpose` specifically to allow sub-delegation cannot migrate to custom agents.
- Subagents **cannot use the Skill tool** — permission denied regardless of `tools` frontmatter. The Skill tool is not in the available tool set for subagents. To run skills from subagents, read the SKILL.md and follow its steps as inline methodology (but note: any skill steps requiring Agent will also fail due to nesting). (Note: `claude -p` top-level sessions *can* invoke skills — see `multi-agent/autonomous-patterns.md` § "Skill Invocation in Autonomous Agents")
- When agents share the same name, priority: CLI flag > project > user > plugin.

## Agent `memory:` for Persistent Cross-Session Learning

The `memory` field gives agents a persistent directory for building knowledge over time.

| Scope | Path | Best for |
|-------|------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Cross-project patterns (review style, common bugs) |
| `project` | `.claude/agent-memory/<name>/` | Project-specific knowledge (architecture, naming) |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not VCS-tracked |

When enabled: system prompt gets memory instructions, first 200 lines of MEMORY.md auto-loaded, Read/Write/Edit auto-enabled. Include memory instructions in the agent's system prompt for proactive knowledge capture: "Update your agent memory as you discover patterns..."

## Three Skill↔Agent Integration Patterns

Extends the `context: fork` vs Task pattern (see `skill-platform-portability.md`):

**Pattern: Agent preloads skills (`skills:` field)**
```yaml
# In agents/api-developer.md
skills:
  - api-conventions
  - error-handling-patterns
```
The agent's markdown body is the system prompt; skills provide domain knowledge preloaded into context. This is the **inverse** of `context: fork` — here the agent controls the system prompt, not the skill. Use when the agent needs domain knowledge from multiple skills without the overhead of discovering them.

## When to Fold an Agent Into a Persona

If an agent's value is *applying a lens* — priority weighting, gotcha awareness, tradeoff calibration, review focus — rather than *executing isolated work* — multi-step research, parallel exploration, context-heavy reading — the agent is overhead. Promote it to a persona.

| Signal | Verdict |
|--------|---------|
| Always invoked as "review this with X mindset" / "think about this as Y" | Fold to persona |
| Invocations look like "go do Z autonomously, return a report" | Keep as agent |
| Value is judgment per token of output | Fold to persona |
| Value is parallelism, isolation, or context budget protection | Keep as agent |
| Body reads like a system prompt of preferences, not a task spec | Fold to persona |

Personas pay near-zero structural cost (they're a lens loaded into the main loop) where agents pay isolation overhead (separate context, tool plumbing, return-value coordination). When the work was always happening inline anyway, the agent's isolation buys nothing.

Composition lets you fold multiple specialist agents into one fused persona without losing structure — the `## Extends: base-persona` pattern preserves the inheritance shape (e.g., `python-quant-dev` extends `python-engineer`; `java-fintech` extends `fintech-ledger-engineer` and `java-backend`). Two formerly-separate agent personalities can live in one persona file when the activation triggers overlap heavily.

**Provenance footprints to clean on fold:** persona files synthesized from former agents often carry `## Delegation hints` sections or "delegate to the agents for isolated deep dives" header fragments. Once the agents are gone, those are stale refs — strip them during the fold or in a follow-up pass.

## Cross-Refs

No cross-cluster references.
