---
description: "Initialize an iterative research project with spec and progress tracking."
---

# Initialize Ralph Research Project

Create a new Ralph loop project in an isolated git worktree with customized spec and progress files.

## Usage

- `/ralph:init <topic>` - Create project for the given topic
- `/ralph:init` - Will prompt for topic

## Reference Files

- @spec-template.md - Template for spec.md with v2 features (dynamic tasks, deep research workflow)
- @progress-template.md - Template for progress.md with questions section

## Instructions

1. **Get project topic**:
   - If `$ARGUMENTS` provided, use that as the topic
   - Otherwise, ask: "What topic should this research project cover?"

2. **Derive project name**:
   - Convert topic to kebab-case for directory name (e.g., "Monte Carlo Simulation" → "monte-carlo-simulation")
   - Keep it concise (3-4 words max)

3. **Check for existing worktree**:
   - If `.claude/worktrees/ralph-<project-name>/` already exists, offer three options:
     1. **Reuse** — keep existing worktree, skip creation
     2. **Remove and recreate** — `git worktree remove` then create fresh
     3. **Abort** — do nothing

4. **Create worktree**:
   ```bash
   git worktree add .claude/worktrees/ralph-<project-name> -b research/<project-name> HEAD
   ```
   - If the branch `research/<project-name>` already exists, use it without `-b`:
     ```bash
     git worktree add .claude/worktrees/ralph-<project-name> research/<project-name>
     ```

5. **Create project directory inside worktree**:
   ```bash
   mkdir -p .claude/worktrees/ralph-<project-name>/docs/learnings/<project-name>
   ```

6. **Create spec.md** inside worktree using @spec-template.md:
   - Write to `.claude/worktrees/ralph-<project-name>/docs/learnings/<project-name>/spec.md`
   - Replace `<PROJECT_NAME>` with the topic (title case)
   - Replace `<TOPIC>` with the topic
   - Adjust References section to use correct relative path to repository root

7. **Create progress.md** inside worktree using @progress-template.md:
   - Write to `.claude/worktrees/ralph-<project-name>/docs/learnings/<project-name>/progress.md`
   - Replace `<TOPIC>` with the topic

8. **Confirm to user**:
   ```
   Created Ralph research project in worktree.

   Worktree: .claude/worktrees/ralph-<project-name>/
   Branch:   research/<project-name>
   Project:  docs/learnings/<project-name>/

   Next steps:
   cd .claude/worktrees/ralph-<project-name>
   bash ~/.claude/lab/ralph/wiggum.sh docs/learnings/<project-name>
   ```

## Example

```
/ralph:init options pricing models

Created Ralph research project in worktree.

Worktree: .claude/worktrees/ralph-options-pricing-models/
Branch:   research/options-pricing-models
Project:  docs/learnings/options-pricing-models/

Next steps:
cd .claude/worktrees/ralph-options-pricing-models
bash ~/.claude/lab/ralph/wiggum.sh docs/learnings/options-pricing-models
```

## Learnings

### Overwrite Guard: Offer "Create Alongside"

When a project directory already exists, offer three options — not just overwrite/abort:

1. **Overwrite** — replace existing project
2. **Create alongside** — new directory with `-1b` suffix (e.g., `topic-1b/`) for parallel comparison
3. **Abort** — keep existing, do nothing

Use `-1b` (not `-v2`) because parallel research is for comparison, not versioning. If `-1b` exists, increment: `-1c`, `-1d`, etc.
