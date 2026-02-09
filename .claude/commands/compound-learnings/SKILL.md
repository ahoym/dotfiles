---
description: Capture session learnings and save to skills, guidelines, or reference docs
---

# Compound Learnings

Save new patterns and learnings from the current session into skills or guidelines.

## Usage

- `/compound-learnings` - Capture learnings from current session (creates new branch)
- `/compound-learnings #<pr-number>` - Add learnings to an existing PR's branch
- `/compound-learnings <branch-name>` - Add learnings to an existing branch

## Prerequisites

Add these to your project's `.claude/settings.local.json` for background execution:

- `Bash(bash ~/.claude/commands/compound-learnings/worktree-lifecycle.sh:*)`
- `Bash(git push:*)`
- `Bash(gh pr create:*)`
- `Bash(gh pr edit:*)`
- `Bash(gh pr list:*)`
- `Bash(gh pr view:*)`

## Reference Files (conditional — read only when needed)

- `content-type-decisions.md` — Read if categorization is ambiguous
- `skill-template.md` — Read only when a Skill-type learning is selected
- `writing-best-practices.md` — Read only when a Skill-type learning is selected
- `iterative-loop-design.md` — Read only when learning involves iterative/loop patterns
- `background-agent-steps.md` — Read in step 3 to pass to background agent

## Instructions

1. **Identify learnings from current session**:
   - Review the conversation for new patterns, processes, or guidelines discovered
   - List each learning with a brief description
   - Categorize using this decision tree:
     - Command with clear, repeatable steps? → **Skill**
     - Changes behavior or approach? → **Guideline**
     - Reference info, patterns, or examples? → **Learning**

2. **Display learnings for selection**:
   ```
   Identified learnings from this session:

   | # | Learning | Type | Target File | Utility |
   |---|----------|------|-------------|---------|
   | 1 | LGTM verification process | Skill | address-pr-review.md | High - novel project pattern |
   | 2 | Co-authorship in PR replies | Guideline | git-workflow.md | Low - already documented |
   | 3 | SessionEnd hook configuration | Learning | ci-cd.md | High - useful reference |
   ```

   **Utility ratings** (self-assessment of value to Claude):
   - **High** - Novel pattern I wouldn't know without documenting
   - **Medium** - Useful reminder, but I could rediscover if needed
   - **Low** - Standard knowledge or already documented (shown for transparency)

   Use `AskUserQuestion` with multi-select to let user choose which learnings to capture.
   Store selected items as `SELECTED_LEARNINGS`.

   **Do NOT proceed until user selects.** If no learnings selected, inform user and exit.

3. **Launch background agent**:
   - Read `background-agent-steps.md` and include its full content in the Task prompt
   - If any Skill-type learning is selected: also read `skill-template.md` and `writing-best-practices.md`, include relevant excerpts in the prompt
   - Resolve the absolute path to `worktree-lifecycle.sh` (relative to this skill's directory) and pass it as the `LIFECYCLE` value
   - Provide the background agent with:
     - `SELECTED_LEARNINGS` (descriptions, types, target files, content to write)
     - `$ARGUMENTS` (PR number, branch name, or empty)
     - Current repo's working directory path
     - The resolved absolute path to `worktree-lifecycle.sh`
     - Enough session context to write the learning content
     - Which target directories already exist and which need creating
   - Launch with `run_in_background: true`

## Important Notes

- **Background execution**: After learning selection, all work runs via background-agent-steps.md in a Task agent
- Prefer updating existing files over creating new ones
- Keep learnings atomic — one concept per section
- **Type selection when unsure**: Learning > Guideline > Skill (least to most structured)
- Be honest in utility self-assessments
