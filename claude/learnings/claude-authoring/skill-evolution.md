Skill design evolution — authoring guides organization, guidelines-to-skills migration, namespace migration, conventions, decomposition patterns, and token optimization.
- **Keywords:** hub-and-spoke, guidelines-to-skills, namespace migration, numeric arg convention, cross-skill discovery, base persona extends, skill decomposition, structured footnote, token optimization, cross-refs
- **Related:** ~/.claude/learnings/claude-code/skill-platform-portability.md, ~/.claude/learnings/process-conventions.md

---

## Hub-and-Spoke for Authoring Guides

When authoring knowledge spans multiple content types (skills, guidelines, learnings, personas), organize as a routing hub + per-type spokes rather than a monolithic file or scattered fragments. The hub stays small — routing table, boundary cases, inline guidance for minor types. Spokes handle authoring craft for types with enough depth. This enables selective loading (pay tokens only for the type you're writing) and clean ownership (each spoke stays in its lane).

Naming convention: use a shared prefix (`claude-authoring-*`) to group the cluster and separate from platform knowledge files (`claude-code-*`).

## Guidelines-to-Skills Migration

### Guideline-to-skill conversion signal

Guidelines are always-loaded context (`@`-referenced from CLAUDE.md); skills load on invocation. The conversion signal: procedural workflows with clear invocation triggers. "Do X when triggered" = skill. "Always behave this way" = guideline. Reserve guidelines for rules that genuinely apply to every interaction.

### Skill naming convention: prefix by taxonomy domain

When skill count grows, prefix filenames by domain taxonomy (e.g., `git-create-pr.md`, `git-cascade-rebase.md`) rather than flat names. Pattern: `{domain}-{action}.md`. Apply retroactively in a single atomic PR to avoid transitional inconsistency.

### Consolidate guidelines by removing skill commands that duplicate inline knowledge

When guidelines already document how to run commands (e.g., exact CLI invocations), dedicated skill files wrapping those same commands add no value. Delete the skill when the guideline already covers it.

### Meta-guidelines for skill creation belong in always-loaded context

When converting guidelines to skills, a companion `skill-design.md` guideline codifying skill structure belongs in always-loaded context — it governs the quality of all future skill creation.

## Skill Namespace Migration Blast Radius

When renaming a skill namespace (e.g., `ralph:init` → `ralph:research:init`), the SKILL.md files are the obvious targets but infrastructure references are the most commonly missed. Trace all of these: runner script paths (wiggum.sh), hook marker patterns in lib-hooks.sh (used for idempotent injection/cleanup), worktree prefix patterns in cleanup skills, output directory paths across sibling skills (brief/resume/compare may reference different paths than init), and learnings files that document the architecture. Grep the entire `.claude/` tree for the old path fragments before declaring the migration complete.

## Numeric Arg = PR/MR Number Convention

Git skills that operate on a PR/MR should treat a numeric positional arg as a PR/MR number: resolve head/base branches via `gh pr view <N>` / `glab mr view <N>`, check out the branch if needed. Already standard in: address-request-comments, code-review-request, explore-request, split-request, resolve-conflicts. Non-numeric positional args remain branch names or other skill-specific inputs. When adding PR/MR support to a skill, also handle URL args (extract the number) and fall back to current branch detection.

## Cross-Skill Discovery via Cross-Refs

1. **Add "Cross-Refs" section** to skills that have natural follow-ups (table with Next Step → Skill columns)
2. **Reference prerequisite skills** in Important Notes (e.g., "Use `/git:explore-pr` first if you need to understand the PR before splitting")

## Base Reviewer Persona with Extends

Universal review knowledge (code quality instincts, process conventions) belongs in a base `reviewer` persona that domain-specific reviewer personas extend via `## Extends: reviewer`. This ensures every reviewer gets the baseline quality bar without each persona duplicating the same proactive cross-refs. Domain-specific personas add only their unique cross-refs and judgment lens.

## Skill Decomposition by Execution Path

When a skill has mutually exclusive execution paths (e.g., "content mode" vs "skill mode"), split mode-specific steps into conditional reference files loaded after the mode is determined. This saves context — the unused mode's instructions never load.

**Decision criteria:**
- Paths must be truly independent (never both active in one invocation)
- Savings must exceed coordination cost (an extra Read + cross-file references)
- Report templates and apply actions travel with their mode — they're consumed together, so grouping them avoids extra files

**Anti-pattern: single-file conditional split.** Putting all conditional content into one reference file that's always loaded just adds indirection without saving context. Splits only help when they actually gate content out. Similarly, splitting report templates into their own file when they're always loaded alongside their mode is pure overhead.

**Mode variants stay with their parent mode.** When a mode has a variant (e.g., "broad sweep" is content mode at a different granularity), keep it in the mode's file rather than in the shared SKILL.md or a third file. It's the same execution path with different entry conditions — splitting it out would add coordination cost without meaningful savings.

## Structured Footnote for External Platform Posts

Skills that post to external platforms should include the structured footer from `process-conventions.md` § "Structured footnotes for multi-agent comment identity." The `Persona + Role` composite key enables filtering comment chains — the same persona may act as both Reviewer and Addresser on the same PR. Skills filter their own previous comments by matching both fields, not by username (which catches all comments regardless of role).

## Analyzing Skills for Token Optimization

Periodically review skills 100+ lines to identify content extractable into conditional reference files.

| Content Type | Extract? | Threshold |
|---|---|---|
| Core instructions | No | Always needed |
| Templates, examples, reference tables | Yes | 10+ lines, only needed situationally |
| Edge case documentation | Maybe | 20+ lines |

**Evaluate extraction benefit:** 50+ lines situational = high value, 20-50 = medium, <20 = overhead exceeds benefit. Don't extract content under 15 lines, needed on every invocation, or that loses context when separated.

## Cross-Refs

- `~/.claude/learnings/claude-code/skill-platform-portability.md` — platform features, frontmatter fields, cross-platform compatibility
- `~/.claude/learnings/process-conventions.md` — structured footnote template for multi-agent comment identity
