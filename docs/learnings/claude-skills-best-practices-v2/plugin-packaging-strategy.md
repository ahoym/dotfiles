# Deep Research: Plugin Packaging Strategy

## Executive Summary

Converting this repo's 22-skill collection into distributable plugins is feasible and well-supported by Claude Code's plugin system. The key strategic decision is **monolithic vs modular**: one large plugin with everything, or multiple focused plugins by skill family. Research strongly recommends **modular plugins by namespace** (git, learnings, parallel-plan, etc.) for shareability, with a monolithic "full suite" option for personal use.

The plugin system is mature (v1.0.33+), supports all current skill features, and provides marketplace distribution, versioning, auto-updates, and team configuration. The main conversion challenges are: (1) resolving shared `skill-references/` dependencies, (2) handling permission requirements without injecting settings, and (3) deciding what to exclude (learnings, guidelines, persona files).

---

## 1. Plugin System Architecture (Summary)

### What a Plugin Is

A plugin is a self-contained directory with a `.claude-plugin/plugin.json` manifest and component directories at the root level. Components include skills, commands, agents, hooks, MCP servers, LSP servers, and settings.

### Directory Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Manifest (only file in this dir)
├── commands/                # Legacy skill location (still works)
├── skills/                  # Recommended skill location
│   └── skill-name/
│       ├── SKILL.md
│       └── supporting-files
├── agents/                  # Custom agent definitions
├── hooks/
│   └── hooks.json           # Event handlers
├── settings.json            # Default settings (only `agent` key supported currently)
├── .mcp.json                # MCP server configs
├── .lsp.json                # LSP server configs
├── scripts/                 # Shared utility scripts
├── LICENSE
├── README.md
└── CHANGELOG.md
```

### Key Constraints

| Constraint | Impact |
|-----------|--------|
| Skills namespaced as `plugin-name:skill-name` | All invocations become longer (`/git-tools:create-pr` vs `/git:create-pr`) |
| Plugins copied to `~/.claude/plugins/cache/` on install | Cannot reference files outside plugin directory (use symlinks if needed) |
| `settings.json` only supports `agent` key | Cannot inject permission allow-patterns; users must configure manually |
| No path traversal (`../`) allowed after install | All dependencies must be within plugin directory |
| Plugin priority is lowest (enterprise > personal > project > plugin) | Personal skills override plugin skills with same name |

### Plugin Manifest Schema

```json
{
  "name": "plugin-name",           // Required. Kebab-case, no spaces. Becomes namespace prefix.
  "version": "1.0.0",              // Semantic versioning
  "description": "Brief description",
  "author": {
    "name": "Author Name",
    "email": "email@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/path.md"],  // Optional custom paths (supplement defaults)
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "lspServers": "./.lsp.json"
}
```

---

## 2. Packaging Strategy Options

### Option A: Monolithic Plugin (All 22 Skills)

```
mahoy-claude-skills/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── git/
│   │   ├── address-pr-review/
│   │   ├── cascade-rebase/
│   │   ├── create-pr/
│   │   ├── explore-pr/
│   │   ├── monitor-pr-comments/
│   │   ├── prune-merged/
│   │   ├── repoint-branch/
│   │   ├── resolve-conflicts/
│   │   └── split-pr/
│   ├── learnings/
│   │   ├── compound/
│   │   ├── consolidate/
│   │   ├── curate/
│   │   └── distribute/
│   ├── parallel-plan/
│   │   ├── execute/
│   │   └── make/
│   ├── ralph/
│   │   ├── compare/
│   │   └── init/
│   ├── do-refactor-code/
│   ├── do-security-audit/
│   ├── explore-repo/
│   ├── quantum-tunnel-claudes/
│   └── set-persona/
├── skill-references/           # Bundled shared references
├── scripts/                    # Shared scripts
├── README.md
├── LICENSE
└── CHANGELOG.md
```

**Pros:**
- Simplest conversion (mirror existing structure)
- All cross-skill references resolve naturally
- Single install gets everything
- `skill-references/` lives inside plugin (no external deps)

**Cons:**
- Users get everything or nothing (no selective install)
- Namespace prefix applies to ALL skills (`/mahoy:git:create-pr`)
- Large payload (~100+ files)
- Some skills are very personal (quantum-tunnel-claudes, set-persona)

### Option B: Modular Plugins by Namespace (Recommended)

Split into focused plugins by skill family:

| Plugin Name | Skills | Shared Deps |
|-------------|--------|-------------|
| `mahoy-git-skills` | 9 git skills | platform-detection.md |
| `mahoy-learnings` | 4 learnings skills | corpus-cross-reference.md |
| `mahoy-parallel-plan` | 2 parallel-plan skills | agent-prompting.md, code-quality-checklist.md |
| `mahoy-explore-tools` | explore-repo, do-refactor-code, do-security-audit | code-quality-checklist.md |
| `mahoy-ralph` | 2 ralph skills | (self-contained) |

**Pros:**
- Users install what they need
- Shorter namespace prefixes per domain (`/mahoy-git:create-pr`)
- Easier to version and update independently
- Can open-source popular ones (git) while keeping personal ones private

**Cons:**
- Must duplicate shared references into each plugin (or symlink)
- Cross-plugin skill references break (`/learnings:compound` from within git skills)
- More manifests to maintain
- Dependency management between plugins not supported

### Option C: Hybrid (Monolithic + Modular Extracts)

Maintain the monolithic plugin as the "full suite" for personal use, and extract popular skill families as standalone plugins for sharing.

```
Repos:
1. mahoy-claude-skills/        (monolithic, personal)
2. mahoy-git-skills/           (extracted, shareable)
3. mahoy-parallel-plan/        (extracted, shareable)
```

**Pros:**
- Best of both worlds
- Personal use retains all cross-references
- Shared plugins are self-contained
- Can evolve independently

**Cons:**
- Maintenance burden of multiple repos
- Risk of drift between monolithic and extracted versions

### Recommendation: Option B (Modular) for distribution, Option A for personal use

The user's stated intent is to **share skills publicly**. Option B maximizes shareability. For personal use, the existing `~/.claude/commands/` structure already works perfectly — no plugin needed.

---

## 3. Shared Dependency Resolution

### The Problem

9 skills reference files in `~/.claude/skill-references/`:

| Shared File | Used By |
|-------------|---------|
| `platform-detection.md` | 5+ git skills |
| `code-quality-checklist.md` | do-refactor-code, parallel-plan:execute |
| `agent-prompting.md` | parallel-plan:make, parallel-plan:execute |
| `corpus-cross-reference.md` | learnings:curate, quantum-tunnel-claudes |
| `subagent-patterns.md` | multi-agent skills |

### Resolution Strategies

**Strategy 1: Bundle into each plugin** (Recommended for modular approach)

Each plugin includes the shared references it needs:

```
mahoy-git-skills/
├── skills/
│   └── create-pr/
│       └── SKILL.md (references ../../../skill-references/platform-detection.md)
└── skill-references/
    └── platform-detection.md
```

Update SKILL.md references to use relative paths within the plugin. The `{baseDir}` variable resolves to the skill's directory, so references would use `{baseDir}/../../skill-references/platform-detection.md` or similar.

**Strategy 2: Inline small references**

For small reference files (<30 lines), inline the content directly into SKILL.md. This eliminates the dependency entirely.

**Strategy 3: Symlinks** (for monolithic only)

Plugin caching follows symlinks during copy. A monolithic plugin could symlink to shared references. However, this only works for local development — symlinks break when the plugin is distributed via marketplace.

### Recommended Approach

- For **modular plugins**: Bundle copies of required shared references into each plugin's directory. Accept the duplication — it's small (~5 files, <50KB total) and ensures each plugin is self-contained.
- For **monolithic plugin**: Keep shared references in a top-level `skill-references/` directory. Update paths in SKILL.md files to use plugin-relative paths.

### Cross-Skill Reference Resolution

Some skills reference other skills by name (e.g., "Use `/learnings:compound` after..."). In a plugin context:

- **Within same plugin**: References become `/plugin-name:learnings:compound` — works naturally
- **Across plugins**: References break. A git skill saying "Run `/learnings:compound`" won't work if learnings is in a different plugin.
- **Mitigation**: Update cross-references to be plugin-aware or remove them. Most are just "Related Skills" suggestions, not hard dependencies.

---

## 4. Marketplace Distribution

### Marketplace Structure

```
mahoy-plugin-marketplace/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── mahoy-git-skills/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/
│   │   └── skill-references/
│   ├── mahoy-learnings/
│   │   └── ...
│   └── mahoy-parallel-plan/
│       └── ...
├── README.md
└── LICENSE
```

### marketplace.json

```json
{
  "name": "mahoy-skills",
  "owner": {
    "name": "Malcolm Ahoy",
    "email": "..."
  },
  "metadata": {
    "description": "Production-tested Claude Code skill collections for git workflows, knowledge management, and parallel execution",
    "version": "1.0.0",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "mahoy-git-skills",
      "source": "mahoy-git-skills",
      "description": "9 git workflow skills: PR creation, review, conflict resolution, branch management, and more",
      "version": "1.0.0",
      "keywords": ["git", "github", "pr", "code-review"],
      "category": "development"
    },
    {
      "name": "mahoy-learnings",
      "source": "mahoy-learnings",
      "description": "Knowledge management skills: capture, curate, consolidate, and distribute learnings",
      "version": "1.0.0",
      "keywords": ["knowledge", "learnings", "documentation"],
      "category": "productivity"
    },
    {
      "name": "mahoy-parallel-plan",
      "source": "mahoy-parallel-plan",
      "description": "Parallel execution planning: analyze sequential plans for parallelization and execute with DAG scheduling",
      "version": "1.0.0",
      "keywords": ["parallel", "planning", "execution"],
      "category": "productivity"
    }
  ]
}
```

### Hosting Options

| Option | Command | Best For |
|--------|---------|----------|
| GitHub (recommended) | `/plugin marketplace add ahoym/mahoy-skills` | Public sharing, versioning, issues |
| Git URL | `/plugin marketplace add https://gitlab.com/...` | GitLab users |
| Local path | `/plugin marketplace add ./path` | Development/testing |

### Installation Flow (User Experience)

```bash
# 1. Add marketplace
/plugin marketplace add ahoym/mahoy-skills

# 2. Browse available plugins
/plugin  # → Discover tab

# 3. Install specific plugin
/plugin install mahoy-git-skills@mahoy-skills

# 4. Use skills (namespaced)
/mahoy-git-skills:create-pr
/mahoy-git-skills:address-pr-review 123
```

### Version Management

- Set version in `plugin.json` (takes precedence over marketplace entry)
- Use semantic versioning: `MAJOR.MINOR.PATCH`
- Bump version for every change — Claude Code caches by version
- Document changes in CHANGELOG.md

---

## 5. Permission Handling

### The Problem

Plugin `settings.json` currently only supports the `agent` key. Plugins **cannot inject permission allow-patterns**. Skills that run Bash commands (git, gh, scripts) require users to manually configure permissions.

### Solution: Documentation + Recommended Settings

Include a `README.md` with required permissions:

```markdown
## Required Permissions

After installing, add these to your settings (via `/permissions` or settings.json):

### mahoy-git-skills
- `Bash(git *)` — Git operations
- `Bash(gh pr *)`, `Bash(gh api *)` — GitHub CLI
- `Bash(chmod +x *)` — Script permissions

### mahoy-parallel-plan
- `Bash(git *)` — Git context
- Task tool access (default allowed)
```

### Future: Plugin-Scoped Permissions

The `allowed-tools` field in skill frontmatter is experimental but not yet enforced ([#18837](https://github.com/anthropics/claude-code/issues/18837)). When fixed, this becomes the proper way to declare tool needs per-skill. Add `allowed-tools` now for documentation, even without enforcement.

---

## 6. What to Include vs Exclude

### Include in Plugins

| Content | Rationale |
|---------|-----------|
| All 22 SKILL.md files | Core value proposition |
| Supporting files (templates, scripts, references) | Required for skill operation |
| Shared skill-references used by bundled skills | Dependency resolution |
| README.md per plugin | Installation and usage docs |
| LICENSE | Legal clarity for distribution |
| CHANGELOG.md | Version tracking |

### Exclude from Plugins

| Content | Rationale |
|---------|-----------|
| `~/.claude/learnings/` (25 knowledge files) | Too personal/project-specific; bloats plugin |
| `~/.claude/guidelines/communication.md` | Personal communication preferences |
| `settings.json` / `settings.local.json` | Permission config is user-specific |
| `CLAUDE.md` | Root config is project-specific |
| `quantum-tunnel-claudes/` | Sync mechanism — only useful for this repo's author |
| `set-persona/` persona files | Very personal (domain-specific identities) |
| `lab/ralph/wiggum.sh` | Experimental automation script |

### Borderline Decisions

| Content | Include? | Reasoning |
|---------|----------|-----------|
| `ralph/` skills | Maybe | Useful pattern but very opinionated. Could be separate plugin. |
| `set-persona/` | No | Persona definitions are deeply personal. Template could be shared. |
| `quantum-tunnel-claudes/` | No | Only works with the author's sync-source setup |
| `do-security-audit/` | Yes | Broadly useful, self-contained |
| `explore-repo/` | Yes | Broadly useful, self-contained |

---

## 7. Conversion Steps

### Phase 1: Prepare Skills for Plugin Compatibility

Before packaging, ensure skills work when:
1. Invoked with namespace prefix (`/plugin-name:skill-name`)
2. Installed in `~/.claude/plugins/cache/` (not `~/.claude/commands/`)
3. References resolve within plugin directory (no `~/.claude/` paths)

**Key changes needed:**
- Update `skill-references/` paths in SKILL.md from absolute (`~/.claude/skill-references/platform-detection.md`) to relative (`../../skill-references/platform-detection.md` or similar)
- Update cross-skill references from `/learnings:compound` to documentation-only mentions
- Bundle all scripts within skill directories (no external script deps)
- Add `name` field to all SKILL.md frontmatter (already planned in Phase 1D)

### Phase 2: Create Plugin Structure

For each plugin:
1. Create directory with `.claude-plugin/plugin.json`
2. Copy relevant skills into `skills/` (or `commands/`) directory
3. Copy required shared references into plugin directory
4. Add README.md with usage, permissions, and examples
5. Add LICENSE file

### Phase 3: Create Marketplace

1. Create marketplace repo (e.g., `ahoym/mahoy-skills`)
2. Create `.claude-plugin/marketplace.json` with all plugins listed
3. Add each plugin as a subdirectory (relative source)
4. Test locally: `/plugin marketplace add ./mahoy-skills`
5. Push to GitHub

### Phase 4: Test and Validate

1. Test each plugin with `claude --plugin-dir ./plugin-name`
2. Verify all skills appear in `/` menu with correct namespace
3. Test skill invocations (both user and model)
4. Verify shared references load correctly
5. Test installation from marketplace
6. Verify no path resolution errors after cache copy

---

## 8. Naming Strategy

### Plugin Names

Plugin names become the namespace prefix. Keep them short but descriptive:

| Option | Invocation Example | Pros | Cons |
|--------|-------------------|------|------|
| `mahoy-git` | `/mahoy-git:create-pr` | Short, clear | Slightly longer than current |
| `git-workflow` | `/git-workflow:create-pr` | Descriptive | Generic, may conflict |
| `mah-git` | `/mah-git:create-pr` | Very short | Unclear abbreviation |

**Recommendation:** Use `mahoy-` prefix for brand consistency across all plugins.

### Skill Names Within Plugin

Skills keep their current names. The namespace is added automatically:
- `skills/create-pr/SKILL.md` → `/mahoy-git:create-pr`
- `skills/address-pr-review/SKILL.md` → `/mahoy-git:address-pr-review`

**Note:** Nested namespaces (`git/create-pr`) within a plugin create double-namespacing (`/mahoy-git:git:create-pr`). Flatten the structure:

```
# Current (in commands/)
git/create-pr/SKILL.md → /git:create-pr

# In plugin (flatten)
skills/create-pr/SKILL.md → /mahoy-git:create-pr
```

This means the git skills lose their `git/` subdirectory when packaged as a standalone git plugin — the plugin name already provides the namespace.

---

## 9. Hooks in Plugins

### Plugin Hook Configuration

Hooks in plugins go in `hooks/hooks.json` (not skill frontmatter):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/check-conflicts.sh"
          }
        ]
      }
    ]
  }
}
```

**Key:** Use `${CLAUDE_PLUGIN_ROOT}` for all script paths — this resolves to the actual install location after caching.

### Hook Candidates for Plugins

From [hooks-integration.md](./hooks-integration.md), the Tier 1 hooks identified for skill frontmatter can alternatively go in plugin `hooks.json`:

- `git/resolve-conflicts` → PostToolUse(Edit) conflict marker check
- `quantum-tunnel-claudes` → PostToolUse(Edit) section count check

For modular plugins, only include hooks relevant to that plugin's skills.

---

## 10. Agents in Plugins

### Plugin Agent Definitions

Plugins can bundle custom agents in `agents/`:

```
mahoy-git-skills/
├── agents/
│   └── pr-reviewer.md        # Custom agent for PR review tasks
├── skills/
│   └── address-pr-review/
│       └── SKILL.md           # References pr-reviewer agent
```

From [subagent-configuration-patterns.md](./subagent-configuration-patterns.md), the `pr-reviewer` agent (Phase 4C.1) is a natural fit for the git skills plugin. It provides `memory: user` for persistent learning across PR reviews.

---

## 11. Comparison with Anthropic's Official Plugins

### Patterns from Official Plugins

Analyzed 13 official plugins in `anthropics/claude-code/plugins/`:

| Pattern | Official Usage | Our Adoption |
|---------|---------------|-------------|
| Commands + Skills mixed | Yes (commit-commands, feature-dev) | Use `skills/` only for new; `commands/` for migration |
| Custom agents | Yes (code-review: 5 agents, feature-dev: 3 agents) | Add pr-reviewer for git plugin |
| Hooks | Yes (security-guidance, explanatory-output-style) | Add conflict-check hook to git plugin |
| MCP servers | No (in demo plugins) | Not needed |
| `disable-model-invocation: true` | Yes (commit-commands, hookify) | Already planned for 4 skills |
| README.md | All have it | Required for every plugin |
| `settings.json` with `agent` | Yes (feature-dev) | Could use for git plugin with pr-reviewer |

### Key Takeaway

Official plugins are **focused** (2-9 skills each) with **clear single purpose** (code review, commit workflows, feature development). This validates the **modular approach** over monolithic.

---

## 12. Proposed Plugin Breakdown

### Tier 1: High shareability (create first)

#### `mahoy-git` (9 skills)
```
mahoy-git/
├── .claude-plugin/plugin.json
├── skills/
│   ├── create-pr/
│   ├── address-pr-review/
│   ├── explore-pr/
│   ├── monitor-pr-comments/
│   ├── resolve-conflicts/
│   ├── cascade-rebase/
│   ├── repoint-branch/
│   ├── split-pr/
│   └── prune-merged/
├── agents/
│   └── pr-reviewer.md
├── hooks/
│   └── hooks.json              # Conflict marker check
├── skill-references/
│   └── platform-detection.md
├── README.md
├── LICENSE
└── CHANGELOG.md
```

#### `mahoy-parallel-plan` (2 skills)
```
mahoy-parallel-plan/
├── .claude-plugin/plugin.json
├── skills/
│   ├── make/
│   └── execute/
├── skill-references/
│   ├── agent-prompting.md
│   └── code-quality-checklist.md
├── README.md
└── LICENSE
```

### Tier 2: Medium shareability

#### `mahoy-explore` (3 skills)
```
mahoy-explore/
├── .claude-plugin/plugin.json
├── skills/
│   ├── explore-repo/
│   ├── do-refactor-code/
│   └── do-security-audit/
├── skill-references/
│   └── code-quality-checklist.md
├── README.md
└── LICENSE
```

#### `mahoy-learnings` (4 skills)
```
mahoy-learnings/
├── .claude-plugin/plugin.json
├── skills/
│   ├── compound/
│   ├── consolidate/
│   ├── curate/
│   └── distribute/
├── skill-references/
│   └── corpus-cross-reference.md
├── README.md
└── LICENSE
```

### Tier 3: Low shareability (keep personal)

- `ralph/` — Very opinionated research loop pattern
- `quantum-tunnel-claudes/` — Author-specific sync mechanism
- `set-persona/` — Personal domain identities

---

## 13. Open Questions

1. **Plugin name prefix**: Should all plugins use `mahoy-` prefix, or something shorter/different?
2. **License choice**: MIT? Apache-2.0? Affects how others can use/modify.
3. **Marketplace repo name**: `ahoym/mahoy-skills`? `ahoym/claude-plugins`? `ahoym/mahoy-claude-stuff`?
4. **Include ralph as a plugin?**: The research loop pattern is useful but opinionated. Separate plugin or exclude?
5. **Skill-references duplication**: Accept duplication across plugins, or maintain a separate "shared" plugin?
6. **`commands/` vs `skills/` in plugins**: Should the conversion also rename from `commands/` to `skills/`? (Functionally equivalent, but `skills/` is recommended for new work.)
7. **Flatten nested namespaces?**: Should `git/create-pr` become just `create-pr` inside the git plugin (avoiding `/mahoy-git:git:create-pr`)?

---

## 14. Impact on Implementation Plan

### New Phase Needed: Plugin Packaging (Phase 6)

This research should add a new phase after Phase 5:

```
Phase 6: Plugin Packaging & Distribution
  6A: Prepare skills for plugin compatibility (path updates, ref resolution)
  6B: Create plugin directory structures (Tier 1 first)
  6C: Create marketplace repo and marketplace.json
  6D: Test plugins locally (--plugin-dir)
  6E: Publish to GitHub marketplace
  6F: Document installation and usage per plugin
```

### Dependencies on Existing Phases

- **Phase 1D** (add `name` field) should be done first — plugins benefit from explicit names
- **Phase 3C** (dynamic context injection) should be done first — injections should be tested before packaging
- **Phase 4B** (hooks) can be integrated directly into plugin `hooks.json`
- **Phase 4C** (agents) can be bundled into plugins from the start

---

## Sources

- [Claude Code Plugins docs](https://code.claude.com/docs/en/plugins) — Creating plugins
- [Claude Code Plugins reference](https://code.claude.com/docs/en/plugins-reference) — Complete technical spec
- [Claude Code Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) — Distribution
- [Claude Code Discover plugins](https://code.claude.com/docs/en/discover-plugins) — Installation flow
- [Agent Skills Specification](https://agentskills.io/specification) — Open standard
- [Anthropic demo plugins](https://github.com/anthropics/claude-code/tree/main/plugins) — 13 official examples
- This repo's existing research: [subagent-configuration-patterns.md](./subagent-configuration-patterns.md), [hooks-integration.md](./hooks-integration.md), [skill-testing-validation.md](./skill-testing-validation.md)
