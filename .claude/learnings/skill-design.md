# Skill Design Patterns

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

- **`allowed-tools`** — Scoped tool permissions active only during skill execution. **Currently broken:** restriction not enforced ([#18837](https://github.com/anthropics/claude-code/issues/18837)), Bash auto-approval broken ([#14956](https://github.com/anthropics/claude-code/issues/14956)), marked "Experimental" in Agent Skills spec. Anthropic's own reference skills (16 in `anthropics/skills`) don't use it; Trail of Bits does (security focus). Use for documentation/intent-signaling on read-only skills only; defer broad adoption until enforcement is fixed. Syntax: comma-delimited (`Read, Grep, Glob`), YAML list, or scoped Bash (`Bash(gh:*)`) all work.
- **`context: fork` + `agent:`** — Run skill in isolated subagent (Explore, Plan, general-purpose). Skill content becomes the subagent's prompt with no conversation history. **Critical constraint:** subagents cannot spawn subagents, so skills that internally use the Task tool (explore-repo, do-security-audit, parallel-plan:execute) are incompatible with fork.
- **`model:`** — Override session model per skill (e.g., `haiku` for simple tasks, `opus` for complex reasoning).
- **`disable-model-invocation: true`** — Prevents auto-invocation AND removes the skill from context entirely. Saves context budget for manual-only skills.
- **`{baseDir}`** — Resolves to skill's own installation directory (e.g., `~/.claude/commands/<skill>/`). Works for intra-skill references (scripts/, references/, assets/) but **cannot** replace `~/.claude/` for cross-directory references to `~/.claude/learnings/`, `~/.claude/skill-references/`, etc.

Gap identified comparing 22 repo skills against official spec — none use these features.

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

The `` !`command` `` syntax in SKILL.md runs shell commands as preprocessing — output replaces the placeholder before Claude sees the prompt. Useful for injecting live state:

```markdown
- Current branch: !`git branch --show-current`
- Uncommitted changes: !`git diff --stat`
```

Not yet used in this repo. Good candidates: git skills that need current repo state, PR skills that need PR metadata.

## `context: fork` vs Task Subagents

Two isolation mechanisms, different use cases:

- **`context: fork`** — Skill delivery. The *entire skill* runs as a subagent. User invokes `/skill-name`, gets a result back. No conversation history, no mid-task interaction. Best for self-contained, one-shot analysis (input → summary).
- **Task subagents** — Orchestration. The skill runs inline and *delegates subtasks* to workers. Skill stays in main context, coordinates multiple agents, synthesizes results. Best for parallel work, multi-step workflows, anything needing user interaction or conversation history.

They conflict: a forked skill can't spawn Task subagents (no nesting). So skills that orchestrate workers (explore-repo, do-security-audit, parallel-plan:execute) must stay inline with Task subagents — they can't use `context: fork`.

**Choose fork when:** entire skill is a pure function (args in, report out). **Choose Task when:** skill needs to coordinate, interact, or delegate.

## `context: fork` Viability Checklist

A skill is only viable for `context: fork` if ALL of these are true:

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

All skill descriptions (name + description frontmatter) share a budget of **2% of the context window** (~16,000 chars fallback). Skills exceeding the budget are silently excluded. Check with `/context` command. Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var. With 22 skills, budget pressure increases — another reason to use `disable-model-invocation` on manual-only skills.

