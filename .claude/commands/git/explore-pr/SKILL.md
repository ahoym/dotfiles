---
description: Pull down a PR to get context and ask questions about it
---

# Explore PR

Pull down a PR to understand its changes, get context, and ask questions.

## Usage

- `/explore-pr <pr-number>` - Explore PR by number
- `/explore-pr <pr-url>` - Explore PR by URL
- `/explore-pr` - Explore PR for current branch (if one exists)

## Reference Files (conditional — read only when needed)

- @../_shared/platform-detection.md - Platform detection for GitHub/GitLab

## Instructions

0. **Detect platform** — follow `@../_shared/platform-detection.md` to determine GitHub vs GitLab. Set `CLI`, `REVIEW_UNIT`, and API command patterns accordingly. All commands below use GitHub (`gh`) syntax; substitute GitLab equivalents if on GitLab.

1. **Parse PR identifier** from `$ARGUMENTS`:
   - If empty, use current branch's PR
   - If numeric, treat as PR number
   - If URL (contains `github.com`), extract PR number from URL

2. **Fetch PR metadata** (run in parallel):
   - Get PR details:
     ```bash
     gh pr view <pr> --json number,title,body,author,headRefName,baseRefName,state,createdAt,updatedAt
     ```
   - Get files changed:
     ```bash
     gh pr view <pr> --json files --jq '.files[].path'
     ```
   - Get commits:
     ```bash
     gh pr view <pr> --json commits --jq '.commits[] | {sha: .oid[0:7], message: .messageHeadline}'
     ```

3. **Display PR summary** (store as `PR_CONTEXT`):
   ```
   PR #<number>: <title>
   Author: <author>
   Branch: <headRefName> → <baseRefName>
   Status: <state>
   Created: <createdAt>

   ## Description
   <body>

   ## Files Changed (<count>)
   - <file1>
   - <file2>
   ...

   ## Commits (<count>)
   - <sha1>: <message1>
   - <sha2>: <message2>
   ...
   ```

4. **Fetch the diff** (store as `PR_DIFF`):
   ```bash
   gh pr diff <pr>
   ```
   If diff is large (>500 lines), summarize by file:
   - Show first 50 lines of each file's diff
   - Note "... and X more lines" for truncated sections

5. **Offer to checkout** the PR branch (optional):
   Ask: "Would you like me to checkout this branch locally? (y/n)"

   If yes:
   ```bash
   gh pr checkout <pr>
   ```

6. **Enter Q&A mode**:
   Present to user:
   ```
   I now have full context on PR #<number>. You can ask me:
   - What does this PR change?
   - Why was <file> modified?
   - Are there any potential issues?
   - How does <function/class> work now?
   - What's the testing strategy?

   Ask any questions about this PR, or say "done" to exit.
   ```

7. **Answer questions** using `PR_CONTEXT` and `PR_DIFF`:
   - Reference specific files and line numbers when answering
   - Read additional files if needed for context
   - If a question requires understanding code not in the diff, use Read tool

## Example Output

```
PR #42: Add user authentication
Author: @developer
Branch: feature/auth → main
Status: OPEN
Created: 2024-01-15

## Description
This PR adds JWT-based authentication with:
- Login/logout endpoints
- Token refresh mechanism
- Protected route middleware

## Files Changed (5)
- src/auth/jwt.py
- src/auth/middleware.py
- src/routes/auth.py
- tests/auth/test_jwt.py
- tests/auth/test_middleware.py

## Commits (3)
- abc1234: Add JWT token generation
- def5678: Add auth middleware
- ghi9012: Add tests

---

I now have full context on PR #42. You can ask me:
- What does this PR change?
- Why was <file> modified?
- Are there any potential issues?
- How does <function/class> work now?
- What's the testing strategy?

Ask any questions about this PR, or say "done" to exit.
```

## Related Skills

After exploring a PR, you may want to:

| Next Step | Skill |
|-----------|-------|
| Address review comments | `/git:address-pr-review` |
| Check merge status | `/git:pr-status` |
| Split a large PR | `/git:split-pr` |
| Monitor for new comments | `/git:monitor-pr-comments` |
| Preview merge conflicts | `/git:preview-conflicts` |

## Important Notes

- This skill is for **understanding** PRs, not modifying them
- For large PRs with many files, focus on the most significant changes first
- If the diff is too large to process, offer to focus on specific files
