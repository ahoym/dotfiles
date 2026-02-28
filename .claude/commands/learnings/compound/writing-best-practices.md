# Writing Best Practices

Conventions and patterns for writing effective skills.

## Variable Continuity

When a skill stores data in one step and uses it later, explicitly name and reference the variable:

```markdown
3. **Determine files** (store as `FILES_TO_EXTRACT`):
   - Get list of files
   - Store the resulting file list as `FILES_TO_EXTRACT` for use in later steps

7. **Apply changes**:
   For each file in `FILES_TO_EXTRACT`:
   ```bash
   git add <FILES_TO_EXTRACT>
   ```
```

## User Interaction Points

Mark steps where user input is needed:
- **Ask for confirmation**: Before destructive operations (force push, reset)
- **Ask for selection**: When multiple paths are possible
- **Show and confirm**: Before committing or pushing

```markdown
5. **Validate**:
   - Show the files to be extracted
   - Ask: "Confirm these changes? (y/n)"
```

## Bash Commands in Skills

- Use `--force-with-lease` instead of `--force` for safety
- Include the full command, not just fragments
- Show prerequisite commands (fetch, checkout) explicitly
- Use HEREDOC for multi-line commit messages

## File Operations

Keep temp files within repo scope rather than system directories:

- **Use `./tmp/`** instead of `/tmp/` for skill-generated files
- Add `tmp/` to `.gitignore`
- Create the directory with `mkdir -p ./tmp` before use

This keeps operations contained to the repo context and avoids permission issues.

## Numbered Instruction Sequencing

Use proper integer steps (Step 0, 1, 2, 3...), not half-steps (Step 1.5). Half-steps signal unplanned structure, add ordering uncertainty, and complicate references. If inserting a new step, renumber all subsequent steps.

## Verify Assumptions Before Documenting

Test assumptions with a controlled experiment before writing them as facts. Before documenting a technical limitation, run a minimal reproducer. If testing "agents can't use X", test with a known-working variant first before concluding it's a platform issue.

Common pattern: permission-denied errors in background agents are almost always missing allow patterns, not platform constraints.

## Background Agent Permission Debugging

When a background agent fails silently:

1. Check if the specific command has a matching allow pattern in `.claude/settings.local.json`
2. Test with a simple allowed command (e.g., `echo "test"`) to isolate permission vs platform issues
3. If simple command works → missing allow pattern. If it also fails → platform issue

## Permissions

When a skill requires Bash commands, update `.claude/settings.json`:

1. List all commands the skill will run
2. Add appropriate patterns to `permissions.allow`
3. **Commit the settings.json changes** - permissions must be committed to take effect reliably
4. Verify the permissions work after committing

```json
{
  "permissions": {
    "allow": [
      "Bash(bash .claude/commands/my-skill/*)",
      "Bash(./tmp/my-script.sh*)"
    ]
  }
}
```

**Why this matters:** Without pre-approved permissions, users get prompted for every command, creating friction and defeating the purpose of automation. Uncommitted permission changes may appear to work in the current session but won't persist or be available to other users/sessions.

## Skill Naming Conventions

- Use lowercase with hyphens: `/cascade-rebase`, `/pr-status`
- Verb-noun or noun-verb: `/split-commit`, `/resolve-conflicts`
- Keep names short but descriptive (2-3 words max)

## Skill Description Frontmatter

The `description:` field in SKILL.md frontmatter should be optimized for searchability and quick recognition.

### Guidelines

1. **Remove internal jargon** - Use widely understood terms
   - Bad: "Ralph loop directories" → Good: "research directories"
   - Bad: "compound branch" → Good: "stacked/dependent branches"

2. **Add action keywords** - Include verbs that describe what happens
   - Bad: "Resolve merge conflicts" → Good: "Interactively resolve merge conflicts"
   - Bad: "Prune local branches" → Good: "Clean up local branches"

3. **Use standard terminology** - Prefer terms from common git/dev workflows
   - "stacked branches" over "compound branches"
   - "feature branch" over "compound branch"

4. **Include specific capabilities** - For multi-purpose skills, list key features
   - Bad: "Analyze code for refactoring opportunities"
   - Good: "Analyze code for refactoring: helper extraction, nested functions, test factories"

### Examples

| Before | After | Improvement |
|--------|-------|-------------|
| Poll a PR for new comments... | Watch a PR in background and address new comments... | Added "background" keyword |
| Extract changes from a compound branch... | Extract independent changes from a feature branch into a new PR... | Removed jargon, clarified output |
| Initialize a new Ralph loop research project... | Initialize an iterative research project with spec and progress tracking | Removed internal jargon |

**Why this matters:** Better descriptions help me recognize when a skill applies and help users find skills via search.

### Routing Hints

Add "Use when..." routing hints to the description only when the skill name + functional description isn't sufficient for agent inference — e.g., opaque names, overlapping skills needing disambiguation. Skip routing hints when the name already communicates intent (e.g., `git:create-pr`).

## Making Skills Portable

Skills should work across different projects, not just the one where they were created. Periodically audit skills to remove project-specific content.

### What to Look For

| Project-Specific | Generic Replacement |
|------------------|---------------------|
| Class names from your codebase (`BackTester`, `WalkForwardTester`) | Domain-neutral names (`DataProcessor`, `BatchProcessor`) |
| File paths from your project (`walkforward.py`, `logic/models/`) | Generic paths (`pipeline.py`, `src/models/`) |
| Internal API names (`Schwab API`) | Generic references (`External API`, `Payment API`) |
| Project branch names (`docs/ralph-comparison-learnings`) | Common patterns (`feature/user-settings`) |

### What to Keep

- **Industry terminology** - Terms widely used in your domain (e.g., "Ralph loop" for iterative research)
- **Tool names** - Standard tools like `gh`, `git`, `pytest`, `ruff`
- **Generic software patterns** - Auth, JWT, config files (these appear in most projects)

### Audit Process

1. Search skills for project-specific class/file names
2. Check both SKILL.md and reference files (patterns, templates, examples)
3. Replace with domain-neutral examples that illustrate the same concept
4. Verify the examples still make sense in the generic context

**Why this matters:** Portable skills can be copied to new projects or shared with others without modification.

## Cross-Referencing Between Reference Files

When splitting a large file into multiple focused reference files, add a "Related References" section at the bottom of each to help navigate between related content:

```markdown
## Related References

- other-file.md - Brief description of what it covers
- another-file.md - Brief description of what it covers
```

## Conditional vs Eager References

Prefer conditional references over `@`-prefixed eager loading to keep context lean.

### The Problem

`@filename.md` in the Reference Files section loads the full file into context on every skill invocation — even when the content is only needed in specific branches (e.g., Skill-type learnings, error recovery). Four eagerly-loaded files at ~100-300 lines each adds ~790 tokens before the orchestrator does anything.

### The Fix

List reference files WITHOUT the `@` prefix. Add a note on when each should be read:

```markdown
## Reference Files (conditional — read only when needed)
- content-type-decisions.md — Read if categorization is ambiguous
- skill-template.md — Read only when writing a new skill
```

The orchestrator uses the Read tool to load files at the point they're needed, then passes relevant content to subagents.

### When to Use `@` (Eager)

Only when the file is needed on EVERY invocation AND is small (<30 lines). Otherwise, conditional.

### When to Use Conditional

- File is only needed in specific branches of the skill logic
- File is >30 lines
- File is only needed by a subagent (pass via Task prompt, not orchestrator context)

## Skill Composition

When skills can be used together, add cross-references to help users discover related workflows:

1. **Add "Related Skills" section** to skills that have natural follow-ups (table with Next Step → Skill columns)
2. **Reference prerequisite skills** in Important Notes (e.g., "Use `/git:explore-pr` first if you need to understand the PR before splitting")

## Validating Skill Changes

After modifying or creating skills, verify before committing:

1. **Structure** — Directory exists, old files removed (if migrated)
2. **Content** — Key content present in SKILL.md, reference files linked correctly
3. **Permissions** — Required Bash patterns added to settings.json
4. **Function** — Test the actual commands the skill uses when possible

## Analyzing Skills for Token Optimization

Periodically review skills 100+ lines to identify content extractable into conditional reference files.

**Categorize content by extraction potential:**

| Content Type | Extract? | Threshold |
|---|---|---|
| Core instructions | No | Always needed |
| Templates, examples, reference tables | Yes | 10+ lines, only needed situationally |
| Edge case documentation | Maybe | 20+ lines |

**Evaluate extraction benefit:** 50+ lines situational = high value, 20-50 = medium, <20 = overhead exceeds benefit. Don't extract content under 15 lines, needed on every invocation, or that loses context when separated.

## Gap vs Inconsistency Boundary

When a skill categorizes findings into "gaps" and "inconsistencies," define them with a non-overlapping boundary: a **gap** means code has a pattern completely absent from docs; an **inconsistency** means docs exist but contradict the code. Add a preamble to each category excluding the other to prevent items from appearing in both.

## Orchestrator/Agent Separation for Multi-Step Skills

Split SKILL.md into two files when a skill has a multi-step background workflow:

1. **Orchestrator (SKILL.md)** — User interaction only: identifying items, displaying for selection, gathering input. Target ~80 lines. List reference files as conditional (no eager `@`).
2. **Background agent steps (separate .md)** — Autonomous workflow executed by a Task agent. Use aliases at top, decision tables for branching, inline warnings at point of use, error recovery at bottom.

## Related References

- skill-template.md - Template and file organization for skills
- content-type-decisions.md - Deciding if something should be a skill, guideline, or learning
- iterative-loop-design.md - Patterns for Ralph-style research loops
