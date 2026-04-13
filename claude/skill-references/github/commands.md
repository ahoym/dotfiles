---
description: "Index — GitHub command clusters and atomic command files."
---

# GitHub Commands (Index)

## Atomic Command Files (`commands/`)

Skills inline these via `!`cat ~/.claude/platform-commands/<name>.sh`` preprocessing. Each file is a single-command primitive.

| File | Operation |
|------|-----------|
| `create-review.sh` | Create PR via body-file |
| `update-review.sh` | Update existing PR body |
| `check-existing-review.sh` | Check if PR exists for branch |
| `checkout-review.sh` | Checkout PR branch |
| `find-approved-reviewers.sh` | Find APPROVED reviewers |
| `post-review-comments.sh` | Post review with inline comments |
| `fetch-review-details.sh` | Fetch PR metadata |
| `fetch-review-details-with-reviews.sh` | Fetch PR metadata + reviews |
| `fetch-activity-signals.sh` | Quick-exit polling check |
| `fetch-review-diff.sh` | Fetch PR diff |
| `fetch-review-files.sh` | Fetch changed file paths |
| `fetch-review-commits.sh` | Fetch commit list |
| `fetch-inline-comments.sh` | Fetch inline review comments |
| `fetch-recent-inline-comments.sh` | Quick-exit comment check |
| `fetch-review-comments.sh` | Fetch general review comments |
| `fetch-issue-comments.sh` | Fetch issue/top-level comments |
| `reply-to-inline-comment.sh` | Reply to inline comment |
| `post-top-level-comment.sh` | Post top-level PR comment |
| `edit-inline-comment.sh` | Edit existing inline comment |
| `react-to-comment.sh` | React to comment with emoji |
| `consolidated-fetch.sh` | Consolidated state+reviews+comments fetch |
| `list-open-issues.sh` | List open issues |
| `fetch-issue.sh` | Fetch single issue with comments |
| `post-issue-comment.sh` | Post comment on issue |
| `batch-fetch-reviews.sh` | Batch fetch PR metadata |
| `verify-platform-access.sh` | Verify API access |
| `count-total-reviews.sh` | Count total PRs via Link header |

## Legacy Cluster Files

These files are retained as human-readable reference. Skills no longer load them at runtime — use `commands/` files instead.

| Cluster | File | Contents |
|---------|------|----------|
| **Fetch review data** | `fetch-review-data.md` | Fetch Review Details, Diff, Files Changed, Commits |
| **Comment interaction** | `comment-interaction.md` | Fetch/Reply/Edit/React to comments (inline, review, top-level) |
| **PR management** | `pr-management.md` | Create/Update PR, Post Review, Checkout, Check Existing, Find Approvers |
| **Batch operations** | `batch-operations.md` | Fetch Review Metadata, Verify Access, Count Total |
| **Issue operations** | `issue-operations.md` | List Issues, Fetch Details, Post Comments, Check Linked PRs |
