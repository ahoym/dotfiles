---
description: "Index — GitHub command clusters. Skills should reference specific cluster files, not this index."
---

# GitHub Commands (Index)

Commands are split into clusters so skills load only what they need:

| Cluster | File | Contents |
|---------|------|----------|
| **Fetch review data** | `fetch-review-data.md` | Fetch Review Details, Diff, Files Changed, Commits |
| **Comment interaction** | `comment-interaction.md` | Fetch/Reply/Edit/React to comments (inline, review, top-level) |
| **PR management** | `pr-management.md` | Create/Update PR, Post Review, Checkout, Check Existing, Find Approvers |
| **Batch operations** | `batch-operations.md` | Fetch Review Metadata, Verify Access, Count Total (for extract-request-learnings) |

Skills reference clusters by name in their Reference Files section. After platform detection, read from `~/.claude/skill-references/{github,gitlab}/`.
