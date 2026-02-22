---
description: "Create a GitHub issue from a PR review comment."
---

# Create Follow-up Issue

Create a GitHub issue to track work requested in a PR review comment, then reply to the reviewer with the issue link.

## Usage

- `/create-followup-issue <pr-number>` - Create issue from a comment on the specified PR
- `/create-followup-issue` - Will prompt for PR number

## Reference Files (conditional — read only when needed)

- @_shared/platform-detection.md - Platform detection for GitHub/GitLab

## Instructions

0. **Detect platform** — follow `@_shared/platform-detection.md` to determine GitHub vs GitLab. Set `CLI`, `REVIEW_UNIT`, and API command patterns accordingly. All commands below use GitHub (`gh`) syntax; substitute GitLab equivalents if on GitLab.

1. **Get PR number**:
   - If `$ARGUMENTS` provided, use as PR number
   - Otherwise, ask: "Which PR has the review comment?"

2. **Fetch review comments**:
   ```bash
   gh api repos/{owner}/{repo}/pulls/<pr-number>/comments \
     --jq '.[] | {id, path, line, body, user: .user.login}'
   ```

   Also check PR-level comments:
   ```bash
   gh api repos/{owner}/{repo}/issues/<pr-number>/comments \
     --jq '.[] | {id, body, user: .user.login}'
   ```

3. **Show comments and ask which one**:
   Display the comments with their IDs and ask:
   "Which comment should become an issue? (Enter comment ID)"
   Store as `COMMENT_ID` and `COMMENT_BODY`

4. **Draft issue details**:
   Ask user to confirm or edit:
   - Title (suggest based on comment content)
   - Body (include context linking back to PR)

   Suggested body format:
   ```markdown
   Originated from PR #<pr-number> review comment by @<reviewer>.

   ## Context
   <COMMENT_BODY>

   ## Original Location
   - PR: #<pr-number>
   - File: <path> (if applicable)
   - Line: <line> (if applicable)
   ```

5. **Create the issue**:
   ```bash
   gh issue create --title "<title>" --body "<body>"
   ```

   Capture the new issue number from output.

6. **Reply to the reviewer**:
   For code review comments:
   ```bash
   gh api repos/{owner}/{repo}/pulls/<pr-number>/comments \
     -f body="Good idea! Created issue #<issue-number> to track this as a follow-up.

   ---
   *Co-authored with Claude Opus 4.5*" \
     -F in_reply_to=<COMMENT_ID>
   ```

   For PR-level comments:
   ```bash
   gh api repos/{owner}/{repo}/issues/<pr-number>/comments \
     -f body="Good idea! Created issue #<issue-number> to track this as a follow-up.

   ---
   *Co-authored with Claude Opus 4.5*"
   ```

7. **Summary**:
   Report the created issue number and link.

## Example

```
Fetching comments from PR #8...

Review comments:
  [101] @reviewer on src/metrics.py:45
        "Consider using Decimal instead of float for financial calculations"

  [102] @reviewer on src/result.py:12
        "Add docstring here"

PR-level comments:
  [201] @reviewer
        "Great work! Ship it."

Which comment should become an issue? > 101

Draft issue:
  Title: Convert floats to Decimal for financial calculations
  Body: Originated from PR #8 review comment...

Create this issue? (y/n) > y

Created issue #16: Convert floats to Decimal for financial calculations
Replied to comment [101] with link to issue #16.
```

## Important Notes

- Always include the co-authorship footnote when replying
- Link back to the original PR and comment location in the issue body
- Use a friendly, appreciative tone in the reply
