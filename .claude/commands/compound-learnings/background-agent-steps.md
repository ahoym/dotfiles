# Background Agent Steps

Steps for the background Task agent launched by the compound-learnings orchestrator.

## Aliases

- `LIFECYCLE` = the lifecycle command provided by the orchestrator (e.g., `bash ~/.claude/commands/compound-learnings/worktree-lifecycle.sh`). IMPORTANT: use `~` literally — do NOT expand to an absolute path, so the command matches the permission pattern in settings.
- `WORKTREE` = `../worktree-compound-learnings`

Use these as shorthand in the instructions below. In actual commands, expand to their full values.

## Step 1: Create worktree

| `$ARGUMENTS` | Action |
|---|---|
| `#<number>` | `gh pr view <number> --json headRefName --jq '.headRefName'` to get branch, then `$LIFECYCLE attach $WORKTREE "$BRANCH"` |
| `<name>` | `$LIFECYCLE attach $WORKTREE "$ARGUMENTS"` |
| _(empty)_ | Derive topic from the primary learning, then `$LIFECYCLE create $WORKTREE docs/<topic>-learnings` |

Store the branch name as `TARGET_BRANCH`.

## Step 2: Write files

For each item in `SELECTED_LEARNINGS`:

1. **Try reading the file first** to check if it exists:
   ```bash
   $LIFECYCLE read $WORKTREE <relative-path>
   ```
   If the exit code is non-zero, the file is new — write from scratch. If it succeeds, merge new content into the existing content.

2. **Write or append the file**:
   - **New file** (read returned non-zero): use `write` with full content
   - **Existing file**: prefer `append` to add new sections without reproducing existing content

   ```bash
   # New file:
   $LIFECYCLE write $WORKTREE <relative-path> <<'ENDOFLEARNINGFILE'
   # Full file content here
   ENDOFLEARNINGFILE

   # Existing file — append new section only:
   $LIFECYCLE append $WORKTREE <relative-path> <<'ENDOFLEARNINGFILE'

   ## New Section Title
   New content here
   ENDOFLEARNINGFILE
   ```

**File placement rules:**
- **Skills** → `.claude/commands/<skill-name>/`
- **Guidelines** → `.claude/guidelines/<guideline-name>.md`
- **Learnings** → `docs/claude-learnings/<topic>.md`

> **WARNING**: Do NOT use Write/Edit tools — subagents cannot access worktree paths outside the project sandbox. All file operations MUST go through the lifecycle script.

> **HEREDOC NOTE**: Use a unique delimiter like `ENDOFLEARNINGFILE` — avoid `CONTENT`, `EOF`, or common words that may appear in the file body. The heredoc redirect (`<<'...'`) must keep `bash` as the first word of the command so it matches the pre-approved permission pattern.

## Step 3: Commit

```bash
$LIFECYCLE commit $WORKTREE "$(cat <<'EOF'
Add <brief description> to <file>

- <bullet for each learning>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

## Step 4: Push + PR

Push from the **main repo directory** (not `git -C <worktree>` — worktrees share the git object database, and `git -C ... push` won't match the `Bash(git push:*)` permission):

```bash
git push origin <TARGET_BRANCH>
```

**Check if a PR already exists for the branch**:
```bash
gh pr list --head <TARGET_BRANCH> --json number,url --jq '.[0]'
```

**If PR exists**: Done — changes are pushed. Optionally use `gh pr edit <number> --body ...` to update the PR body with newly added learnings.

**If no PR exists, create one**:
1. Read `~/.claude/commands/git-create-pr/pr-body-template.md` for the PR body format
2. Create the PR following that template:
```bash
gh pr create --head <TARGET_BRANCH> --base main --title "<title>" --body "$(cat <<'EOF'
<body following pr-body-template.md format>
EOF
)"
```

## Step 5: Cleanup + Report

```bash
$LIFECYCLE remove $WORKTREE
```

Output a report in this exact format:

```
Updated files:
- <path> — <what was added> (Utility: <High/Medium/Low>)

<Created PR #N: <url> | Pushed to PR #N: <url>>
Cleaned up worktree.
```

## Error Recovery

- **Heredoc collision**: If a write fails because the delimiter appears in the file body, retry with a different unique delimiter (e.g., `LEARNINGEOF_42`).
- **File doesn't exist**: If `read` returns non-zero, the file is new — write from scratch (do not treat as an error).
