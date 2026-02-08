---
description: Capture session learnings and save to skills, guidelines, or reference docs
---

# Compound Learnings

Save new patterns and learnings from the current session into skills or guidelines.

## Usage

- `/compound-learnings` - Capture learnings from current session (creates new branch)
- `/compound-learnings #<pr-number>` - Add learnings to an existing PR's branch
- `/compound-learnings <branch-name>` - Add learnings to an existing branch

## Reference Files

- @content-type-decisions.md - How to decide if content is a skill, guideline, or learning
- @skill-template.md - Template and file organization for new skills
- @writing-best-practices.md - Conventions for writing effective skills
- @iterative-loop-design.md - Patterns for Ralph-style research loops

## Prerequisites

Add these to your project's `.claude/settings.local.json` for background execution:

- `Bash(git fetch:*)`
- `Bash(git worktree add:*)`
- `Bash(git worktree remove:*)`
- `Bash(git push:*)`
- `Bash(gh pr create:*)`
- `Bash(bash ~/.claude/commands/compound-learnings/worktree-commit.sh:*)`
- `Write(path:../worktree-*/**)`
- `Edit(path:../worktree-*/**)`

## Instructions

1. **Identify learnings from current session**:
   - Review the conversation for new patterns, processes, or guidelines discovered
   - List each learning with a brief description
   - Categorize as one of:
     - **Skill** - Actionable, repeatable task with clear steps (invoked via `/skill-name`)
     - **Guideline** - Rules and practices that shape behavior (loaded via CLAUDE.md)
     - **Learning** - Reference knowledge, patterns, or examples (useful info that doesn't fit skill/guideline)

2. **Display learnings for selection**:
   ```
   Identified learnings from this session:

   | # | Learning | Type | Target File | Utility |
   |---|----------|------|-------------|---------|
   | 1 | LGTM verification process | Skill | address-pr-review.md | High - novel project pattern |
   | 2 | Co-authorship in PR replies | Guideline | git-workflow.md | Low - already in git-workflow.md |
   | 3 | SessionEnd hook configuration | Learning | ci-cd.md | High - useful reference |
   ```

   **Utility ratings** (self-assessment of value to Claude):
   - **High** - Novel pattern I wouldn't know without documenting
   - **Medium** - Useful reminder, but I could rediscover if needed
   - **Low** - Standard knowledge or already documented (shown for transparency)

   Use `AskUserQuestion` with multi-select to let user choose which learnings to capture.
   Store selected items as `SELECTED_LEARNINGS`.

   If no learnings are selected, inform user and exit.

3. **Run steps 3–7 as a background Task agent**:

   After the user selects learnings, use the `Task` tool with `run_in_background: true` to execute the remaining steps autonomously. Provide the task agent with:
   - The `SELECTED_LEARNINGS` (descriptions, types, target files, content to write)
   - The `$ARGUMENTS` (PR number, branch name, or empty)
   - The current repo's working directory path
   - Enough session context to write the learning content
   - Which target directories already exist and which need creating, so the agent can write files immediately without exploring
   - If any selected learnings are of type Skill, read @skill-template.md and @writing-best-practices.md and include relevant excerpts so the background agent follows conventions

   The task agent then executes steps 4–8 below without further user interaction.

4. **Create worktree for target branch**:

   Store the worktree path as `WORKTREE_PATH` (e.g., `../worktree-compound-learnings`).

   **If `$ARGUMENTS` starts with `#` (PR number)**:
   ```bash
   TARGET_BRANCH=$(gh pr view <number> --json headRefName --jq '.headRefName')
   git fetch origin "$TARGET_BRANCH"
   git worktree add ../worktree-compound-learnings "$TARGET_BRANCH"
   ```

   **If `$ARGUMENTS` provided, check if it's an existing branch**:
   ```bash
   git fetch origin
   git branch -r | grep -q "origin/$ARGUMENTS"
   git worktree add ../worktree-compound-learnings "$ARGUMENTS"
   ```
   Store as `TARGET_BRANCH`.

   **If no arguments, create new branch**:
   - Derive topic from the primary learning (e.g., "lgtm-response", "hook-configuration")
   ```bash
   git fetch origin main
   git worktree add -b docs/<derived-topic>-learnings ../worktree-compound-learnings origin/main
   ```
   Store `docs/<derived-topic>-learnings` as `TARGET_BRANCH`.

5. **Update appropriate files** (in `WORKTREE_PATH`):
   - For each item in `SELECTED_LEARNINGS`:
     - **Skills** go in `<WORKTREE_PATH>/.claude/commands/<skill-name>/`
     - **Guidelines** go in `<WORKTREE_PATH>/.claude/guidelines/<guideline-name>.md`
     - **Learnings** go in `<WORKTREE_PATH>/docs/claude-learnings/<topic>.md` (e.g., `python-specific.md`, `ci-cd.md`)
   - Add new sections or update existing ones
   - Include examples from the session where helpful
   - See @skill-template.md for skill structure and @writing-best-practices.md for conventions

6. **Commit changes** (using the helper script to avoid permission prompts):
   ```bash
   bash ~/.claude/commands/compound-learnings/worktree-commit.sh <WORKTREE_PATH> "$(cat <<'EOF'
   Add <brief description> to <file>

   - <bullet point for each learning>

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```

7. **Push and create PR** (from the main repo — worktrees share the git object database):
   ```bash
   git push origin <TARGET_BRANCH>
   ```

   **If adding to existing PR**: Done — changes are pushed to the PR's branch.

   **If new branch, create PR**:
   ```bash
   gh pr create --head <TARGET_BRANCH> --base main --title "<title>" --body "$(cat <<'EOF'
   ## Summary

   Capture learnings from <context, e.g., "PR #10 review cycle">.

   ## Changes

   ### <File 1>
   - <What was added>

   ### <File 2>
   - <What was added>

   ## Context

   These patterns emerged from <brief description of the session/task>.
   EOF
   )"
   ```

8. **Cleanup worktree and report**:
   ```bash
   git worktree remove ../worktree-compound-learnings
   ```
   Report to user:
   - List files updated
   - Link to PR (if created) or PR that was updated
   - Summary of learnings captured

## Example Output

### New branch
```
Identified learnings from this session:

| # | Learning | Type | Target File | Utility |
|---|----------|------|-------------|---------|
| 1 | Respond to mismatched LGTM | Skill | address-pr-review.md | High - project-specific flow |
| 2 | Confirm valid LGTM | Skill | address-pr-review.md | High - project-specific flow |

Creating worktree at ../worktree-compound-learnings with branch docs/lgtm-response-learnings...

Updated files:
- .claude/commands/address-pr-review.md
  - Added "Responding to Mismatched LGTM" section
  - Added "Confirming Valid LGTM" section

Created PR #19: https://github.com/owner/repo/pull/19
Cleaned up worktree.
```

### Adding to existing PR
```
Identified learnings from this session:

| # | Learning | Type | Target File | Utility |
|---|----------|------|-------------|---------|
| 1 | Skill composition pattern | Guideline | skill-authoring-guide.md | Medium - useful reminder |

Creating worktree at ../worktree-compound-learnings with branch docs/lgtm-response-learnings...

Updated files:
- .claude/commands/compound-learnings/skill-authoring-guide.md
  - Added "Skill Composition" section

Pushed to PR #19: https://github.com/owner/repo/pull/19
Cleaned up worktree.
```

## Important Notes

- **CRITICAL: Use AskUserQuestion in step 2** - Do NOT proceed to step 3 until user selects learnings. Use multi-select to let them choose which items to capture.
- **Background execution**: After learning selection, steps 3–8 run as a background Task agent. The user should not need to approve any further actions.
- **Avoid `cd` in Bash commands**: Commands starting with `cd` don't match pre-approved permission patterns like `Bash(git add:*)`, causing unnecessary approval prompts. The helper script `worktree-commit.sh` handles add+commit inside the worktree. Run `git push` and `gh pr create` from the main repo directory (worktrees share the object database).
- **Permissions**: See Prerequisites section above for required `.claude/settings.local.json` entries.
- **Worktree isolation**: Using a worktree means the user's main working directory is not affected. They can continue working while learnings are captured.
- Capture learnings while they're fresh in context
- Prefer updating existing files over creating new ones
- Include concrete examples from the session
- Keep learnings atomic - one concept per section
- **Type selection**: If unsure, use this order: Learning (least commitment) → Guideline → Skill (most structured)
- Be honest in utility self-assessments - Low utility items are shown for transparency but users often skip them
