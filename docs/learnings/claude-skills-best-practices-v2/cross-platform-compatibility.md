# Deep Research: Agent Skills Cross-Platform Compatibility

## Executive Summary

The Agent Skills standard (agentskills.io) has been adopted by **8+ platforms** as of Feb 2026: Claude Code, Cursor, VS Code/GitHub Copilot, OpenAI Codex, Gemini CLI, Roo Code, OpenCode, and SkillPort (meta-manager). This repo's 22 skills are **structurally portable** — all use description-only frontmatter (no Claude Code extensions in YAML) — but **behaviorally non-portable** because every skill's body references Claude Code-specific tools (`Task`, `AskUserQuestion`, `Read`, `Edit`, etc.) and patterns (`$ARGUMENTS`, `!`command``).

**Key finding**: Portability is a spectrum, not binary. 3 skills are near-portable today, ~10 could be made portable with moderate effort, and ~9 are deeply coupled to Claude Code's orchestration model and would require substantial rewrites.

---

## 1. Platform Adoption Matrix

| Platform | Status (Feb 2026) | Discovery Paths | Reads `~/.claude/skills/`? | Own Extension Fields |
|----------|-------------------|-----------------|---------------------------|---------------------|
| **Claude Code** | Stable | `.claude/skills/`, `~/.claude/skills/`, plugins | Yes (native) | `context`, `agent`, `model`, `hooks`, `disable-model-invocation`, `user-invocable`, `argument-hint` |
| **VS Code / Copilot** | Stable (v1.108+) | `.github/skills/`, `.claude/skills/`, `.agents/skills/`, `~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | Yes | `argument-hint`, `user-invokable` [sic], `disable-model-invocation` |
| **Cursor** | Nightly → Stable | `.agents/skills/`, `.cursor/skills/`, `~/.cursor/skills/`, `.claude/skills/`, `~/.claude/skills/` | Yes (compat) | `disable-model-invocation` |
| **OpenAI Codex** | Stable | `.agents/skills/`, `~/.agents/skills/`, `/etc/codex/skills/` | No | `agents/openai.yaml` sidecar (UI config, tool deps) |
| **Gemini CLI** | Stable (v0.23+) | `.gemini/skills/`, `.agents/skills/`, `~/.gemini/skills/`, `~/.agents/skills/` | No | Undocumented |
| **Roo Code** | Stable (v3.38+) | `.roo/skills/`, `.agents/skills/`, `~/.roo/skills/`, `~/.agents/skills/` | No | Mode-specific: `.roo/skills-{mode}/` |
| **OpenCode** | Stable | `.opencode/skills/`, `.claude/skills/`, `.agents/skills/`, `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | Yes | None documented |

### Universal Discovery Path

**`.agents/skills/`** is the cross-platform convention supported by all platforms. `~/.claude/skills/` is recognized by Claude Code, VS Code, Cursor, and OpenCode but not by Codex, Gemini CLI, or Roo Code.

---

## 2. Frontmatter Field Compatibility

### Standard Fields (Agent Skills Spec)

| Field | Required by Spec | Supported by All Platforms | Notes |
|-------|-----------------|---------------------------|-------|
| `name` | Yes | Yes | Must match directory name. Max 64 chars, lowercase + hyphens. |
| `description` | Yes | Yes | Max 1024 chars. Used for routing/activation decisions. |
| `license` | No | Varies | Recognized by Claude Code, OpenCode. Others: unknown. |
| `compatibility` | No | Varies | OpenCode uses it (`compatibility: opencode`). Others: unknown. |
| `metadata` | No | Varies | Arbitrary key-value map. SkillPort uses `metadata.skillport.*` namespace for extensions. |
| `allowed-tools` | No (Experimental) | Claude Code only (broken) | Not supported elsewhere. |

### Extension Field Handling by Platform

| Platform | Unknown Fields | Behavior |
|----------|---------------|----------|
| **Claude Code** | Silently ignored | Only reads fields it recognizes |
| **VS Code / Copilot** | **Warns** (yellow underline) | Fixed allowlist: `name`, `description`, `compatibility`, `license`, `metadata`. Extension fields (`context`, `model`, `agent`, `allowed-tools`, `argument-hint`) trigger "Attribute not supported" warning. [Open issue #294520](https://github.com/microsoft/vscode/issues/294520) |
| **Cursor** | Undocumented | Likely ignored (no reports of errors) |
| **OpenAI Codex** | Undocumented | Only `name` and `description` documented as frontmatter; extensions go in `agents/openai.yaml` sidecar |
| **Gemini CLI** | Undocumented | Minimal frontmatter docs; likely ignored |
| **Roo Code** | Undocumented | Only `name` and `description` documented |
| **OpenCode** | **Explicitly ignored** | Docs state: "Unknown frontmatter fields are ignored" |

### This Repo's Frontmatter Portability

**Current state: Maximally portable.** All 22 skills use only `description:` in frontmatter — the most universally supported field. No Claude Code extension fields are present in any YAML block.

**After implementation plan changes**: Phase 1 adds `name`, `disable-model-invocation`, `argument-hint`. Phase 4 adds `hooks`. Impact:

| Field to Add | Cross-Platform Impact |
|--------------|----------------------|
| `name` | **Improves portability** — required by spec, recognized everywhere |
| `description` | Already present — universal |
| `disable-model-invocation` | Supported by Claude Code, VS Code, Cursor. Ignored by Codex, Gemini, Roo, OpenCode. **Graceful degradation**: skills just load normally (no harm). |
| `argument-hint` | Supported by Claude Code, VS Code. Ignored by others. **Graceful degradation**: no hint shown (no harm). |
| `hooks` | **Claude Code only.** Ignored by all others. No harm (hooks just don't fire). |
| `model` | **Claude Code only.** Ignored by all others. No harm (default model used). |
| `context: fork` | **Claude Code only.** Other platforms have no fork/subagent concept for skills. Unknown behavior — could be ignored or cause errors. |
| `agent` | **Claude Code only.** Same concern as `context`. |

**Conclusion**: All planned frontmatter additions degrade gracefully except potentially `context` and `agent` (which the plan doesn't recommend for existing skills anyway).

---

## 3. Body Content Portability

This is where the real compatibility challenges lie. The SKILL.md body is platform-agnostic Markdown, but the *instructions* reference platform-specific tools and patterns.

### Tool Name Mapping

| Claude Code Tool | VS Code/Copilot | Cursor | Codex | Gemini CLI | Portable Alternative |
|-----------------|-----------------|--------|-------|------------|---------------------|
| `Read` | Varies | Varies | `read_file` | Varies | "Read the file at..." (natural language) |
| `Write` | Varies | Varies | `write_file` | Varies | "Create/write a file at..." |
| `Edit` | Varies | Varies | `apply_diff` | Varies | "Edit the file to change..." |
| `Glob` | N/A | N/A | N/A | N/A | "Find files matching..." |
| `Grep` | N/A | N/A | N/A | N/A | "Search for content in..." |
| `Bash` | Terminal | Terminal | Shell | Shell | "Run the command..." |
| `Task` (subagent) | **No equivalent** | **No equivalent** | **No equivalent** | **No equivalent** | None — this is unique to Claude Code |
| `AskUserQuestion` | **No equivalent** | **No equivalent** | **No equivalent** | **No equivalent** | None — platform-specific |
| `TodoWrite` | **No equivalent** | **No equivalent** | **No equivalent** | **No equivalent** | None — platform-specific |
| `EnterPlanMode` | **No equivalent** | **No equivalent** | **No equivalent** | **No equivalent** | None — platform-specific |

### Claude Code-Specific Patterns Used in This Repo

| Pattern | Skills Using | Portable? |
|---------|-------------|-----------|
| `$ARGUMENTS` | 16/22 | **Partially** — Codex, Cursor, Gemini CLI support argument passing, but syntax may differ |
| `!`command`` (dynamic injection) | 1/22 (ralph:init) | **Claude Code only** — preprocessing happens before prompt reaches model |
| `Task` (subagent spawning) | 4/22 | **Claude Code only** — no equivalent in other platforms |
| `AskUserQuestion` | 14/22 | **Claude Code only** — some platforms have implicit confirmation UIs but no explicit tool |
| Tool names as instructions | 22/22 | **Not portable** — tool names differ across platforms |
| `@file.md` (eager reference) | 2/22 | **Unclear** — reference loading semantics vary |
| Conditional reference reads | 20/22 | **Partially** — works if described in natural language rather than tool-specific syntax |
| Background execution (`run_in_background`) | 1/22 | **Claude Code only** |

### `$ARGUMENTS` Compatibility

The `$ARGUMENTS` variable is part of the Agent Skills body substitution convention. Anthropic's spec describes it, and multiple platforms document support:

- **Claude Code**: Full support (`$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`)
- **VS Code/Copilot**: Supports argument passing (syntax not fully documented)
- **Cursor**: Supports argument passing via `/skill-name <args>`
- **Codex**: Supports argument passing
- **Others**: Likely supported (standard feature)

**Assessment**: `$ARGUMENTS` is likely the most portable body-level feature.

---

## 4. Per-Skill Portability Assessment

### Tier 1: Near-Portable (3 skills)

These skills have simple, procedural instructions that could work across platforms with minimal changes.

| Skill | What Makes It Portable | What Needs Changing |
|-------|----------------------|---------------------|
| `git/prune-merged` | Git commands are universal. Simple workflow. | Replace `AskUserQuestion` with natural language confirmation prompt. Replace tool names. |
| `git/repoint-branch` | Git + gh commands. Linear flow. | Remove specific tool references. |
| `do-refactor-code` | Analysis-focused. Reads files, produces report. | Replace `Read` tool name with generic instruction. |

### Tier 2: Moderate Effort (10 skills)

These skills use Claude Code tools but the core logic is transferable.

| Skill | Blocker | Effort to Port |
|-------|---------|---------------|
| `git/create-pr` | Tool names, `gh` command patterns (universal), template refs | Low-Medium |
| `git/address-pr-review` | Tool names, `gh` API patterns | Low-Medium |
| `git/explore-pr` | Tool names, Q&A interaction model | Medium |
| `git/resolve-conflicts` | Tool names, `AskUserQuestion` for conflict choices | Medium |
| `git/split-pr` | Tool names, structured output | Low-Medium |
| `git/cascade-rebase` | Tool names, sequential git operations | Low-Medium |
| `git/monitor-pr-comments` | Background execution (CC-only), `TaskStop` | Medium-High |
| `set-persona` | File loading pattern, `Glob` + `Read` | Medium |
| `learnings/distribute` | File operations, `AskUserQuestion` | Medium |
| `ralph/compare` | File comparison, structured output | Medium |

### Tier 3: Deep Coupling (9 skills)

These skills fundamentally depend on Claude Code's orchestration model.

| Skill | Core Dependency | Why It Can't Port Easily |
|-------|----------------|-------------------------|
| `explore-repo` | `Task` (parallel subagents) | Multi-agent orchestration is CC-only |
| `do-security-audit` | `Task` (parallel subagents) | Multi-agent orchestration is CC-only |
| `parallel-plan/make` | Specialized analysis output | Depends on CC tool ecosystem |
| `parallel-plan/execute` | `Task`, `TaskCreate`, `TaskOutput`, worktrees | Deep CC-only orchestration |
| `learnings/compound` | `AskUserQuestion`, file ecosystem, templates | Tight coupling to CC file tools + interaction |
| `learnings/consolidate` | `Task` (orchestrates curate), state management | Multi-iteration delegation is CC-only |
| `learnings/curate` | `AskUserQuestion`, classification model, parallel analysis | CC-specific interaction + subagents |
| `quantum-tunnel-claudes` | `AskUserQuestion`, git operations, inventory script | CC-specific sync workflow |
| `ralph/init` | `!`command``, `@` references, file scaffolding | CC-only preprocessing + eager refs |

---

## 5. Cross-Platform Distribution Strategy

### Plugin Systems Compared

| Platform | Distribution | Registry | Notes |
|----------|-------------|----------|-------|
| Claude Code | `.claude-plugin/plugin.json` + marketplace repos | GitHub-based marketplace | Most mature plugin system |
| VS Code/Copilot | VS Code extensions via `chatSkills` contribution | VS Code Marketplace | Requires extension packaging |
| Cursor | No documented plugin system | N/A | Skills are local-only or copied |
| Codex | `$skill-installer` + GitHub repos | No centralized marketplace | Repository-based distribution |
| Gemini CLI | Extensions (bundled with installed extensions) | N/A | Extension-based |
| Roo Code | No documented plugin system | N/A | Local-only or copied |
| SkillPort | CLI install + MCP server | SkillPort manages inventory | Meta-tool that serves to any platform |

### Implications for Plugin Strategy

The modular plugin approach from [plugin-packaging-strategy.md](./plugin-packaging-strategy.md) targets Claude Code's marketplace. For cross-platform reach:

1. **`.agents/skills/` directory** is the universal fallback — any platform can find skills there
2. **GitHub repos** work for Codex (`$skill-installer`) and manual copying for all platforms
3. **SkillPort** can manage skills across platforms from a single source
4. **VS Code extension** packaging is needed for marketplace distribution but is a separate effort

**Recommendation**: The primary distribution path (Claude Code marketplace) is correct. For cross-platform, the simplest approach is:
- Keep skills in a GitHub repo structured as `.agents/skills/<name>/SKILL.md`
- Write a "portable subset" README listing which skills work cross-platform
- Use SkillPort for multi-platform delivery if demand warrants

---

## 6. Portability Best Practices

### Writing Portable Skills

For skills intended to work across platforms:

1. **Use natural language for tool instructions** instead of tool names:
   - ❌ "Use the `Read` tool to read the file"
   - ✅ "Read the contents of the file at..."

2. **Use `$ARGUMENTS` for input** — most portable body-level feature

3. **Use `compatibility:` field** to signal intended platform:
   ```yaml
   compatibility: Requires git, gh CLI, and shell access
   ```

4. **Put extensions in `metadata:`** for future-proofing:
   ```yaml
   metadata:
     claude-code:
       context: fork
       model: haiku
   ```
   (Note: Claude Code doesn't read `metadata` for behavior — this is for documentation/tooling only)

5. **Avoid platform-specific orchestration** (`Task`, `AskUserQuestion`, `TodoWrite`, background execution)

6. **Use `scripts/` for complex logic** — shell scripts are universally executable

7. **Test with `skills-ref validate`** — catches spec violations before cross-platform issues

### The `compatibility` Field

The spec's `compatibility` field is designed for exactly this use case:

```yaml
compatibility: Designed for Claude Code. Core git workflow works in any Agent Skills-compatible tool.
```

This signals to other platforms and users what to expect.

---

## 7. Impact on Implementation Plan

### No Changes Needed to Existing Phases

All planned frontmatter additions (Phases 1-4) degrade gracefully on other platforms:
- `name` → improves portability
- `disable-model-invocation` → ignored (skill loads normally)
- `argument-hint` → ignored (no hint shown)
- `hooks` → ignored (hooks don't fire)

### New Recommendation: Add `compatibility` Field

For skills that are NOT portable (Tier 3), add:
```yaml
compatibility: Requires Claude Code (uses subagent orchestration)
```

For skills that ARE portable (Tier 1-2), add:
```yaml
compatibility: Works with any Agent Skills-compatible tool. Requires git and gh CLI.
```

This is a zero-risk, zero-cost addition that improves cross-platform UX. Could be added alongside Phase 1D (`name` field).

### Plugin Phase (6) Cross-Platform Addition

If cross-platform distribution is desired beyond Claude Code marketplace:
1. Structure plugin repos with `.agents/skills/` layout (universal path)
2. Add a `COMPATIBILITY.md` or README section listing per-skill portability tier
3. Consider SkillPort integration for multi-platform delivery

---

## 8. The `metadata` Namespace Pattern

SkillPort's approach of using `metadata.skillport.*` for platform-specific configuration is a clean pattern that avoids frontmatter pollution while staying spec-compliant:

```yaml
metadata:
  skillport:
    category: development
    tags: [git, workflow]
    alwaysApply: true
  claude-code:
    context: fork
    model: haiku
```

**Current limitation**: Claude Code reads extension fields from top-level frontmatter, not from `metadata.*`. The `metadata` namespace pattern is for documentation/tooling only — it doesn't affect runtime behavior on any platform today. But it's forward-compatible if platforms agree on this convention.

---

## 9. VS Code Warning Workaround

VS Code's strict frontmatter validation ([issue #294520](https://github.com/microsoft/vscode/issues/294520)) warns on Claude Code extension fields. Two workarounds:

1. **File association override** (per-workspace or global):
   ```json
   "files.associations": {
     "**/.claude/skills/**/SKILL.md": "markdown",
     "**/.claude/commands/**/SKILL.md": "markdown"
   }
   ```
   Treats SKILL.md as plain markdown, disabling skill validation.

2. **Wait for fix** — issue is open with MS maintainers assigned. Partial fix landed in v1.109.3, but some extension fields still warn.

**Impact**: This affects **editing** skills in VS Code, not executing them. Skills still load and work fine in Copilot regardless of editor warnings.

---

## 10. Summary: What This Means for This Repo

| Dimension | Assessment |
|-----------|-----------|
| **Frontmatter portability** | Excellent — description-only today, all planned additions degrade gracefully |
| **Body portability** | Low — all 22 skills reference CC-specific tools |
| **Distribution portability** | Medium — GitHub repos work everywhere, CC marketplace is primary |
| **Effort to make portable** | 3 skills: low effort. 10 skills: moderate. 9 skills: not practical. |
| **Should we prioritize portability?** | **No for existing skills** — they're tuned for Claude Code. **Yes for new skills** if sharing is a goal. |

### Recommended Actions

1. **Add `compatibility` field** (Phase 1, zero-cost) — signals portability tier per skill
2. **Add `name` field** (already planned) — improves spec compliance everywhere
3. **For new skills**: Consider writing tool-agnostic instructions if cross-platform is desired
4. **For plugin distribution**: Structure repos with `.agents/skills/` for universal discovery
5. **Don't rewrite existing skills** for portability — the ROI is poor for Tier 3 skills

---

## Sources

- [Agent Skills Specification](https://agentskills.io/specification)
- [Cursor Skills Docs](https://cursor.com/docs/context/skills)
- [VS Code Copilot Agent Skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- [GitHub Copilot Agent Skills Changelog (Dec 2025)](https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/)
- [OpenAI Codex Skills](https://developers.openai.com/codex/skills/)
- [Gemini CLI Skills](https://geminicli.com/docs/cli/skills/)
- [Roo Code Skills](https://docs.roocode.com/features/skills)
- [OpenCode Skills](https://opencode.ai/docs/skills/)
- [SkillPort](https://github.com/gotalab/skillport)
- [VS Code Frontmatter Validation Issue #294520](https://github.com/microsoft/vscode/issues/294520)
- [Anthropic: Equipping Agents with Agent Skills](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills)
