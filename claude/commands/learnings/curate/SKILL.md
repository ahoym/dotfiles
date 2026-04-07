---
name: curate
description: "Single-pass curation of learnings, guidelines, and skills — consolidate, reorganize, or prune. For exhaustive multi-sweep curation, use learnings:consolidate instead."
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - Write
---

# Curate Learnings

Review learnings, guidelines, or skills to identify content that should be migrated, reorganized, or pruned.

## Usage

- `/learnings:curate <file-path>` - Curate a specific file (relative to `~/.claude/`)
- `/learnings:curate <file1> <file2>` - Curate multiple files
- `/learnings:curate` - Prompt for which file to curate

## Context Window Optimization

Curation serves a dual purpose: organizing content AND minimizing baseline context window cost. Every token in reference material is a token unavailable for the actual task.

**Core principles:**

- **`@` references are always-on cost.** Content in `@`-referenced files (e.g., `@.claude/guidelines/...` in CLAUDE.md) is injected into every conversation regardless of relevance. Keep `@`-referenced files lean — only universally-needed content belongs there.
- **Non-`@` path references are conditional.** Skill reference files, learnings, and non-`@` files are only read when the agent judges them relevant to the current task. Prefer these for domain-specific, task-specific, or situational content.
- **Reorganization enables selectivity.** Well-organized, granular files let the agent pull in only what's relevant. A monolithic 200-line file forces loading all 200 lines even when only 20 matter.
- **Conciseness is a feature.** When reorganizing content, also compress it. Redundant phrasing, excessive examples, and verbose explanations waste context budget. Say the same thing in fewer tokens.

**During classification (step 4), factor in context cost:**
- Content currently in `@`-referenced files that isn't universally needed → candidate for migration to a conditional reference (skill reference file, learning, or non-`@` guideline)
- Content that could be split from a large file into a focused file the agent can selectively load → candidate for extraction
- Duplicate or near-duplicate content across files → consolidation saves tokens in every conversation that loads both

## Reference Files (conditional)

- content-mode.md — Content mode execution steps (2–6), report formats, and apply actions — read after step 1 when mode = content
- skill-mode.md — Skill mode execution steps (2–4), report format, and apply actions — read after step 1 when mode = skill
- classification-model.md — The 6-bucket classification model with decision criteria (learnings/guidelines) and skill pruning criteria (skills) — read in step 4
- `~/.claude/learnings/claude-authoring/routing-table.md` — Content type routing table (for reorganization) — read in step 4
- persona-design.md — Persona structure, naming, sizing, and suggestion criteria — read in step 5a when persona clusters are detected
- curation-insights.md — Operational calibration and phase-specific patterns from prior consolidation runs — read in step 4

## Parallel Execution

This skill has several steps that can run concurrently. **Use parallel tool calls aggressively** to reduce wall-clock time:

| Opportunity | When | How |
|---|---|---|
| **Pre-load + parse** | Always (content mode) | Step 2: parse target files AND bulk-read all skill/guideline files in the same tool-call batch |
| **Multi-file pipelines** | 2+ target files in content mode | Launch one Task subagent per file for steps 2→6, merge results at step 7 |
| **Step 6** | Single-file content mode | Run underutilized-skill check and persona detection as parallel tool calls after step 5 |
| **Broad sweep clusters** | "All learnings" mode | After clustering (step 2), launch one Task subagent per domain/stack cluster for analysis |
| **Apply actions** | Step 8, after operator approval | Execute independent file writes (different target files) as parallel tool calls |

Detailed instructions for each opportunity are inline in the relevant steps (marked with **⚡ Parallel**).

## Instructions

### 1. Get target file(s)

**If `$ARGUMENTS` provided**:
- Parse as space-separated file paths (relative to `~/.claude/`)
- Verify each file exists under `~/.claude/` — check provider directories from `~/.claude/learnings-providers.json`, plus `guidelines/`, `commands/`, `skill-references/`
- Determine the **curation mode** per file:
  - `learnings/*` or `learnings/<cluster>/*` or `learnings/<cluster>/<subcluster>/*` or `guidelines/*` → **Content mode** (pattern-level analysis)
  - `commands/*/SKILL.md` (or a skill directory) → **Skill mode** (skill-level evaluation)
  - `commands/*` reference files (e.g., `classification-model.md`) → **Content mode** (pattern-level analysis). These are content files with discrete patterns, not skill packages. Skill mode is only for SKILL.md files and their parent directories.
  - `skill-references/*` → **Content mode** with **reference-file gate** (step 4a). These are authoritative shared references — duplication is removed from consuming skills, not from the reference.
- Store as `TARGET_FILES`

**If no arguments**:
- List available files under all provider directories from `~/.claude/learnings-providers.json` (including cluster subdirectories), `projectLocal.path` (resolved relative to project root), `~/.claude/guidelines/`, `~/.claude/skill-references/`, and skill directories under `~/.claude/commands/`
- Use `AskUserQuestion` to prompt the operator:
  ```
  What would you like to curate?

  Learnings (clusters):
  - learnings/xrpl/ (6 files)
  - learnings/frontend/ (7 files)
  - ...

  Learnings (flat):
  - learnings/testing-patterns.md
  - ...

  Guidelines:
  - guidelines/communication.md
  - ...

  Skill References:
  - skill-references/agent-prompting.md
  - ...

  Skills:
  - commands/do-security-audit
  - commands/git:split-pr
  - ...
  ```
- Store selection as `TARGET_FILES`

**If operator selects "all learnings" (broad sweep mode)**:

This is a content mode variant. Read `content-mode.md` and follow the **Broad Sweep** section.

### 2. Load mode-specific instructions

Based on the curation mode determined in step 1, read the appropriate reference file:
- **Content mode** → Read `content-mode.md`
- **Skill mode** → Read `skill-mode.md`

Then follow the mode-specific steps (2–6 for content, 2–4 for skill) before returning to step 7 below.

---

### 7. Generate recommendations

Display the full report inline in the CLI. Use the report format from the loaded mode file (content-mode.md or skill-mode.md).

### 8. Apply changes (with approval)

For each recommended action, use `AskUserQuestion` with **multi-select** to let the operator pick which actions to apply. Each action should be a separate selectable option (not a table followed by a generic "apply?" prompt). Always include a **Discuss** option as one of the choices, especially for medium-confidence items.

**If operator approves**:

**⚡ Parallel: apply actions.** Group approved actions by target file. Actions targeting **different files** are independent — execute them as parallel tool calls. Actions targeting the **same file** must be sequential (to avoid edit conflicts).

Apply the mode-specific actions described in the loaded mode file (content-mode.md or skill-mode.md).

### 9. Update deep-dive tracker

After applying changes, update the consolidation deep-dive tracker so the next autonomous consolidation run knows this file was recently reviewed:

1. Read `~/.claude/ralph/consolidate/deep-dive-tracker.json`
2. For each curated file in `TARGET_FILES`:
   - Derive the tracker key (path relative to repo root, e.g., `.claude/learnings/foo.md`)
   - Set `last_deep_dive_run` to the current `run_count` value
   - If the file isn't in the tracker yet, add it
3. Write the updated tracker back

This prevents the consolidation loop from queueing files for deep dives that were just manually curated.

### 10. Report results

```
## Curation Complete

**Curated**: <file or skill name>

**Actions taken**:
- ...

**Deep-dive tracker**: Updated for <N> file(s) (run_count: <N>)

**Skills flagged for review**: N
```

## Prerequisites

For prompt-free execution, add these allow patterns to `~/.claude/settings.local.json`:

```json
"Read(~/.claude/commands/**)",
"Read(~/.claude/learnings-providers.json)",
"Read(~/.claude/learnings*/**)",
"Read(~/.claude/guidelines/**)",
"Write(~/.claude/commands/**)",
"Write(~/.claude/learnings*/**)",
"Write(~/.claude/guidelines/**)",
"Write(~/.claude/skill-references/**)",
"Edit(~/.claude/commands/**)",
"Edit(~/.claude/learnings*/**)",
"Edit(~/.claude/guidelines/**)",
"Edit(~/.claude/skill-references/**)"
```

## Important Notes

- **Operator approval required**: Always use `AskUserQuestion` before applying changes
- **Discuss option**: Always include for medium-confidence items
- **Deletion with approval**: Content/skills can be deleted if the operator approves
- **Preserve context**: When migrating, ensure content retains enough context to be useful standalone
- **Update cross-references**: If content is migrated, update any internal links in the source file
- **Frequency**: Designed for regular use to prevent bloat across learnings, guidelines, and skills
- **Complements learnings:compound**: This curates existing content; `learnings:compound` creates new content
