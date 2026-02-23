# Claude Skills Best Practices

Research findings on Claude Code skill design, combining official documentation, community patterns, and analysis of the 22 skills in this repo.

## 1. Official Skill Anatomy (from Anthropic Docs)

### SKILL.md Structure

Every skill lives in a directory with a required `SKILL.md`:

```yaml
---
name: my-skill                    # Defaults to directory name
description: What it does         # Primary trigger for auto-invocation
argument-hint: [issue-number]     # Autocomplete hint
disable-model-invocation: true    # Prevents Claude from auto-loading
user-invocable: false             # Hides from / menu
allowed-tools: Read, Grep, Glob   # Scoped tool permissions (active only during skill execution)
model: claude-opus-4              # Override session model
context: fork                     # Run in isolated subagent
agent: Explore                    # Subagent type (when context: fork)
---

Markdown instructions here...
```

All frontmatter fields are optional. Only `description` is recommended.

### Where Skills Live (Priority: enterprise > personal > project)

| Location   | Path                                     | Scope                     |
|:-----------|:-----------------------------------------|:--------------------------|
| Enterprise | Managed settings                         | All users in organization |
| Personal   | `~/.claude/skills/<name>/SKILL.md`       | All your projects         |
| Project    | `.claude/skills/<name>/SKILL.md`         | This project only         |
| Plugin     | `<plugin>/skills/<name>/SKILL.md`        | Where plugin is enabled   |

### Commands vs Skills

Custom slash commands (`.claude/commands/`) still work but skills are the recommended path forward. Skills add: supporting files, frontmatter-based invocation control, auto-discovery, and `context: fork` for subagent execution. If a skill and command share a name, the skill takes precedence.

**This repo uses `.claude/commands/`** — migration to `.claude/skills/` (or `.claude/commands/` with full skill features) is worth evaluating.

### Dynamic Context Injection

The `` !`command` `` syntax runs shell commands as preprocessing:

```markdown
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`
```

Output replaces the placeholder before Claude sees the prompt. Useful for injecting live state.

### String Substitutions

| Variable               | Description                                    |
|:-----------------------|:-----------------------------------------------|
| `$ARGUMENTS`           | All arguments passed when invoking             |
| `$ARGUMENTS[N]`       | Specific argument by 0-based index             |
| `${CLAUDE_SESSION_ID}` | Current session ID for logging/correlation     |

### Context Budget

Skill descriptions consume **2% of the context window** (~16,000 chars fallback). Check with `/context`. Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var.

---

## 2. Invocation Control Matrix

| Frontmatter                      | User invokes | Claude invokes | Context loading                                             |
|:---------------------------------|:-------------|:---------------|:------------------------------------------------------------|
| (default)                        | Yes          | Yes            | Description always in context; full skill loads when invoked |
| `disable-model-invocation: true` | Yes          | No             | Description NOT in context; loads only on manual invocation  |
| `user-invocable: false`          | No           | Yes            | Description always in context; full skill loads when invoked |

Key insight: `disable-model-invocation: true` completely removes the skill from context, not just its ability to invoke. This saves context budget for skills that are only used manually.

---

## 3. Anthropic's Skill Design Principles

From the [official skill-creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md):

### Concise is Key
- The context window is a shared resource
- Only add context Claude doesn't already have
- Challenge every piece: "Does Claude really need this?"
- Prefer concise examples over verbose explanations

### Degrees of Freedom

| Freedom Level | When to Use                                | Instruction Style                      |
|:-------------|:-------------------------------------------|:---------------------------------------|
| High         | Multiple valid approaches, context-dependent | Text-based instructions               |
| Medium       | Preferred patterns exist, some variation OK  | Pseudocode with parameters            |
| Low          | Fragile operations, consistency critical     | Specific scripts, few parameters      |

### Progressive Disclosure (Three Levels)

1. **Metadata** (name + description): Always in context (~100 words)
2. **SKILL.md body**: Loaded when triggered (<5k words, <500 lines)
3. **Bundled resources**: Loaded as needed (scripts execute without reading into context)

### Resource Types

| Directory      | Purpose                    | Token Cost     | Use When                                    |
|:---------------|:---------------------------|:---------------|:--------------------------------------------|
| `scripts/`     | Executable automation      | None (executed) | Deterministic operations, repeated computations |
| `references/`  | Documentation for context  | Yes (loaded)   | API docs, schemas, domain knowledge         |
| `assets/`      | Files used in output       | None (by path) | Templates, images, boilerplate              |

### What NOT to Include
- No README.md, INSTALLATION_GUIDE.md, QUICK_REFERENCE.md, CHANGELOG.md
- Only include what the AI needs to execute the task

---

## 4. Design Patterns

### Pattern 1: Script Automation
Offload computational tasks to scripts. Claude orchestrates; scripts do heavy lifting.
```yaml
allowed-tools: Bash(python {baseDir}/scripts/*:*)
```
Use `{baseDir}` for portable paths — never hardcode absolute paths.

### Pattern 2: Subagent Delegation (`context: fork`)
Run skills in isolation. Skill content becomes the subagent's prompt with no conversation history.
```yaml
context: fork
agent: Explore
```
**Critical**: `context: fork` only makes sense for task-based skills. Reference-only skills will return empty because the subagent has nothing actionable to do.

### Pattern 3: Dynamic Context with Shell Preprocessing
Use `` !`command` `` to inject live data before Claude processes the prompt.

### Pattern 4: Subagent Analysis + Main Execution
Subagents perform read-only analysis (Read, Grep, Glob), then main Claude handles mutations (Write, Edit, Bash). Preserves tool access control.

### Pattern 5: Orchestrator/Agent Separation
Split complex multi-step skills:
- **SKILL.md (~80 lines)** — User interaction: identifying items, displaying for selection, gathering input
- **Background agent .md** — Autonomous workflow executed by Task agent

---

## 5. Description Engineering

The `description` field is the **primary trigger mechanism**. Claude uses natural language understanding (not algorithmic matching) to decide when a skill applies.

### WHEN + WHEN NOT Pattern
```yaml
description: >
  Deploy to staging/production. Use when asked to deploy, ship, or release code.
  Do NOT use for local development builds.
```

### Best Practices
- Include keywords users would naturally say
- Add domain-specific trigger words
- Remove internal jargon
- For multi-purpose skills, list key features

---

## 6. Common Anti-Patterns

### Structural
| Anti-Pattern | Fix |
|:---|:---|
| Monolithic skill handling multiple workflows | Split into focused, composable skills |
| Everything in SKILL.md (>500 lines) | Move reference material to separate files |
| Hardcoded absolute paths | Use `{baseDir}` variable |
| Extraneous docs (README, CHANGELOG) | Only include what AI needs |
| Vague descriptions | Use WHEN + WHEN NOT pattern |

### Permission
| Anti-Pattern | Fix |
|:---|:---|
| Over-permissioning (`allowed-tools: Bash,Read,Write,...`) | Specify exactly what's needed |
| No tool restrictions on dangerous skills | Add `disable-model-invocation: true` + scoped `allowed-tools` |

### Content
| Anti-Pattern | Fix |
|:---|:---|
| Duplicating info Claude already knows | Only add context Claude lacks |
| Second-person instructions ("You should...") | Use imperative form |
| Reference-only skill with `context: fork` | Add task instructions or remove fork |
| SKILL.md body >5,000 words | Use progressive disclosure |

---

## 7. This Repo's Current Skill Practices

### What We Do Well

- **22 skills, well-organized** — Semantic namespacing (`git:*`, `learnings:*`, `parallel-plan:*`, `ralph:*`)
- **Conditional reference loading** — Most reference files NOT eagerly loaded; only `@` for <30-line files needed every invocation
- **Rich internal documentation** — `skill-design.md`, `writing-best-practices.md`, `content-type-decisions.md`, `skill-template.md` cover authoring patterns
- **Variable continuity** in skill instructions — Explicit naming and referencing across steps
- **Token optimization awareness** — Periodic review of 100+ line skills for extraction
- **Portability focus** — Audit for project-specific content; genericize examples
- **Documented constraints** — AskUserQuestion 4-option max, background agent permission caching, symlink gotchas
- **Skill composition** — Related Skills sections, natural workflow chaining

### Potential Gaps (vs. Official Best Practices)

1. **`allowed-tools` frontmatter not used** — Skills don't declare scoped tool permissions. This means every skill runs with the session's full tool access rather than minimum necessary.

2. **No `{baseDir}` usage** — Skills reference paths with `~/.claude/...` rather than `{baseDir}`. If a skill is installed in a different location, paths break.

3. **`context: fork` / subagent delegation underused** — Only the main conversation runs skills; no skills leverage `context: fork` for isolated execution despite several being good candidates (e.g., `/explore-repo`, `/do-security-audit`).

4. **No dynamic context injection** — No `` !`command` `` preprocessing found. Some skills (e.g., git skills) could benefit from injecting git state before Claude processes the prompt.

5. **No `disable-model-invocation: true`** usage — All skills are potentially auto-invocable, which means all 22 skill descriptions consume context budget. Task-specific skills that are only manually invoked (e.g., `/ralph:init`, `/learnings:consolidate`) could save context by opting out.

6. **Skills live in `commands/` not `skills/`** — Uses the legacy commands directory. While functional, migration to `skills/` would enable full skill features and align with Anthropic's recommended path.

7. **No `scripts/` or `assets/` directories** — All supporting files are markdown references. No executable scripts bundled with skills (except `git:monitor-pr-comments` which has `.sh` files).

8. **No `model:` overrides** — Skills don't specify model preferences. Some complex skills might benefit from requesting `opus` while simpler ones could use `haiku` for speed.

---

## 8. How Skills Are Discovered and Selected (Internals)

1. Claude Code scans skill directories at startup
2. Frontmatter (name + description) aggregated into the Skill tool's description
3. Claude reads this list and uses **natural language reasoning** to decide when a skill applies
4. When invoked, full SKILL.md body injected as a user message (frontmatter excluded)
5. Execution context temporarily modified (tool permissions, model override)

### Two-Message Injection
When a skill activates, two messages are injected:
- **Metadata message**: Shown in UI (transparency)
- **Skill prompt message**: Hidden (`isMeta: true`), contains actual instructions

### Monorepo Auto-Discovery
Editing files in subdirectories also discovers nested `.claude/skills/` directories.

---

## 9. Community Skill Collections Worth Studying

| Collection | Focus | Notes |
|:---|:---|:---|
| [anthropics/skills](https://github.com/anthropics/skills) | Reference implementation | Includes skill-creator meta-skill |
| [Trail of Bits](https://github.com/trailofbits/skills) | Security auditing | 12+ security-focused skills |
| [Superpowers](https://github.com/obra/superpowers) | Core engineering competencies | Planning, reviewing, testing, debugging |
| [Context Engineering Kit](https://github.com/NeoLabHQ/context-engineering-kit) | Minimal token footprint | Advanced context engineering |
| [Compound Engineering Plugin](https://github.com/EveryInc/compound-engineering-plugin) | Learning from mistakes | Turns errors into learnings |

---

## Areas for Deeper Investigation

These topics warrant dedicated research files with cross-references:

1. ~~`commands/` to `skills/` Migration~~ → See [commands-to-skills-migration.md](./commands-to-skills-migration.md). **Key finding:** `commands/` supports all the same frontmatter as `skills/`. Migration is cosmetic/future-proofing only — no directory rename needed for any feature improvement.

2. ~~`allowed-tools` Scoping Strategy~~ → See [allowed-tools-scoping.md](./allowed-tools-scoping.md). **Key finding:** `allowed-tools` enforcement is currently broken (restriction not enforced, Bash auto-approval broken, marked "Experimental"). Recommend adding it to 5 read-only auto-invocable skills for documentation/future-proofing, but defer broad adoption until enforcement is fixed. `disable-model-invocation` is the higher-impact change.

3. ~~`context: fork` Candidates~~ → See [context-fork-candidates.md](./context-fork-candidates.md). **Key finding:** Only 1 of 22 skills (`ralph:compare`) is a viable fork candidate. The two originally assumed candidates (explore-repo, do-security-audit) are **incompatible** because they spawn subagents internally, and subagents cannot spawn subagents. Most other skills need conversation history or user interaction. Deprioritize fork adoption.

4. **Dynamic Context Injection (`!`command``)** — Which git-related skills could benefit from shell preprocessing? Performance implications?

5. ~~`disable-model-invocation` Budget Optimization~~ → See [disable-model-invocation.md](./disable-model-invocation.md). **Key finding:** 22 skills use only 2,813 chars (~17.6% of 16k budget) — no truncation risk. But disabling 9 manual-only skills saves 1,464 chars and, more importantly, reduces noise in Claude's skill selection decisions and prevents accidental invocation of heavyweight operations.

6. **`{baseDir}` Path Portability** — How does `{baseDir}` resolve for personal vs. project skills? Can it replace our `~/.claude/...` convention?

7. **Model Selection Strategy** — Which skills would benefit from `model:` overrides? Criteria for choosing haiku vs sonnet vs opus per skill.

8. **Anthropic Skills Repo Deep Dive** — Study the reference implementations in `anthropics/skills` for patterns we haven't adopted.

---

## Sources

- [Extend Claude with skills — Claude Code Docs](https://code.claude.com/docs/en/skills)
- [anthropics/skills — GitHub](https://github.com/anthropics/skills)
- [anthropics/skills — skill-creator/SKILL.md](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md)
- [Claude Agent Skills: A First Principles Deep Dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
- [Inside Claude Code Skills](https://mikhail.io/2025/10/claude-code-skills/)
- [Claude Code Customization Guide](https://alexop.dev/posts/claude-code-customization-guide-claudemd-skills-subagents/)
- [Skills vs Commands vs Subagents vs Plugins](https://www.youngleaders.tech/p/claude-skills-commands-subagents-plugins)
- [Claude Code Skills: The Complete Guide](https://fraway.io/blog/claude-code-skills-guide/)
- Internal: `.claude/learnings/skill-design.md`, `.claude/commands/learnings/compound/writing-best-practices.md`, `.claude/commands/learnings/compound/content-type-decisions.md`
