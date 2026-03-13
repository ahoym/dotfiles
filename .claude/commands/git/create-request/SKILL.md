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
- @~/.claude/skill-references/platform-detection.md — Platform detection for GitHub/GitLab

## Pre-Review Checklist

Before creating the review, verify these items are complete:

- [ ] All tests pass locally
- [ ] Code formatted with linter
- [ ] No sensitive data in code or logs
- [ ] Metrics added for new operations (if applicable)
- [ ] Error handling implemented
- [ ] Documentation updated (if needed)

## Instructions

1. **Detect platform** — follow `@~/.claude/skill-references/platform-detection.md` to determine GitHub vs GitLab. Set variables for the rest of the skill:

   | Variable | GitHub | GitLab |
   |----------|--------|--------|
   | `CLI` | `gh` | `glab` |
   | `REVIEW_UNIT` | PR | MR |
   | `CREATE_CMD` | `gh pr create` | `glab mr create` |
   | `LIST_CMD` | `gh pr list --head` | `glab mr list --source-branch` |
   | `EDIT_CMD` | `gh pr edit` | `glab mr update` |
   | `BASE_FLAG` | `--base` | `--target-branch` |
   | `BODY_FLAG` | `--body` | `--description` |

2. **Gather context** (run in parallel):
   - `git status` - Check for uncommitted changes
   - `git branch --show-current` - Get current branch name
   - `git log origin/main..HEAD --oneline` - See commits to include (adjust base as needed)
   - `git diff origin/main..HEAD --stat` - See files changed

3. **Check for uncommitted changes**:
   - If there are uncommitted changes, ask user if they want to commit first
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
   - **Unfixable**: report to user and ask whether to proceed

   Skip checks that aren't configured for the project. Don't install new tools.

5. **Check for existing review**:
   ```bash
   $LIST_CMD <current-branch>
   ```
   - If a review already exists, ask user: "$REVIEW_UNIT #N already exists for this branch. Update its description instead of creating new?"
   - If yes, use `$EDIT_CMD` instead of `$CREATE_CMD`

6. **Determine base branch**:
   - If `$ARGUMENTS` provided, use that as base
   - If branch name suggests a parent (e.g., `feature/foo-part2` might be based on `feature/foo`), ask user
   - Default to `main`

7. **Infer Jira ticket** (if applicable):
   - Extract Jira ticket ID from the branch name (common patterns: `feature/PROJ-123`, `bugfix/PROJ-456`, `PROJ-789-description`)
   - Look for Jira ticket references in commit messages
   - If no ticket can be inferred, leave the URL incomplete for the user to fill in

8. **Check if push needed**:
   - If local is ahead of remote, push first: `git push -u origin <branch>`

9. **Compose review body** — Read `request-body-template.md` from the skill's base directory. Structure the body following that template.

10. **Run the command**:

For new review:
```bash
$CREATE_CMD $BASE_FLAG <base-branch> --title "<title>" $BODY_FLAG "$(cat <<'EOF'
<body content>
EOF
)"
```

For existing review:
```bash
$EDIT_CMD <number> $BODY_FLAG "$(cat <<'EOF'
<body content>
EOF
)"
```

11. **Return the review URL** to the user.
