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

- `~/.claude/skill-references/platform-detection.md` — read if platform not yet detected this session
- `~/.claude/skill-references/github/pr-management.md` / `gitlab/pr-management.md` — Create/update PR, check existing
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

1. **Detect platform** — if not already detected this session, read `~/.claude/skill-references/platform-detection.md` and follow its logic to determine GitHub vs GitLab. Then read `~/.claude/skill-references/{github,gitlab}/pr-management.md` (matching detected platform).

2. **Gather context** (run in parallel):
   - `git status` - Check for uncommitted changes
   - `git branch --show-current` - Get current branch name
   - `git log origin/main..HEAD --oneline` - See commits to include (adjust base as needed)
   - `git diff origin/main..HEAD --stat` - See files changed

3. **Check for uncommitted changes**:
   - If there are uncommitted changes, ask the operator if they want to commit first
   - Do not proceed with review creation if there are uncommitted changes

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

5. **Check for existing review** — using the section index from `pr-management.md` (loaded in step 1), `Read` the file at `check-for-existing-review`'s offset/limit, substitute placeholders, and execute.
   - If a review already exists, ask the operator: "$REVIEW_UNIT #N already exists for this branch. Update its description instead of creating new?"
   - If yes, use `$EDIT_CMD` instead of `$CREATE_CMD`

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

10. **Write body and create/update review** — Using the section index from `pr-management.md` (loaded in step 1), `Read` the file at `create-or-update-request`'s offset/limit, substitute placeholders, and execute. Use `<BRANCH_NAME>` in the temp filename for parallel safety.

11. **Clean up** — remove the temp body file and empty `tmp/change-request-replies/` directory (per the platform commands section).

12. **Return the review URL** to the operator.
