# Claude Skills Best Practices — Research Findings

## Executive Summary

Claude Code skills are Markdown files with YAML frontmatter that extend Claude's capabilities. They follow the [Agent Skills](https://agentskills.io) open standard (cross-platform: Cursor, Gemini CLI, VS Code, Roo Code, etc.) and add Claude Code-specific extensions (invocation control, subagent execution, dynamic context injection, hooks). This document synthesizes official documentation, the open standard specification, and empirical patterns from this repo's 22+ production skills.

---

## 1. Skill Architecture

### What Skills Are

A skill is a directory with a `SKILL.md` entrypoint containing YAML frontmatter (metadata) and Markdown body (instructions). Skills teach Claude how to perform tasks, apply domain knowledge, or follow workflows. They operate on a **progressive disclosure** model:

| Tier | Content | Token Cost | Budget |
|------|---------|------------|--------|
| **Metadata** | name + description | Always loaded (~100 tokens) | 2% of context window (~16K chars fallback) |
| **SKILL.md body** | Full instructions | On invocation | <5K words recommended, <500 lines |
| **Bundled resources** | scripts/, references/, assets/ | On demand | Unlimited |

### Directory Structure

```
skill-name/
├── SKILL.md           # Required entrypoint
├── reference.md       # Loaded into context when needed (token cost)
├── examples/
│   └── sample.md      # Example output
└── scripts/
    └── helper.py      # Executed, not loaded (zero token cost)
```

### Where Skills Live (Priority Order)

| Location | Path | Applies To | Priority |
|----------|------|------------|----------|
| Enterprise | Managed settings | All org users | Highest |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects | High |
| Project | `.claude/skills/<name>/SKILL.md` | This project only | Medium |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled | Lowest |

**Key facts:**
- `commands/` and `skills/` directories are **fully feature-equivalent** — same frontmatter, same features. Skills in `commands/` still work; `skills/` is the recommended convention going forward.
- When a skill and command share the same name, the skill takes precedence.
- Nested `.claude/skills/` directories are auto-discovered (monorepo support).
- Skills from `--add-dir` directories get live change detection (hot-reload).

---

## 2. Frontmatter Reference

### Agent Skills Open Standard Fields

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes (spec) / No (Claude Code) | Max 64 chars, lowercase + hyphens only. No consecutive hyphens, no start/end with hyphen. Must match directory name. Must NOT contain "claude" or "anthropic". |
| `description` | Recommended | Max 1,024 chars. No XML angle brackets (`<` or `>`). Should describe what AND when to use. |
| `license` | No | License name or bundled file reference. |
| `compatibility` | No | Max 500 chars. Environment requirements. |
| `metadata` | No | Arbitrary key-value mapping. |
| `allowed-tools` | No (Experimental) | Space-delimited or comma-delimited tool list. |

### Claude Code Extensions

| Field | Description |
|-------|-------------|
| `argument-hint` | Autocomplete hint (e.g., `[issue-number]`). |
| `disable-model-invocation` | `true` = only user can invoke via `/name`. Also **removes skill from context entirely** — Claude won't know it exists until invoked. Saves context budget. |
| `user-invocable` | `false` = hidden from `/` menu. Only Claude can invoke. Description still in context. |
| `model` | Override session model per skill (e.g., `haiku`, `sonnet`, `opus`). |
| `context` | `fork` = run in isolated subagent. Skill content becomes the subagent's prompt. No conversation history. |
| `agent` | Which subagent type when `context: fork` (e.g., `Explore`, `Plan`, `general-purpose`, or custom from `.claude/agents/`). |
| `hooks` | Lifecycle hooks scoped to this skill (PreToolUse, PostToolUse, Stop). |

### Invocation Matrix

| Frontmatter | User Can Invoke | Claude Can Invoke | Description in Context |
|-------------|----------------|-------------------|----------------------|
| (default) | Yes | Yes | Yes |
| `disable-model-invocation: true` | Yes | No | **No** |
| `user-invocable: false` | No | Yes | Yes |

---

## 3. Skill Content Patterns

### Two Types of Skill Content

**Reference content** — Knowledge Claude applies to current work (conventions, patterns, style guides). Runs inline alongside conversation context.

```yaml
---
name: api-conventions
description: API design patterns for this codebase
---
When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
```

**Task content** — Step-by-step instructions for a specific action. Often `disable-model-invocation: true` since you want to control timing.

```yaml
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
---
Deploy the application:
1. Run the test suite
2. Build the application
3. Push to the deployment target
```

### String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking |
| `$ARGUMENTS[N]` / `$N` | Specific argument by 0-based index |
| `${CLAUDE_SESSION_ID}` | Current session ID |

If `$ARGUMENTS` is absent from content, arguments are appended as `ARGUMENTS: <value>`.

### Dynamic Context Injection (Preprocessing)

The `` !`command` `` syntax runs shell commands before the prompt reaches Claude:

```markdown
- Current branch: !`git branch --show-current`
- PR diff: !`gh pr diff`
```

Output replaces the placeholder. Claude only sees the final rendered content.

### Extended Thinking

Include the word "ultrathink" anywhere in skill content to enable extended thinking mode.

---

## 4. Advanced Patterns

### `context: fork` (Subagent Execution)

Runs the entire skill as an isolated subagent. Critical constraints:

1. **No conversation history** — operates from skill content + `$ARGUMENTS` only
2. **No subagent nesting** — forked skills cannot spawn Task subagents
3. **No mid-task interaction** — no AskUserQuestion or confirmations
4. **Must be task-based** — needs actionable instructions, not just guidelines
5. **Output is a deliverable** — produces a summary/report returned to main conversation

**Viability checklist** — ALL must be true:
- [ ] No internal subagent spawning (no Task tool usage)
- [ ] No conversation history dependency
- [ ] No mid-task user interaction
- [ ] Task-based, not reference-based
- [ ] Output is a deliverable

**Choose `context: fork` when:** Entire skill is a pure function (args in, report out).
**Choose Task subagents when:** Skill needs to coordinate, interact, or delegate.

### Skill ↔ Subagent Relationship

| Approach | System Prompt | Task | Also Loads |
|----------|--------------|------|------------|
| Skill with `context: fork` | From agent type | SKILL.md content | CLAUDE.md |
| Subagent with `skills` field | Subagent's markdown body | Claude's delegation message | Preloaded skills + CLAUDE.md |

### `allowed-tools` — Current State

**Currently broken:** restriction not enforced ([#18837](https://github.com/anthropics/claude-code/issues/18837) closed as dup of [#14956](https://github.com/anthropics/claude-code/issues/14956) which remains open), Bash auto-approval broken, SDK ignores the field entirely ([#18737](https://github.com/anthropics/claude-code/issues/18737)), piped commands bypass restrictions ([#1271](https://github.com/anthropics/claude-code/issues/1271)). Marked "Experimental" in Agent Skills spec. Anthropic's own 16 reference skills don't use it; Trail of Bits does (security focus, YAML list syntax, 4+ skills). **Recommended: add now as intent-signaling on 13/22 skills** — documents design intent, prepares for enforcement, zero risk while unenforced. See [allowed-tools-adoption.md](./allowed-tools-adoption.md) for per-skill tool lists.

### Hooks in Skills

Skills can define lifecycle hooks in frontmatter:

```yaml
---
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
---
```

`Stop` hooks in skill frontmatter are auto-converted to `SubagentStop` events.

### Generating Visual Output

Skills can bundle scripts (Python, etc.) that generate interactive HTML, dependency graphs, test coverage reports, etc. The script does heavy lifting; Claude handles orchestration. Pattern: `allowed-tools: Bash(python *)` + bundled script.

---

## 5. Distribution & Sharing

| Method | Scope | Mechanism |
|--------|-------|-----------|
| Project skills | Team | Commit `.claude/skills/` to VCS |
| Plugins | Community | Plugin marketplace with namespaced `/plugin:skill` |
| Managed settings | Organization | Enterprise deployment |
| Personal | Individual | `~/.claude/skills/` |

**Plugin namespacing:** Plugin skills use `plugin-name:skill-name` to avoid conflicts. Standalone skills use short names like `/review`.

---

## 6. Patterns from This Repo's 22+ Skills

### Skill Template (Standardized Structure)

```markdown
---
description: One-line description of what the skill does
---

# Skill Name

One-line description.

## Usage
- `/skill-name` - Default behavior
- `/skill-name <arg>` - With argument

## Reference Files (conditional — read only when needed)
- reference-file.md - Description of what it contains

## Instructions
1. **Step name**:
   - Explanation

## Important Notes
- Caveats, warnings, edge cases
```

### Token Optimization Patterns

1. **Conditional references** (no `@` prefix) — file loaded on-demand via Read tool, not on every invocation. Only use `@` when file is <30 lines AND needed every time.
2. **`disable-model-invocation: true`** on manual-only skills — removes description from context entirely, saving budget.
3. **Extract reference files** when content is >10 lines and only needed situationally.
4. **SKILL.md under 500 lines** — move detailed reference to separate files.

### Naming Conventions

- Lowercase with hyphens: `/cascade-rebase`, `/pr-status`
- Verb-noun or noun-verb: `/split-commit`, `/resolve-conflicts`
- 2-3 words max
- Namespaced groups via directories: `git/create-pr`, `learnings/compound`

### Description Best Practices

1. **Clear functional description** — only add routing hints ("Use when...") if name + description isn't enough for agent inference.
2. **Remove internal jargon** — use widely understood terms.
3. **Add action keywords** — include verbs describing what happens.
4. **Include specific capabilities** for multi-purpose skills.

### Reference File Patterns

| Pattern | When to Use |
|---------|-------------|
| `@file.md` (eager) | <30 lines, needed every invocation |
| `file.md` (conditional) | >30 lines OR only needed in specific branches |
| `@~/.claude/skill-references/file.md` | Cross-skill shared reference |
| `{baseDir}/file.md` | Intra-skill reference (resolves to skill's directory) |

### Orchestrator/Agent Separation

For multi-step skills with background workflows:
1. **SKILL.md** — orchestrator, user interaction only (~80 lines)
2. **Separate .md** — background agent workflow (autonomous execution)

### Skill Composition

- **Cross-references** between related skills: "Use `/git:explore-pr` first if you need to understand the PR"
- **"Related Skills" section** for natural follow-ups
- **Shared reference files** in `~/.claude/skill-references/` for cross-cutting concerns (platform detection, agent prompting, etc.)

---

## 7. Content Type Decision Framework

| Type | Purpose | Location | Trigger |
|------|---------|----------|---------|
| **Skill** | Actionable, repeatable task | `.claude/commands/` or `.claude/skills/` | Multi-step procedures via `/skill-name` |
| **Guideline** | Rules that shape behavior | `.claude/guidelines/` | Always-on via `@` in CLAUDE.md |
| **Learning** | Reference knowledge | `~/.claude/learnings/` | Ad-hoc discovery or conditional loading |

**Quick decision tree:**
1. Can it be invoked as a command with clear steps? → **Skill**
2. Does it change how to behave/approach tasks? → **Guideline**
3. Is it useful reference info (patterns, examples, gotchas)? → **Learning**

---

## 8. Common Pitfalls

1. **Stale path references** — skills referencing specific file paths break when files move. Verify every path in SKILL.md resolves. Use `Read` (not `Glob`) to verify paths through symlinks.
2. **Context budget overflow** — many skills with verbose descriptions exceed the 2% budget. Skills get silently excluded. Check with `/context`.
3. **`allowed-tools` enforcement gap** — feature exists but isn't enforced at runtime. Don't rely on it for security.
4. **`context: fork` + Task incompatibility** — forked skills can't spawn subagents. Skills that orchestrate workers must stay inline.
5. **Eagerly loaded references** — `@file.md` loads on every invocation. Use conditional references for files >30 lines or only sometimes needed.
6. **Permission drift** — skills needing Bash commands require matching allow patterns in settings. Uncommitted permissions may not persist.

---

## Areas for Deeper Investigation

1. ~~Subagent configuration patterns~~ → See [subagent-configuration-patterns.md](./subagent-configuration-patterns.md)
2. ~~Plugin packaging~~ → See [plugin-packaging-strategy.md](./plugin-packaging-strategy.md) — **Modular approach recommended** (by namespace). Full manifest, marketplace, and naming strategy documented. 7 open questions for user input.
3. ~~Skill context budget optimization~~ → See [skill-context-budget.md](./skill-context-budget.md) — **Key finding: only 31% budget utilization, no skills excluded, ~52-skill headroom**
~~`allowed-tools` adoption strategy~~ → See [allowed-tools-adoption.md](./allowed-tools-adoption.md) — **13/22 skills recommended for adoption (5 read-only Tier 1, 8 narrowly-scoped Tier 2). Add now as intent-signaling; enforce when #14956 is fixed. YAML list syntax recommended (Trail of Bits pattern). 9 orchestrator skills skipped (Tier 3).**
5. ~~Dynamic context injection (`!` syntax)~~ → See [dynamic-context-injection.md](./dynamic-context-injection.md)
6. ~~Agent Skills cross-platform compatibility~~ → See [cross-platform-compatibility.md](./cross-platform-compatibility.md) — **Frontmatter maximally portable (description-only), body low portability (CC-specific tools). 8+ platforms adopt the standard. 3 skills near-portable, 10 moderate, 9 deeply coupled. All planned frontmatter additions degrade gracefully. Recommended: add `compatibility` field to signal portability tier.**
7. ~~Hooks integration with skills~~ → See [hooks-integration.md](./hooks-integration.md)
8. ~~Skill testing and validation~~ → See [skill-testing-validation.md](./skill-testing-validation.md)
9. ~~Agent teams vs subagent skills~~ → Covered in [subagent-configuration-patterns.md](./subagent-configuration-patterns.md) §8

---

## Sources

- [Claude Code Skills docs](https://code.claude.com/docs/en/skills) — Official reference (Feb 2026)
- [Claude Code Sub-agents docs](https://code.claude.com/docs/en/sub-agents) — Subagent configuration
- [Claude Code Plugins docs](https://code.claude.com/docs/en/plugins) — Plugin structure and distribution
- [Claude Code Hooks docs](https://code.claude.com/docs/en/hooks) — Hook events and configuration
- [Agent Skills Specification](https://agentskills.io/specification) — Open standard spec
- [Anthropic's Skills Guide (PDF)](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf) — PDF was not parseable; field constraints cited from existing repo learnings
- This repo: `~/.claude/learnings/skill-design.md`, `~/.claude/commands/learnings/compound/skill-authoring.md`, `~/.claude/commands/learnings/compound/writing-best-practices.md`
