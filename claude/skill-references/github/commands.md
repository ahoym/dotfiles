---
description: "Index — GitHub command clusters and atomic scripts. Skills use !cat platform-commands/<cmd>.sh for atomic commands."
---

# GitHub Commands (Index)

## Use Verbatim — Reformulation Hits Permission Denials

When a script is inlined into your prompt via `!cat <script>.sh`, **run the command verbatim** with placeholders substituted. Do not reformulate the shape from memory or training:

- `-f body=@file` ≠ `-F body=@file` — `-f` (lowercase) posts literal `@file`; `-F` (uppercase) reads the file. Use what the script says.
- `gh api ... -F body=@<abs>` ≠ `jq -n --arg body "$(cat file)" \| gh api ... --input -`. The "workaround" hits `Bash(jq *)` permission denials because the `$(cat ...)` subshell defeats pattern matching.
- `git -C <absolute-path>` ≠ `cd <path> && git ...` ≠ `git -C <relative-path>`. The first matches the allowlist; the others do not.

The allowlist permits the inlined command shape exactly. Substituting an "equivalent" form means denial-then-retry-loop, not seamless execution. **A first permission denial is a STOP signal**, not a retry signal — re-read the inlined script and use that shape.

If a sanctioned shape doesn't cover what you need, escalate. Do not invent a workaround.

## Atomic Command Scripts (`commands/*.sh`)

Skills inline these via `!cat ~/.claude/platform-commands/<cmd>.sh`. See `commands/` subdirectory for all scripts.

## Cluster Reference Files (Deprecated)

Legacy cluster files — retained for accumulated platform knowledge, not loaded by skills:

| Cluster | File | Status |
|---------|------|--------|
| **Comment interaction** | `comment-interaction.md` | Retained — jq escaping gotchas, -F vs -f, permission prompt workarounds |

Deleted clusters (content migrated to learnings):
- `pr-management.md` → `~/.claude/learnings/git-github-api.md` (`claude/learnings/git-github-api.md`)
- `issue-operations.md` → `~/.claude/learnings/git-github-api.md` (`claude/learnings/git-github-api.md`)
- `batch-operations.md` → `~/.claude/learnings/git-github-api.md` (`claude/learnings/git-github-api.md`)
- `fetch-review-data.md` → deleted (content redundant with request-interaction-base.md)
