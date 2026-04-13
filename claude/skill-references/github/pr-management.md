---
description: "DEPRECATED — Commands extracted to commands/*.sh files. Retained as human-readable reference."
---

# GitHub: PR Management (Deprecated — see commands/)

> **Note:** Skills are being migrated away from this file. Commands have been extracted to atomic `.sh` files in `commands/` and are inlined via `!` preprocessing. This file is retained as human-readable reference until migration is complete.

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

## Create or Update PR (Body via File)

Write the PR body to `tmp/claude-artifacts/change-request-replies/pr-body.md` first to avoid HEREDOC/quoted string permission prompts:

```bash
# Write body via Write tool to tmp/claude-artifacts/change-request-replies/pr-body.md, then:
gh pr create --base <base-branch> --title "<title>" --body-file tmp/claude-artifacts/change-request-replies/pr-body.md
# Or update existing:
gh pr edit <number> --body-file tmp/claude-artifacts/change-request-replies/pr-body.md
```

## Post Review with Inline Comments

Write the review payload to `tmp/claude-artifacts/change-request-replies/review-<number>.json` via the Write tool, then post:

```bash
# Write JSON payload to tmp/claude-artifacts/change-request-replies/review-<number>.json, then:
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  --input tmp/claude-artifacts/change-request-replies/review-<number>.json
# Clean up:
rm tmp/claude-artifacts/change-request-replies/review-<number>.json
```

**Payload format** (`tmp/claude-artifacts/change-request-replies/review-<number>.json`):
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
# Write jq filter to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool first (avoids quoted string permission prompt):
#   [.[] | select(.state == "APPROVED") | .user.login] | unique | .[]
# Then (use piped jq -f instead of --jq):
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  | jq -rf tmp/claude-artifacts/jq-filters/jq-filter.jq
```
