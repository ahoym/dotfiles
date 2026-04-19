---
description: "Index — GitLab command clusters and atomic scripts. Skills use !cat platform-commands/<cmd>.sh for atomic commands."
---

# GitLab Commands (Index)

## Atomic Command Scripts (`commands/*.sh`)

Skills inline these via `!cat ~/.claude/platform-commands/<cmd>.sh`. See `commands/` subdirectory for all scripts.

## Cluster Reference Files (Deprecated)

Legacy cluster files — retained for accumulated platform knowledge, not loaded by skills:

| Cluster | File | Status |
|---------|------|--------|
| **Comment interaction** | `comment-interaction.md` | Retained — discussions vs notes, nested JSON gotcha, no-python3 rule, emoji names |
| **MR management** | `pr-management.md` | Retained — GraphQL createDiffNote, line positioning, flat JSON gotcha |

Deleted clusters (content migrated to learnings):
- `batch-operations.md` → deleted (migration target `~/.claude/learnings/gitlab/batch-operations-patterns.md` does not exist — content was not migrated)
- `issue-operations.md` → deleted (unimplemented v2 stub)
- `fetch-review-data.md` → deleted (content redundant with skill instructions)
