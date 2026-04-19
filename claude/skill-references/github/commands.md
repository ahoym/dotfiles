---
description: "Index — GitHub command clusters and atomic scripts. Skills use !cat platform-commands/<cmd>.sh for atomic commands."
---

# GitHub Commands (Index)

## Atomic Command Scripts (`commands/*.sh`)

Skills inline these via `!cat ~/.claude/platform-commands/<cmd>.sh`. See `commands/` subdirectory for all scripts.

## Cluster Reference Files (Deprecated)

Legacy cluster files — retained for accumulated platform knowledge, not loaded by skills:

| Cluster | File | Status |
|---------|------|--------|
| **Comment interaction** | `comment-interaction.md` | Retained — jq escaping gotchas, -F vs -f, permission prompt workarounds |

Deleted clusters (content migrated to learnings):
- `pr-management.md` → `~/.claude/learnings/git-github-api.md`
- `issue-operations.md` → `~/.claude/learnings/git-github-api.md`
- `batch-operations.md` → `~/.claude/learnings/git-github-api.md`
- `fetch-review-data.md` → deleted (content redundant with request-interaction-base.md)
