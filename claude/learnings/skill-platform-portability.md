# Skill Platform & Portability

Official features, cross-platform compatibility, plugins, and agent definitions for the Claude Code skill ecosystem.
**Keywords:** commands, skills, frontmatter, allowed-tools, context fork, disable-model-invocation, $ARGUMENTS, plugins, agents, memory, progressive disclosure, shell preprocessing, baseDir, Agent Skills spec, SkillPort, compatibility field
**Related:** claude-authoring-skills.md, claude-code.md

---

## `commands/` and `skills/` Are Fully Feature-Equivalent

The official docs state both "work the same way" and "support the same frontmatter." Every feature works in `commands/` — no directory rename needed. Previously assumed `skills/`-exclusive features (monorepo auto-discovery, `--add-dir` hot-reload, plugin packaging) were confirmed to work in `commands/` too — via user testing (auto-discovery, hot-reload) and the [plugin docs](https://code.claude.com/docs/en/plugins) explicitly listing both directories. The only difference is naming convention.

## Unused Official Frontmatter Features

This repo's skills use only `description:` from SKILL.md frontmatter. Official features not yet adopted:

- **`allowed-tools`** — Scoped tool permissions active only during skill execution. **Confirmed working** (tested 2026-03-16: skill with `allowed-tools: [Read, Glob, Grep, Edit, Write]` successfully blocked Bash calls). **Recommended syntax: YAML list.** Use bare tool names (not scoped `Bash(git:*)`).
- **`context: fork` + `agent:`** — Run skill in isolated subagent. See "`context: fork` vs Task Subagents" section below.
- **`model:`** — Override session model per skill (e.g., `haiku` for simple tasks, `opus` for complex reasoning).
- **`disable-model-invocation: true`** — See "`disable-model-invocation` Removes Skill from Context" section below.
- **`{baseDir}`** — Resolves to skill's own installation directory (e.g., `~/.claude/commands/<skill>/`). Works for intra-skill references (scripts/, references/, assets/) but **cannot** replace `~/.claude/` for cross-directory references to `~/.claude/learnings/`, `~/.claude/skill-references/`, etc.

## `disable-model-invocation` Removes Skill from Context

Setting `disable-model-invocation: true` does more than prevent auto-invocation — it **completely removes the skill's description from Claude's context**. This means Claude won't know the skill exists until manually invoked. Trade-off: saves context budget but loses auto-discovery. Use for skills that are only invoked explicitly (e.g., `/ralph:init`, `/learnings:consolidate`).

## Add Broken/Experimental Features for Intent-Signaling

When an official frontmatter feature exists but enforcement status is uncertain, it can still be worth adding — as documentation of design intent and (when working) runtime enforcement. Criteria: (1) it communicates the skill's intended tool surface to human readers, (2) it enforces the constraint at runtime when supported. Only do this for features where the *intended* behavior matches your *actual* intent — don't add `allowed-tools: Read, Glob` if the skill legitimately needs Write sometimes.

## Progressive Disclosure: Three Token-Cost Tiers

Anthropic's official model for skill content budgeting:

| Tier | What | Token Cost | Budget |
|------|------|------------|--------|
| Metadata | name + description | Always loaded | ~100 words |
| SKILL.md body | Instructions | On trigger | <5k words |
| Bundled resources | scripts/, references/, assets/ | On demand | Unlimited |

Key distinction: `scripts/` files execute without reading into context (zero token cost). `references/` files are loaded into context (token cost). `assets/` are referenced by path only (zero token cost). Our repo uses only references — no scripts or assets.

## Dynamic Context Injection via Shell Preprocessing

The `` !`command` `` syntax in SKILL.md runs shell commands as preprocessing — output replaces the placeholder before Claude sees the prompt. Not cached; re-runs every invocation.

### Evaluation Framework

A good `` !`command` `` candidate must pass ALL five criteria:

1. **Reliability** — Command rarely fails regardless of repo state
2. **Output size** — Small, bounded (<5 lines ideal)
3. **Always needed** — Used every invocation, not just conditional branches
4. **Saves a step** — Claude would run the same command as its first action anyway
5. **Read-only** — No side effects or mutations

### Disqualifiers

- Unbounded output (e.g., `git log` without `| head`, `gh pr diff`)
- Network-dependent commands that may timeout (e.g., `gh api ...`)
- State-dependent commands that only work in specific states (e.g., `git diff --name-only --diff-filter=U` only works mid-merge)

### Best Injection: `git branch --show-current`

The single highest-value injection across the skill collection. 7/9 git skills need it as their first context. ~5 tokens, always succeeds, saves 1 Bash call per invocation.

### Implementation Pattern

Add `## Context` section immediately after frontmatter. Always append `2>/dev/null` for graceful degradation outside git repos:

```markdown
## Context
- Current branch: !`git branch --show-current 2>/dev/null`
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
```

For network-dependent commands, provide fallback: `|| echo "unknown"`.

## `context: fork` vs Task Subagents

Two isolation mechanisms, different use cases:

- **`context: fork`** — Skill delivery. The *entire skill* runs as a subagent. User invokes `/skill-name`, gets a result back. No conversation history, no mid-task interaction. Best for self-contained, one-shot analysis (input → summary).
- **Task subagents** — Orchestration. The skill runs inline and *delegates subtasks* to workers. Skill stays in main context, coordinates multiple agents, synthesizes results. Best for parallel work, multi-step workflows, anything needing user interaction or conversation history.

They conflict: a forked skill can't spawn Task subagents (no nesting). So skills that orchestrate workers (explore-repo, do-security-audit, parallel-plan:execute) must stay inline with Task subagents — they can't use `context: fork`.

**Choose fork when:** entire skill is a pure function (args in, report out). **Choose Task when:** skill needs to coordinate, interact, or delegate.

### Viability Checklist

A skill is viable for `context: fork` only if ALL of these are true:

1. **No internal subagent spawning** — skill doesn't use Task tool (subagents can't nest)
2. **No conversation history dependency** — skill operates from $ARGUMENTS alone, not prior discussion
3. **No mid-task user interaction** — no AskUserQuestion or confirmation prompts during execution
4. **Task-based, not reference-based** — skill has actionable instructions, not just guidelines
5. **Output is a deliverable** — produces a summary/report that returns to the main conversation

Failing any one eliminates the skill. In practice, most interactive or orchestrating skills fail criteria 1-3.

## Skill Field Constraints (from Anthropic's Official Guide)

- **`name`**: Max 64 characters, lowercase with hyphens. Must not contain "claude" or "anthropic".
- **`description`**: Max 1,024 characters. Must not contain XML angle brackets (`<` or `>`).
- **`dependencies`**: Declares skills this one requires (not yet observed in the wild).

Source: [The Complete Guide to Building Skills for Claude (PDF)](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)

## Skills Are Cross-Platform

Skills work across **Claude.ai, Claude Code, and the API** — same folder, no modification needed. Distribution varies by surface: ZIP upload (Claude.ai Settings > Capabilities > Skills), directory placement (`~/.claude/commands/` or `~/.claude/skills/`), `/v1/skills` REST endpoint (CI/CD), org-level workspace deployment (teams, shipped Dec 2025).

## Skill Description Context Budget

All skill descriptions share a budget of **2% of the context window** (~16,000 chars fallback). Skills exceeding the budget are silently excluded. Check with `/context`. Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var.

**Per-entry overhead is ~109 chars** (XML tags ~85, skill name ~16 avg, location field ~4) beyond description text. Formula: `chars_per_skill = description_length + ~109`. Budget fills at ~15,700 chars total.

At typical collection sizes (20-30 skills), utilization is well under 50% with ample headroom. No aggressive description compression needed — `disable-model-invocation` should be motivated by preventing unwanted auto-invocation, not budget savings.

| Avg Desc Length | Max Skills Capacity |
|----------------|-------------------|
| 250 chars | ~45 |
| 150 chars | ~62 |
| 103 chars | ~75 |
| 80 chars | ~85 |

## Built-In Bundled Skills

`keybindings-help` is a built-in skill (~337 chars, ~50 tokens/cycle) always loaded by Claude Code, even with `--disable-slash-commands` ([bug #24156](https://github.com/anthropics/claude-code/issues/24156)). Skills are injected as user-message attachments, not in the system prompt. Bundled skills bypass all settings-based filtering — they load after plugin/user/managed skill filtering occurs.

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

Extends the `context: fork` vs Task section above with a third pattern:

**Pattern: Agent preloads skills (`skills:` field)**
```yaml
# In agents/api-developer.md
skills:
  - api-conventions
  - error-handling-patterns
```
The agent's markdown body is the system prompt; skills provide domain knowledge preloaded into context. This is the **inverse** of `context: fork` — here the agent controls the system prompt, not the skill. Use when the agent needs domain knowledge from multiple skills without the overhead of discovering them.

## Plugin Caching: All Dependencies Must Be Self-Contained

Plugins installed from marketplaces are **copied** to `~/.claude/plugins/cache/`. After installation, path traversal (`../`) is blocked — references to files outside the plugin directory fail silently. Every dependency (skill-references, scripts, templates) must live inside the plugin directory.

- **Symlinks** are followed during the copy process, so they work for bundling external content. But symlinks only resolve during initial install — if the symlink target changes later, the cached copy stays stale until the plugin is updated.
- `${CLAUDE_PLUGIN_ROOT}` is the environment variable for plugin-relative paths. Use it in `hooks.json` and MCP configs — it resolves to the actual install location, not the source directory.
- The `--plugin-dir` flag bypasses caching (loads directly from disk), so path issues only surface after marketplace installation.

## Plugin `settings.json` Only Supports `agent` Key

Plugin `settings.json` can set a default agent (`"agent": "agent-name"`) but **cannot inject permission allow-patterns** for Bash, Read, Write, or Edit. Users must manually configure permissions (via `/permissions` or their own `settings.json`) for any tool access the plugin's skills need. Document required permissions in the plugin's README.

## Flatten Nested Namespace Directories in Plugins

When packaging skills from a nested directory structure (`git/create-pr/SKILL.md`) into a plugin whose name already provides namespace context (e.g., `acme-git`), flatten the subdirectory to avoid double-namespacing. Otherwise: `skills/git/create-pr/` → `/acme-git:git:create-pr` (redundant). Flattened: `skills/create-pr/` → `/acme-git:create-pr` (clean). **Verify empirically** — exact namespace resolution behavior with nested `skills/` subdirectories needs testing.

## `skills-ref validate` Rejects Claude Code Extensions

The Agent Skills spec validator ([`skills-ref`](https://github.com/agentskills/agentskills/tree/main/skills-ref)) only allows 6 fields: `name`, `description`, `license`, `allowed-tools`, `metadata`, `compatibility`. Claude Code extension fields (`disable-model-invocation`, `argument-hint`, `hooks`, `context`, `agent`, `model`, `user-invocable`) all produce "Unexpected fields" errors. This means **any skill using Claude Code-specific features will fail spec validation**.

For repos targeting Claude Code specifically, build a custom validator that understands the Claude Code superset. Don't depend on `skills-ref validate` — it's also v0.1.0, labeled "demonstration purposes only", not on PyPI, and no CI/CD for skill validation exists in the ecosystem yet (not in Anthropic's repos, agentskills org, or community repos).

## Cross-Platform Extension Field Handling

Claude Code extension frontmatter fields (`disable-model-invocation`, `argument-hint`, `hooks`, `context`, `agent`, `model`) **degrade gracefully** on all 8+ Agent Skills platforms (Feb 2026). Most platforms silently ignore unknown fields. VS Code warns (yellow underline, [issue #294520](https://github.com/microsoft/vscode/issues/294520)) against a fixed allowlist — workaround: `"files.associations": {"**/.claude/skills/**/SKILL.md": "markdown"}`. OpenCode explicitly documents "unknown frontmatter fields are ignored." No platform errors on or rejects skills with extension fields.

**Universal discovery path**: `.agents/skills/` is supported by all platforms. `~/.claude/skills/` is recognized by Claude Code, VS Code, Cursor, OpenCode — but NOT by Codex, Gemini CLI, or Roo Code.

## `$ARGUMENTS` Is the Most Portable Body Feature

`$ARGUMENTS` (and `$ARGUMENTS[N]`/`$N`) is supported by Claude Code, VS Code/Copilot, Cursor, Codex, and likely all Agent Skills tools — it's part of the standard's body substitution convention. Tool names (`Read`, `Edit`, `Task`, `AskUserQuestion`, etc.) are **NOT portable** — they differ across platforms. For cross-platform skills, use natural language instructions ("Read the file at...") instead of tool-specific directives ("Use the Read tool").

## `metadata.*` Namespace for Platform-Specific Config

SkillPort uses `metadata.skillport.*` in YAML frontmatter for platform-specific configuration while staying spec-compliant. This pattern avoids frontmatter pollution and is forward-compatible if platforms standardize on namespaced metadata. Example: `metadata: { skillport: { category: development, alwaysApply: true } }`. Note: no platform currently reads `metadata.*` for runtime behavior — it's documentation/tooling only.

## `compatibility` Field for Signaling Portability

The spec-standard `compatibility:` frontmatter field (max 500 chars) signals intended platform and runtime requirements. Zero runtime cost, recognized by multiple platforms. Good practice for skills with varying portability levels:
- Near-portable: `compatibility: Works with any Agent Skills-compatible tool. Requires git and gh CLI.`
- CC-specific: `compatibility: Requires Claude Code (uses subagent orchestration and interactive tools).`

## Cross-Refs

- `claude-authoring-skills.md` — skill design patterns
- `claude-code.md` — permission and platform mechanics
