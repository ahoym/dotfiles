---
description: "GitHub commands for creating/updating PRs, posting reviews, and branch management."
---

# GitHub: PR Management

## Section Index
<!-- Offsets are 1-indexed line numbers. After editing sections below, verify by running: Read(file, offset, limit) for each slug -->
| Slug | Offset | Limit |
|------|--------|-------|
| create-or-update-request | 19 | 10 |
| post-review-with-inline-comments | 30 | 31 |
| checkout-review-branch | 62 | 6 |
| check-for-existing-review | 69 | 5 |
| find-approved-reviewers | 75 | 9 |

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

## Create or Update PR (Body via File)

Write the PR body to `tmp/change-request-replies/pr-body.md` first to avoid HEREDOC/quoted string permission prompts:

```bash
# Write body via Write tool to tmp/change-request-replies/pr-body.md, then:
gh pr create --base <base-branch> --title "<title>" --body-file tmp/change-request-replies/pr-body.md
# Or update existing:
gh pr edit <number> --body-file tmp/change-request-replies/pr-body.md
```

## Post Review with Inline Comments

Write the review payload to `tmp/change-request-replies/review-<number>.json` via the Write tool, then post:

```bash
# Write JSON payload to tmp/change-request-replies/review-<number>.json, then:
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  --input tmp/change-request-replies/review-<number>.json
# Clean up:
rm tmp/change-request-replies/review-<number>.json
```

**Payload format** (`tmp/change-request-replies/review-<number>.json`):
```json
{
  "event": "COMMENT",
  "body": "Review summary body here",
  "comments": [
    {
      "path": "relative/file/path.md",
      "line": 42,
      "side": "RIGHT",
      "body": "Inline comment body here"
    }
  ]
}
```

- `line`: line number in the final version of the file (RIGHT side of diff)
- `side`: always `"RIGHT"` for comments on the new version
- `event`: `"COMMENT"`, `"APPROVE"`, or `"REQUEST_CHANGES"`

## Checkout Review Branch

```bash
gh pr checkout <number>
git pull origin <headRefName>
```

## Check for Existing Review

```bash
gh pr list --head <branch-name>
```

## Find Approved Reviewers

```bash
# Write jq filter to tmp/jq-filter.jq via Write tool first (avoids quoted string permission prompt):
#   [.[] | select(.state == "APPROVED") | .user.login] | unique | .[]
# Then (use piped jq -f instead of --jq):
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  | jq -rf tmp/jq-filter.jq
```
