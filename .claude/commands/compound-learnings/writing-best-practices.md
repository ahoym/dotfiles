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

**Why this matters:** Without explicit naming, later steps become ambiguous. "Add the files" is unclear; "Add `FILES_TO_EXTRACT`" is unambiguous.

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
- Verb-noun or noun-verb: `/split-commit`, `/preview-conflicts`
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

1. Search skills for project-specific class/file names:
   ```bash
   grep -r "YourClassName\|your_file.py" .claude/commands/
   ```

2. Check both SKILL.md and reference files (patterns, templates, examples)

3. Replace with domain-neutral examples that illustrate the same concept

4. Verify the examples still make sense in the generic context

**Why this matters:** Portable skills can be copied to new projects or shared with others without modification.

## Cross-Referencing Between Reference Files

When splitting a large file into multiple focused reference files, add cross-references to help users navigate between related content.

### Pattern

Add a "Related References" section at the bottom of each reference file:

```markdown
## Related References

- @other-file.md - Brief description of what it covers
- @another-file.md - Brief description of what it covers
```

### When to Cross-Reference

- Files that cover complementary topics (e.g., "skill template" ↔ "writing best practices")
- Files where readers of one are likely to need the other
- Files that were split from a common source

### Benefits

- Helps users discover related content they might need
- Creates a navigable web of documentation
- Makes the split files feel cohesive rather than fragmented

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

1. **Add "Related Skills" section** to skills that have natural follow-ups:

```markdown
## Related Skills

After exploring a PR, you may want to:

| Next Step | Skill |
|-----------|-------|
| Address review comments | `/git-address-pr-review` |
| Check merge status | `/git-pr-status` |
```

2. **Reference prerequisite skills** in Important Notes:

```markdown
## Important Notes

- Use `/git-explore-pr` first if you need to understand the PR before splitting
```

**Why this matters:** Skills are more powerful when composed. Cross-references help users discover workflows they wouldn't find otherwise.

## Validating Skill Changes

After modifying or creating skills, run validation checks before committing.

### Structure Checks

```bash
# Verify directory structure
ls -la .claude/commands/<skill-name>/

# Confirm old file removed (if migrated)
test -f .claude/commands/<old-file>.md && echo "OLD FILE EXISTS" || echo "OK"
```

### Content Checks

```bash
# Key content present in skill
grep -q "<expected-content>" .claude/commands/<skill>/SKILL.md && echo "OK" || echo "MISSING"

# Reference files linked correctly
grep -q "@<reference-file>" .claude/commands/<skill>/SKILL.md && echo "OK" || echo "MISSING"
```

### Permission Checks

```bash
# Permissions added for Bash commands
grep "<command-pattern>" .claude/settings.json
```

### Functional Test

When possible, test the actual command the skill uses:

```bash
# Example: Test PR detection for git-create-pr skill
gh pr list --head <branch>
```

### Why Validate Skills?

- Catches broken references before users hit them
- Confirms permissions won't block skill execution
- Verifies migrations completed cleanly
- Documents that the skill was tested

## Analyzing Skills for Token Optimization

Periodically review skills to identify content that could be extracted into reference files, reducing tokens loaded per invocation.

### Analysis Workflow

1. **List all skills and their line counts**:
   ```bash
   wc -l .claude/commands/*/SKILL.md | sort -n
   ```

2. **Identify large skills** (100+ lines) as candidates

3. **For each candidate, categorize content**:
   | Content Type | Extract? | Reason |
   |--------------|----------|--------|
   | Core instructions | No | Always needed |
   | Templates (10+ lines) | Yes | Only needed when generating output |
   | Examples/reference tables | Yes | Only needed situationally |
   | Edge case documentation | Maybe | Extract if 20+ lines |

4. **Check for situational content** - sections only needed in specific scenarios:
   - Reply templates (only when replying)
   - Verification checklists (only when verifying)
   - Error handling guides (only when errors occur)

5. **Evaluate extraction benefit**:
   - **High value**: 50+ lines of situational content
   - **Medium value**: 20-50 lines of situational content
   - **Low value**: <20 lines (overhead of separate file may not be worth it)

### Example Analysis

```
git-address-pr-review/SKILL.md (309 lines)
├── Core instructions: 180 lines (keep)
├── Reply Templates: 35 lines (extract - only needed when replying)
├── LGTM Verification: 50 lines (extract - only needed for LGTM comments)
└── Important Notes: 44 lines (keep - always relevant)

Result: Extract 85 lines → SKILL.md reduced to 224 lines
```

### When NOT to Extract

- Content under 10-15 lines (overhead exceeds benefit)
- Content needed on every invocation
- Content that would lose context when separated

## Related References

- @skill-template.md - Template and file organization for skills
- @content-type-decisions.md - Deciding if something should be a skill, guideline, or learning
- @iterative-loop-design.md - Patterns for Ralph-style research loops
