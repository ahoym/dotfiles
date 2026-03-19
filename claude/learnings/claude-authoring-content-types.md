# Content Type Taxonomy

Routing guide for the Claude configuration surface. Decide where content belongs, then follow the per-type authoring guide.

## Content Types

| Type | Location | What belongs here | Placement test |
|------|----------|-------------------|----------------|
| **Skill** | `commands/` | Actionable, repeatable multi-step procedures | Can it be invoked as a command with clear steps? |
| **Guideline** | `guidelines/` | Universal behavioral rules ("always do X") | Shapes behavior universally, `@`-loaded from CLAUDE.md |
| **Learning** | `learnings/` | Domain knowledge: gotchas, recipes, patterns | Conditional reference, loaded by persona or keyword search |
| **Persona** | `commands/set-persona/` | Judgment lens: priorities, tradeoffs, review instincts | "Would activating this change what I do?" — if just a gotcha list, not ready |
| **Skill reference** | `skill-references/` | Shared patterns consumed by 2+ skills | Single source of truth; skills read selectively, not `@`-loaded |
| **Template** | Inside skill directory | Message body content (reply text, PR descriptions) | Body-only — no posting commands. Promote to `skill-references/` if shared |
| **Memory** | `memory/` | Facts, context, project state | Last resort — if it would be useful to a skill or persona, use a discoverable file instead |
| **CLAUDE.md** | Project root or subdirectory | Navigational hub, architecture, relationships | `@` refs for always-needed context; signposts (non-`@`) for conditional |

### Quick Decision Tree

1. Can it be invoked as a command with clear steps? → **Skill**
2. Does it change how I should behave or approach tasks? → **Guideline**
3. Is it useful reference info (patterns, examples, gotchas)? → **Learning**
4. Is it a judgment lens for a domain (priorities, tradeoffs)? → **Persona**
5. Is it a shared pattern used by 2+ skills? → **Skill reference**
6. Is it message body content for a skill? → **Template** (skill-scoped) or **Skill reference** (if shared)
7. Is it a fact that doesn't fit anywhere else? → **Memory** (last resort)

## Boundary Cases

- Prescriptive but conditional on domain → learning or persona gotcha, not guideline
- Guideline that restates a skill's default behavior → redundant, remove it
- Learning fully covered by a persona one-liner → apply the persona-learning boundary test (see `claude-authoring-learnings.md`)
- Content in memory that's a behavioral rule → migrate to guideline
- Skill-scoped reference file gaining a second consumer → promote to `skill-references/` or `learnings/`

## Universal vs Language-Specific

Separate language-agnostic principles from language/tool-specific implementations.

**The test:** Ask "Does this apply regardless of language?" If yes, document it as a universal principle with pseudocode examples.

**Examples:**
- **Universal:** Helper Class Extraction, Factory Functions, Single Responsibility Principle
- **Language-specific:** Python docstring style, JavaScript async/await patterns

## Guideline Scoping: Always-On vs Conditional

| Scope | Mechanism | When to use |
|-------|-----------|-------------|
| **Always-on** | `@` import in CLAUDE.md | Behavioral rules that apply to every interaction |
| **Conditional** | Reference file in a skill directory | Context needed only when that skill runs |
| **Persona** | Persona file in `set-persona/` | Domain-specific behavioral rules loaded on activation |
| **Search-only** | Standalone file in `guidelines/` or `learnings/` | Rarely needed, fine to discover ad-hoc |

Prefer conditional or persona scoping over always-on when the content is only relevant during a specific workflow or domain.

## Evaluating Existing Guidelines

Guidelines must be universal — applicable to any agent regardless of stack, language, or project. During curation, actively look for content to migrate out:

| Sign of Wrong Placement | Action |
|------------------------|--------|
| References a specific stack/framework (Vitest, React, Spring) | Migrate to `learnings/<domain>.md` |
| Contains project-specific paths or config | Migrate to learnings or project CLAUDE.md |
| Documents language-specific patterns or gotchas | Migrate to `learnings/<language>-patterns.md` |
| Documents a past bug fix | Move to code comment at the fix location |
| Describes an existing utility function | Remove; discoverable via code search |
| The "wrong" pattern only exists in the guideline | The bug is fixed; remove the guideline |

## Skill References & Templates (inline guidance)

**Skill references** (`skill-references/`):
- Must be consumed by 2+ skills. If only one consumer, inline in the skill instead
- Split by platform (`github-commands.md`, `gitlab-commands.md`) so skills read selectively
- Body-only for template content — no posting commands
- Authoritative source of truth — when a skill absorbs reference content inline, deduplicate from the *skill*, not the reference

**Templates** (skill-scoped):
- Live inside the skill directory that uses them
- Body-only content — command mechanics belong in platform command refs or skill steps
- If multiple skills need the same template, promote to `skill-references/`

## Memory (inline guidance)

- Challenge every memory addition: could this live in a guideline, learning, skill reference, or persona instead?
- Memory is always-on context cost — learnings/guidelines are conditional and discoverable
- Behavioral rules → guidelines, not memory
- If it duplicates a learning or guideline, the memory is the redundant copy
- Convert relative dates to absolute when saving

## Content Principles

### No TODOs or Feature Requests

Learnings, guidelines, and skills document **patterns** — things observed, decided, or implemented. Not aspirations or "not yet implemented" TODOs. The curation workflow surfaces insights when conditions are right.

### Genericize Tool-Specific References

Skill instructions should reference artifacts generically, not by the tool that created them.

- Bad: "check if the project has a CLAUDE.md generated by `/explore-repo`"
- Good: "check if the project has a CLAUDE.md"

## Authoring Guides (per-type)

For detailed authoring craft, see the spoke file for the relevant type:
- `claude-authoring-skills.md` — skill design patterns, frontmatter, composition, hooks, references
- `claude-authoring-polling-review-skills.md` — polling loops, quick-exit logic, re-review detection, reviewer timestamps
- `claude-authoring-guidelines.md` — merging overlaps, enforcement gates, scoping, separation tiers
- `claude-authoring-learnings.md` — genericization, scope classification, boundary tests
- `claude-authoring-personas.md` — judgment vs recipes, proactive loads, gotcha files, composition
- `claude-authoring-claude-md.md` — conditional references, relationships, subdirectory criteria

## Converting Guidelines to Skills

A guideline is a candidate for skill conversion when it describes an actionable, repeatable process with clear inputs.

**Process:**
1. Create skill folder: `.claude/commands/<skill-name>/`
2. Move detailed patterns to a reference file in the skill folder
3. Replace guideline content with: "Use `/<skill-name>` to..."
4. Keep the guideline header for discoverability
