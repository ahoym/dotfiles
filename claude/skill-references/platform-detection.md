---
description: "DEPRECATED — Platform is now resolved at setup time via setup-claude.sh. Skills use !`cat ~/.claude/platform-commands/<cmd>.sh` instead. Retained as fallback for subagent sessions that lack the symlink."
---

# Platform Detection (Deprecated)

> **Note:** Skills are being migrated away from this file. Platform commands are inlined via `!` preprocessing from `~/.claude/platform-commands/` (a symlink to the correct platform's `commands/` directory, created by `setup-claude.sh`). This file is retained only as a fallback for `claude -p` subagent sessions that may not have the symlink.

Before executing any platform-specific commands, detect whether the repository uses GitHub or GitLab.

## Detection Logic

Run these checks in order and use the first match:

1. **Git remote URL** (most reliable):
   ```bash
   git remote get-url origin
   ```
   - Contains `github.com` → **GitHub**
   - Contains `gitlab` → **GitLab**

2. **Fallback — repository markers:**
   - `.github/` directory exists → **GitHub**
   - `.gitlab-ci.yml` file exists → **GitLab**

3. **Default:** If no signals found, ask the operator.

## Platform Mapping

| Concept | GitHub | GitLab |
|---------|--------|--------|
| CLI tool | `gh` | `glab` |
| Code review unit | Pull Request (PR) | Merge Request (MR) |
| Create review | `gh pr create` | `glab mr create` |
| List reviews | `gh pr list` | `glab mr list` |
| View review | `gh pr view` | `glab mr view` |
| Review comments | `gh pr review` | `glab mr note` |
| CI status | `gh pr checks` | `glab ci status` |
| Create issue | `gh issue create` | `glab issue create` |
| API access | `gh api` | `glab api` |
| Merge | `gh pr merge` | `glab mr merge` |
| Close | `gh pr close` | `glab mr close` |

## Usage in Skills

Set variables at the start of execution based on detected platform:

```
PLATFORM=github|gitlab
CLI=gh|glab
REVIEW_UNIT=PR|MR
REVIEW_UNIT_LOWER=pr|mr
CREATE_CMD="gh pr create"|"glab mr create"
EDIT_CMD="gh pr edit"|"glab mr update"
VIEW_CMD="gh pr view"|"glab mr view"
LIST_CMD="gh pr list"|"glab mr list"
```

Then use these variables throughout instead of hardcoding platform-specific commands.
