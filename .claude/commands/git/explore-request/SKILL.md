---
name: explore-request
description: "Fetch and analyze a request's (PR or MR) diff and metadata, then enter interactive Q&A mode."
argument-hint: "[request-number]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Explore Review

Pull down a review to understand its changes, get context, and ask questions.

## Usage

- `/git:explore-request <number>` - Explore review by number
- `/git:explore-request <url>` - Explore review by URL
- `/git:explore-request` - Explore review for current branch (if one exists)

## Reference Files (conditional — read only when needed)

- @~/.claude/skill-references/platform-detection.md
- `~/.claude/skill-references/github/fetch-review-data.md` / `gitlab/fetch-review-data.md` — Fetch PR/MR details, diff, files, commits

## Instructions

1. **Detect platform** — follow `@~/.claude/skill-references/platform-detection.md` to determine GitHub vs GitLab. Then read `~/.claude/skill-references/{github,gitlab}/fetch-review-data.md` (matching detected platform).

2. **Parse review identifier** from `$ARGUMENTS`:
   - If empty, use current branch's review
   - If numeric, treat as review number
   - If URL (contains `URL_PATTERN`), extract review number from URL

3. **Fetch review metadata** (run in parallel):

   Using the fetch-review-data cluster file loaded in step 1, follow:
   - **Fetch Review Details** — get number, title, body, author, branches, state, timestamps
   - **Fetch Files Changed** — get list of modified file paths
   - **Fetch Commits** — get short SHAs and commit messages

4. **Display review summary** (store as `REVIEW_CONTEXT`):
   ```
   $REVIEW_UNIT $REVIEW_PREFIX<number>: <title>
   Author: <author>
   Branch: <source_branch> → <target_branch>
   Status: <state>
   Created: <created_at>

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

5. **Fetch the diff** (store as `REVIEW_DIFF`):
   ```bash
   $DIFF_CMD <number>
   ```
   If diff is large (>500 lines), summarize by file:
   - Show first 50 lines of each file's diff
   - Note "... and X more lines" for truncated sections

6. **Offer to checkout** the review branch (optional):
   Ask: "Would you like me to checkout this branch locally? (y/n)"

   If yes:
   ```bash
   $CHECKOUT_CMD <number>
   ```

7. **Enter Q&A mode**:
   Present to user:
   ```
   I now have full context on $REVIEW_UNIT $REVIEW_PREFIX<number>. You can ask me:
   - What does this $REVIEW_UNIT change?
   - Why was <file> modified?
   - Are there any potential issues?
   - How does <function/class> work now?
   - What's the testing strategy?

   Ask any questions about this review, or say "done" to exit.
   ```

8. **Answer questions** using `REVIEW_CONTEXT` and `REVIEW_DIFF`:
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

After exploring a review, you may want to:

| Next Step | Skill |
|-----------|-------|
| Address review comments | `/git:address-request-comments` |
| Split a large review | `/git:split-request` |
| Preview/resolve merge conflicts | `/git:resolve-conflicts --preview` |

## Important Notes

- This skill is for **understanding** reviews, not modifying them
- For large reviews with many files, focus on the most significant changes first
- If the diff is too large to process, offer to focus on specific files
