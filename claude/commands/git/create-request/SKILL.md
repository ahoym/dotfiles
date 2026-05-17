---
name: create-request
description: "Create a request (pull request or merge request) or update an existing one following project conventions."
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`
- Commits on branch: !`git log origin/main..HEAD --oneline 2>/dev/null | head -20`

# Create Review

Create a pull request (GitHub) or merge request (GitLab), or update an existing one, following project conventions.

## Usage

- `/git:create-request` - Create review targeting main
- `/git:create-request <base-branch>` - Create review targeting specified base branch

## Reference Files (conditional — read only when needed)

- `request-body-template.md` — Read before composing review body (step 9). Located in the skill's base directory.

## Pre-Review Checklist

Before creating the review, verify these items are complete:

- [ ] All tests pass locally
- [ ] Code formatted with linter
- [ ] No sensitive data in code or logs
- [ ] Metrics added for new operations (if applicable)
- [ ] Error handling implemented
- [ ] Documentation updated (if needed)

## Instructions

1. **Gather platform commands** — platform-specific commands are inlined below via `!` preprocessing. No detection or file loading needed.

2. **Gather context** (run in parallel):
   - `git status` - Check for uncommitted changes
   - `git branch --show-current` - Get current branch name
   - `git log origin/main..HEAD --oneline` - See commits to include (adjust base as needed)
   - `git diff origin/main..HEAD --stat` - See files changed

3. **Handle uncommitted changes**:
   Based on `git status` from step 2:

   - **Clean working tree** → proceed to step 4.
   - **Dirty + on base branch** — offer:
     - (a) Create a new branch, stage all uncommitted, commit
     - (b) Create a new branch, stage a subset (operator specifies which files), commit
   - **Dirty + on feature branch** — offer:
     - (a) Commit all uncommitted to the current branch
     - (b) Commit a subset (leave the rest uncommitted)
     - (c) Stash, proceed with only the already-committed state

   **Multi-concern flag**: if the uncommitted set spans logically distinct concerns (e.g., unrelated features, docs + code, migration + cleanup), surface the grouping before the operator picks. Suggest running this skill once per concern — each iteration stages only the relevant subset — rather than bundling into one PR.

   After the chosen action completes, re-check `git status` and continue to step 4 only when the tree is clean (or stashed).

4. **Run verifications**:
   Run any available automated checks **before pushing**. Look for project-standard commands (in CLAUDE.md, pyproject.toml, package.json, Makefile, etc.). Common checks:
   - **Tests** (e.g., `pytest`, `npm test`)
   - **Lint** (e.g., `ruff check`, `eslint`)
   - **Type check** (e.g., `pyright`, `tsc --noEmit`)
   - **Format** (e.g., `ruff format --check`, `prettier --check`)

   Run available checks in parallel. If any fail:
   - **Auto-fixable** (lint/format): fix, commit the fix, and re-run to confirm
   - **Test/type failures**: fix, commit, re-run
   - **Unfixable**: report to the operator and ask whether to proceed

   Skip checks that aren't configured for the project. Don't install new tools.

5. **Check for existing review:**
   !`cat ~/.claude/platform-commands/check-existing-review.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
   - If a review already exists, ask the operator: "Review #N already exists for this branch. Update its description instead of creating new?"

6. **Determine base branch**:
   - If `$ARGUMENTS` provided, use that as base
   - If branch name suggests a parent (e.g., `feature/foo-part2` might be based on `feature/foo`), ask the operator
   - Default to `main`

7. **Infer Jira ticket** (if applicable):
   - Extract Jira ticket ID from the branch name (common patterns: `feature/PROJ-123`, `bugfix/PROJ-456`, `PROJ-789-description`)
   - Look for Jira ticket references in commit messages
   - If no ticket can be inferred, leave the URL incomplete for the operator to fill in

8. **Check if push needed**:
   - If local is ahead of remote, push first: `git push -u origin <branch>`

9. **Compose review body** — Read `request-body-template.md` from the skill's base directory. Structure the body following that template.

10. **Write body and create/update review** — Use `<BRANCH_NAME>` in the temp filename for parallel safety.
    **Create:**
    !`cat ~/.claude/platform-commands/create-review.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
    **Update (if existing review):**
    !`cat ~/.claude/platform-commands/update-review.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`

11. **Clean up** — remove the temp body file and empty `tmp/claude-artifacts/change-request-replies/` directory (per the platform commands section).

12. **Return the review URL** to the operator.
