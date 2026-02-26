# Skill Design Patterns

## Compose Skills, Don't Couple Them

When two skills share setup (e.g., locating a project, reading files) but diverge in purpose (one exploratory, one operational), keep them separate and composable. Duplicate the shared setup in each skill (~10 lines of instructions is fine) rather than making one depend on the other. Add a hint in the operational skill pointing to the exploratory one for users who need context first. Example: `/ralph:resume` mentions `/ralph:brief` but doesn't invoke it — the user composes them when needed.

## Merging Diverged Skills Across Repos

When two repos have independently evolved the same skill, merge by keeping unique features from both sides. Use the more complete version as the base, append unique sections from the other. For platform-specific commands (gh vs glab), parameterize via a shared reference file with detection logic and a mapping table. One codebase to maintain means no future drift.

## Skill Improvement: Fix and Assess In-Session

Apply skill improvements in the same session they surface — context fades across sessions. After running a skill, note what worked, what didn't, and prioritize: regression prevention >> efficiency; one-line fixes >> structural overhauls. Cap at 3-5 improvements. If a skill hits a bug mid-execution, fix immediately — scope to one constraint workaround per incident.

## AskUserQuestion Has a 4-Option Maximum

`AskUserQuestion` enforces `maxItems: 4` on the options array. This is a hard schema constraint — not configurable. Skills that present learnings, tasks, or choices to the user will fail at runtime if they try to offer >4 options.

**Workarounds (in order of preference):**
1. **Auto-save high-confidence items** — Remove them from the selection set entirely. Only prompt for uncertain items, which usually fit in 4 options.
2. **Group by theme** — Combine related items into a single option (e.g., "CI patterns (3 items)" instead of 3 separate options).
3. **Use free-text input** — Present a numbered table and let the user type "1,3,5" or "all" as a regular message instead of using the widget.
4. **Multi-round prompting** — Split into batches of 4, though this adds friction.

**Where this bites:** `/learnings:compound` when a session produces >4 learnings. The fix applied there: auto-save High-utility learnings (they're almost always worth keeping) and only prompt for Medium/Low.

## Preserve Reference Style During Migrations

When migrating file paths (e.g., relocating shared references), preserve each skill's original reference style rather than normalizing all references to a single style:

- If a skill used `@_shared/file.md` (auto-include directive), update to `@~/.claude/skill-reference/file.md`
- If a skill used `` `~/.claude/commands/.../file.md` `` (bare path in backticks), update to `` `~/.claude/skill-reference/file.md` ``

Adding `@` to files that previously used bare paths changes behavior (auto-include vs manual read instruction). Only update the path portion, not the reference mechanism.

## "LLM Knows X" ≠ "LLM Consistently Applies X"

When deciding whether to codify a pattern, the question isn't "can the model execute this when asked?" but "does it reliably do so unprompted?" Textbook patterns (extract class, DRY, factories) that the model knows but doesn't consistently apply during implementation still warrant codification — as a lightweight checklist reminder, not a tutorial. The correct form factor is a slim reference file (~15 lines) that reminds, not a 229-line reference file that teaches.

## Stale Path References Are the Primary Skill Maintenance Issue

Skills referencing specific file paths (`~/.claude/lab/script.sh`, `docs/learnings/topic.md`) go stale when files are moved, deleted, or renamed. In curation of 4 skills, 2 had broken path references. During curation, verify every file path in SKILL.md and reference files actually resolves. Paths to external scripts and cross-directory references are more fragile than paths within the skill's own directory.

**Symlink gotcha:** `~/.claude/` subdirectories are directory-level symlinks to the dotfiles repo. `Glob` doesn't reliably resolve paths through these symlinks — a file can exist but Glob reports "No files found." Always verify path existence with `Read` (which resolves symlinks correctly), not `Glob`.

## `commands/` and `skills/` Are Fully Feature-Equivalent

The official docs state both "work the same way" and "support the same frontmatter." Every feature works in `commands/` — no directory rename needed. Previously assumed `skills/`-exclusive features (monorepo auto-discovery, `--add-dir` hot-reload, plugin packaging) were confirmed to work in `commands/` too — via user testing (auto-discovery, hot-reload) and the [plugin docs](https://code.claude.com/docs/en/plugins) explicitly listing both directories. The only difference is naming convention.

## Unused Official Frontmatter Features

This repo's skills use only `description:` from SKILL.md frontmatter. Official features not yet adopted:

- **`allowed-tools`** — Scoped tool permissions active only during skill execution. **Currently broken** (restriction not enforced, SDK ignores the field, piped commands bypass — multiple open issues). **Recommended syntax: YAML list.** Use bare tool names (not scoped `Bash(git:*)`). Add for intent-signaling (see "Add Broken/Experimental Features" below); defer reliance on enforcement.
- **`context: fork` + `agent:`** — Run skill in isolated subagent. See "`context: fork` vs Task Subagents" section below.
- **`model:`** — Override session model per skill (e.g., `haiku` for simple tasks, `opus` for complex reasoning).
- **`disable-model-invocation: true`** — See "`disable-model-invocation` Removes Skill from Context" section below.
- **`{baseDir}`** — Resolves to skill's own installation directory (e.g., `~/.claude/commands/<skill>/`). Works for intra-skill references (scripts/, references/, assets/) but **cannot** replace `~/.claude/` for cross-directory references to `~/.claude/learnings/`, `~/.claude/skill-references/`, etc.

Gap identified comparing repo skills against official spec — none use these features.

## `disable-model-invocation` Removes Skill from Context

Setting `disable-model-invocation: true` does more than prevent auto-invocation — it **completely removes the skill's description from Claude's context**. This means Claude won't know the skill exists until manually invoked. Trade-off: saves context budget but loses auto-discovery. Use for skills that are only invoked explicitly (e.g., `/ralph:init`, `/learnings:consolidate`).

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

A good `!`command`` candidate must pass ALL five criteria:

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

## Track Assumptions with Confidence Levels in Iterative Research

When running multi-iteration research (ralph loops, deep dives), explicitly log assumptions with confidence ratings (High/Medium/Low) and a validation tracker table. This prevents later iterations from re-investigating settled questions or proceeding on shaky foundations. Format: assumption statement, confidence level, whether validated, and resolution. Cross-reference assumptions from the ID (A1, A2...) in other documents.

## Absence of Documentation ≠ Absence of Feature

When docs describe a feature only in the context of X (e.g., "auto-discovery works with `skills/`"), do NOT conclude that Y (e.g., `commands/`) lacks the feature. Silence is not exclusion. Require **explicit** evidence — a statement like "X does not support Y" — before claiming a capability difference. If the docs also contain a general equivalence statement (e.g., "both work the same way"), that should be the default position until contradicted.

**When asserting "X can't do Y":** actively search for evidence that X *can* do Y before committing to the claim. This is the adversarial/red-team step that catches false negatives.

## Broaden Primary Source Coverage in Research

Don't rely on a single doc page. When researching a feature area, traverse **related** official pages (e.g., researching skills? also read plugins, settings, reference docs). Key findings often live on adjacent pages — e.g., the plugin structure table that confirmed `commands/` support was on the plugins page, not the skills page.

## Validate Factual Claims About Runtime Behavior

Research that asserts capability differences (e.g., "directory X supports feature Y but directory Z doesn't") should be validated empirically when possible, not just inferred from docs. If the research loop constraints prevent code execution, flag the claim as **low-confidence/unverified** and note that empirical testing is needed before acting on it.

## Skill Field Constraints (from Anthropic's Official Guide)

- **`name`**: Max 64 characters, lowercase with hyphens. Must not contain "claude" or "anthropic".
- **`description`**: Max 1,024 characters. Must not contain XML angle brackets (`<` or `>`).
- **`dependencies`**: Declares skills this one requires (not yet observed in the wild).

Source: [The Complete Guide to Building Skills for Claude (PDF)](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)

## Skills Are Cross-Platform

Skills work across **Claude.ai, Claude Code, and the API** — same folder, no modification needed. Distribution varies by surface: ZIP upload (Claude.ai Settings > Capabilities > Skills), directory placement (`~/.claude/commands/` or `~/.claude/skills/`), `/v1/skills` REST endpoint (CI/CD), org-level workspace deployment (teams, shipped Dec 2025).

## Add Broken/Experimental Features for Intent-Signaling

When an official frontmatter feature exists but enforcement is broken (e.g., `allowed-tools` restriction not enforced), it can still be worth adding — as documentation of design intent, not runtime enforcement. Criteria: (1) adding it costs nothing (no behavioral change while broken), (2) it communicates the skill's intended tool surface to human readers, (3) it future-proofs for when enforcement is fixed. Only do this for features where the *intended* behavior matches your *actual* intent — don't add `allowed-tools: Read, Glob` if the skill legitimately needs Write sometimes.

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

## Skill-Scoped Hooks: Placement Decision Framework

Hooks can live in skill `hooks:` frontmatter (active only during skill execution) or in `settings.json` (active always). Choose placement based on scope:

**Skill frontmatter** — Use for invariants specific to one skill's workflow:
- Conflict marker detection after merge edits (`git/resolve-conflicts`)
- Section count verification after content sync (`quantum-tunnel-claudes`)

**Settings (project/user)** — Use for universal checks that apply to ALL file edits:
- Auto-format after Edit/Write (project settings)
- Secret file protection (user settings)
- CLAUDE.md section preservation (project settings)

**Decision rule**: If you'd need to copy the hook into 3+ skills, it belongs in settings.

### Hook Type Selection

Default to `command` hooks (shell scripts). Only escalate when shell logic can't express the check:
- **`command`** — Deterministic checks, <1s, zero token cost. `jq` + `grep` for most cases.
- **`prompt`** — Simple judgment calls, ~2-5s, ~1K tokens (Haiku default).
- **`agent`** — Complex verification needing tool access, ~10-60s, ~5-50K tokens.

See also: `~/.claude/learnings/claude-code-hooks.md` for PostToolUse limitations, stop hook looping, and other hooks mechanics.

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

## "Reduces Typing" Is Sufficient Justification for a Skill

Don't overthink whether a repeated sequence "deserves" to be a skill. If the user types the same N commands every session in the same order, a skill that runs them sequentially is a valid simplification — even if individual steps are conversational or already invoke other skills. The bar is consistency of the sequence, not complexity of the automation.

