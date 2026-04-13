---
description: "Index — GitLab command clusters and atomic command files."
---

# GitLab Commands (Index)

## Atomic Command Files (`commands/`)

Skills inline these via `!`cat ~/.claude/platform-commands/<name>.sh`` preprocessing. Each file is a single-command primitive.

| File | Operation |
|------|-----------|
| `create-review.sh` | Create MR via $(cat) body |
| `update-review.sh` | Update existing MR description |
| `check-existing-review.sh` | Check if MR exists for branch |
| `checkout-review.sh` | Checkout MR branch |
| `find-approved-reviewers.sh` | Find LGTM reviewers |
| `post-review-comments.sh` | Post review via GraphQL createDiffNote |
| `fetch-review-details.sh` | Fetch MR metadata |
| `fetch-activity-signals.sh` | Quick-exit polling check |
| `fetch-review-diff.sh` | Fetch MR diff |
| `fetch-review-files.sh` | Fetch changed file paths |
| `fetch-review-commits.sh` | Fetch commit list |
| `fetch-inline-comments.sh` | Fetch inline notes |
| `fetch-recent-inline-comments.sh` | Quick-exit note check |
| `fetch-review-comments.sh` | Fetch threaded discussions |
| `fetch-issue-comments.sh` | Fetch top-level notes |
| `reply-to-inline-comment.sh` | Reply to discussion note |
| `post-top-level-comment.sh` | Post top-level MR note |
| `react-to-comment.sh` | React to note with emoji |
| `consolidated-fetch.sh` | Consolidated state+discussions fetch |
| `list-open-issues.sh` | List open issues (v2 stub) |
| `fetch-issue.sh` | Fetch single issue (v2 stub) |
| `post-issue-comment.sh` | Post issue note (v2 stub) |
| `batch-fetch-reviews.sh` | Batch fetch MR metadata |
| `verify-platform-access.sh` | Verify API access |
| `count-total-reviews.sh` | Count total MRs via x-total header |

## Legacy Cluster Files

These files are retained as human-readable reference. Skills no longer load them at runtime — use `commands/` files instead.

| Cluster | File | Contents |
|---------|------|----------|
| **Fetch review data** | `fetch-review-data.md` | Fetch Review Details, Diff, Files Changed, Commits |
| **Comment interaction** | `comment-interaction.md` | Fetch/Reply/React to comments (inline, review, top-level) |
| **MR management** | `pr-management.md` | Create/Update MR, Post Review, Checkout, Check Existing, Find Approvers |
| **Batch operations** | `batch-operations.md` | Fetch Review Metadata, Verify Access, Count Total |
