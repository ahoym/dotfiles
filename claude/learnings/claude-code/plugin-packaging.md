Plugin packaging and distribution — caching, settings limitations, namespace conventions, and cross-platform compatibility.
- **Keywords:** plugin, marketplace, cache, ~/.claude/plugins/, settings.json, namespace, flatten, skills-ref, Agent Skills spec, $ARGUMENTS, metadata, compatibility field, cross-platform
- **Related:** ~/.claude/learnings/claude-authoring/skill-platform-unification.md

---

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

The Agent Skills spec validator ([`skills-ref`](https://github.com/agentskills/agentskills/tree/main/skills-ref)) only allows 6 fields: `name`, `description`, `license`, `allowed-tools`, `metadata`, `compatibility`. Claude Code extension fields (`disable-model-invocation`, `argument-hint`, `hooks`, `context`, `agent`, `model`, `user-invocable`) all produce "Unexpected fields" errors.

For repos targeting Claude Code specifically, build a custom validator that understands the Claude Code superset. Don't depend on `skills-ref validate` — it's also v0.1.0, labeled "demonstration purposes only", not on PyPI, and no CI/CD for skill validation exists in the ecosystem yet.

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

- `~/.claude/learnings/claude-authoring/skill-platform-unification.md` — skill design patterns
