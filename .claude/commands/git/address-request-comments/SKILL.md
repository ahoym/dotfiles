---
name: address-request-comments
description: "Fetch and address request comments from a pull request (GitHub) or merge request (GitLab)."
argument-hint: "[request-number]"
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Address Review

Fetch and address review comments from a pull request (GitHub) or merge request (GitLab).

## Usage

- `/git:address-request-comments` - Address comments on review for current branch
- `/git:address-request-comments <number>` - Address comments on specific review
- `/git:address-request-comments <url>` - Address comments on review by URL

## Reference Files (conditional — read only when needed)

- @~/.claude/skill-references/platform-detection.md - Platform detection for GitHub/GitLab
- `request-reply-templates.md` — Read before composing replies to review comments (step 6)
- `request-lgtm-verification.md` — Read only when an LGTM comment is detected among review comments

## Instructions

1. **Detect platform** — follow `@~/.claude/skill-references/platform-detection.md` to determine GitHub vs GitLab. Set variables for the rest of the skill:

   | Variable | GitHub | GitLab |
   |----------|--------|--------|
   | `CLI` | `gh` | `glab` |
   | `REVIEW_UNIT` | PR | MR |
   | `REVIEW_UNIT_LOWER` | pr | mr |
   | `VIEW_CMD` | `gh pr view` | `glab mr view` |
   | `COMMENT_CMD` | `gh pr comment` | `glab mr comment` |
   | `CHECKOUT_CMD` | `gh pr checkout` | `glab mr checkout` |
   | `API_CMD` | `gh api` | `glab api` |
   | `AUTH_CMD` | `gh auth status` | `glab auth status` |

2. **Fetch review and comments** (run in parallel):

   **Incremental fetch:** If this review was already fetched earlier in the session, use `updated_after` (GitLab) or `since` (GitHub) to get only new/edited comments since the last fetch. Store the current UTC timestamp as `LAST_FETCH_TS` after each fetch for use in subsequent invocations. On incremental fetch, filter out your own replies (author = current user via `$AUTH_CMD`) to avoid re-processing comments you already responded to.

   Announce the mode:
   ```
   Incremental fetch — checking for comments since <LAST_FETCH_TS>
   ```
   or:
   ```
   Full fetch — first review of $REVIEW_UNIT <number>
   ```

   **GitHub:**
   - Get review details:
     ```bash
     gh pr view <review> --json number,title,headRefName,baseRefName
     ```
   - Get inline review comments:
     ```bash
     # Full fetch
     gh api repos/{owner}/{repo}/pulls/{review}/comments --jq '.[] | {id, path, line, body, user: .user.login, created_at}'

     # Incremental fetch
     gh api "repos/{owner}/{repo}/pulls/{review}/comments?since=<LAST_FETCH_TS>" --jq '.[] | {id, path, line, body, user: .user.login, created_at}'
     ```
   - Get general review comments (not tied to specific lines):
     ```bash
     gh pr view <review> --json reviews --jq '.reviews[] | select(.body != "") | {author: .author.login, state: .state, body}'
     ```
   - Get issue/review comments (includes LGTM comments):
     ```bash
     gh api repos/{owner}/{repo}/issues/{review}/comments --jq '.[] | {id, body, user: .user.login, created_at}'
     ```

   **GitLab:**
   - Get review details:
     ```bash
     glab mr view <review> --output json
     ```
   - Get review notes/comments:
     ```bash
     # Full fetch
     glab api projects/:id/merge_requests/<review>/notes | jq '.[] | {id, body, author: .author.username, created_at, position}'

     # Incremental fetch
     glab api "projects/:id/merge_requests/<review>/notes?updated_after=<LAST_FETCH_TS>" | jq '.[] | {id, body, author: .author.username, created_at, position}'
     ```
   - Get review discussions (threaded):
     ```bash
     # Full fetch
     glab api projects/:id/merge_requests/<review>/discussions | jq '.[] | {id, notes: [.notes[] | {id, body, author: .author.username, position}]}'

     # Incremental fetch
     glab api "projects/:id/merge_requests/<review>/discussions?updated_after=<LAST_FETCH_TS>" | jq '.[] | {id, notes: [.notes[] | {id, body, author: .author.username, position}]}'
     ```

3. **Display comments summary**:
   - Group by file path (from `path` on GitHub, `position` data on GitLab)
   - Show each comment with: file, line number, author, and content
   - Number each comment for reference (store as `COMMENTS` list)

4. **Checkout the review branch** if not already on it:

   **GitHub:**
   ```bash
   gh pr checkout <review>
   git pull origin <headRefName>
   ```

   **GitLab:**
   ```bash
   glab mr checkout <review>
   git pull origin <source_branch>
   ```

5. **Categorize each comment in `COMMENTS`**:
   a. Read the relevant file and understand the context
   b. Categorize each comment as one of:
      - **Suggestion** - Proposes a code change, architectural change, or different approach
      - **Typo/Bug fix** - Points out an obvious error (typo, missing import, clear bug)
      - **Clarification request** - Asks a question or requests explanation
      - **General feedback** - Praise, acknowledgment, or non-actionable comment
      - **Out of scope** - Valid but should be a separate issue

6. **Reply to all comments on the platform**:
   Read `request-reply-templates.md` for tone guidance, then reply directly on the platform:
   - For suggestions: State whether you agree/disagree and your proposed approach
   - For clarification requests: Provide the explanation
   - For typo/bug fixes: Acknowledge and confirm you'll fix it

   **IMPORTANT:** Do NOT prompt the user in CLI for approval at this step. Always reply to comments on the platform first.

   **GitHub:**
   ```bash
   gh api repos/{owner}/{repo}/pulls/{review}/comments \
     -f body="Good point - I'll update this to use bcrypt instead. The current sha256 approach is less secure for password hashing.

   ---
   *Co-authored with Claude Opus 4.6*" \
     -F in_reply_to=<comment_id>
   ```

   **GitLab:**
   ```bash
   glab api projects/:id/merge_requests/<review>/discussions/<discussion_id>/notes \
     -X POST -f body="Good point - I'll update this to use bcrypt instead. The current sha256 approach is less secure for password hashing.

   ---
   *Co-authored with Claude Opus 4.6*"
   ```

7. **Present suggestions for partner approval**:
   After replying to all comments on the platform, present actionable suggestions to your partner (the user in CLI) for approval:

   ```
   | # | File | Suggestion | My Recommendation |
   |---|------|------------|-------------------|
   | 1 | src/auth.py:25 | Use bcrypt | Agree — more secure |
   | 2 | src/auth.py:48 | Add error handling | Agree — improves robustness |

   Which suggestions should I implement? (all / none / 1,2)
   ```

   Typo/bug fixes are auto-implemented (they're corrections, not debatable suggestions).

8. **Implement approved changes** (only after partner approval):
   a. For partner-approved suggestions and auto-approved typo/bug fixes:
      - Make the change
      - Stage the file: `git add <path>`
   b. Track which comments will be addressed by the commit

9. **Create commit** for changes (if any):
   ```bash
   git commit -m "$(cat <<'EOF'
   Address $REVIEW_UNIT review comments

   - <summary of changes made>

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```
   Store commit hash as `COMMIT_HASH`.

10. **Push changes**:
    ```bash
    git push origin <branch>
    ```

11. **Reply to comments with commit reference** (after implementation):

    **GitHub:**
    For comments addressed by code changes:
    ```bash
    gh api repos/{owner}/{repo}/pulls/{review}/comments \
      -f body="<brief explanation>. Fixed in <COMMIT_HASH>.

    ---
    *Co-authored with Claude Opus 4.6*" \
      -F in_reply_to=<comment_id>
    ```

    For comments needing clarification only:
    ```bash
    gh api repos/{owner}/{repo}/pulls/{review}/comments \
      -f body="<explanation or response>

    ---
    *Co-authored with Claude Opus 4.6*" \
      -F in_reply_to=<comment_id>
    ```

    **GitLab:**
    For comments addressed by code changes:
    ```bash
    glab api projects/:id/merge_requests/<review>/discussions/<discussion_id>/notes \
      -X POST -f body="<brief explanation>. Fixed in <COMMIT_HASH>.

    ---
    *Co-authored with Claude Opus 4.6*"
    ```

    For comments needing clarification only:
    ```bash
    glab api projects/:id/merge_requests/<review>/discussions/<discussion_id>/notes \
      -X POST -f body="<explanation or response>

    ---
    *Co-authored with Claude Opus 4.6*"
    ```

    For suggestions that were skipped (not approved):
    - Do not reply automatically
    - Let the user handle these manually or in a follow-up

12. **Summary**: Report to user:
    - Number of suggestions approved and implemented
    - Number of typo/bug fixes addressed
    - Number of comments replied to with clarification
    - Number of suggestions skipped (awaiting user decision)

## Example Output

```
PR #42: Add user authentication

Found 4 review comments:

1. [src/auth.py:25] @reviewer1
   "Consider using bcrypt instead of sha256 for password hashing"

2. [src/auth.py:48] @reviewer1
   "Missing error handling for invalid tokens"

3. [src/models/user.py:12] @reviewer2
   "Typo: 'pasword' should be 'password'"

4. [General] @reviewer2
   "Great work overall! Just minor fixes needed."

---

Categorized comments:

| # | Type | Comment |
|---|------|---------|
| 1 | Suggestion | Use bcrypt instead of sha256 |
| 2 | Suggestion | Add error handling for invalid tokens |
| 3 | Typo/Bug fix | Fix 'pasword' typo |
| 4 | General feedback | No action needed |

---

The following suggestions require your approval:

| # | File | Suggestion | Recommendation |
|---|------|------------|----------------|
| 1 | src/auth.py:25 | Use bcrypt instead of sha256 | Agree - bcrypt is more secure |
| 2 | src/auth.py:48 | Add error handling for invalid tokens | Agree - improves robustness |

Which suggestions should I implement? (all / none / 1,2 / skip)
> all

---

Implementing approved changes...

- Comment 1: Updated to use bcrypt
- Comment 2: Added try/except with proper error response
- Comment 3: Fixed typo (auto-approved as typo fix)

Created commit: abc1234
Pushed to origin/feature/auth

Replied to 3 comments with commit reference.
Comment 4 was general feedback - no action needed.
```

## Important Notes

- Use `/git:explore-request` first if you need to understand the review before addressing comments
- **Reply to comments on the platform first** — share your analysis with the reviewer, then present suggestions to your partner for approval
- **Your partner approves** — after replying on the platform, present suggestions and wait for your partner to choose which to implement (they may approve in CLI or via review comments)
- Typo fixes and obvious bug fixes can be auto-implemented (they're corrections, not debatable suggestions)
- Always read the file context before making changes
- Use a friendly, appreciative tone in replies ("Thanks for catching this!", "Good call")
- If you disagree with a comment, explain your reasoning respectfully and ask for clarification
- Group related changes into a single commit when possible
- If a comment is unclear, ask the user before responding

### Who approves suggestions?

Your **partner** — the person you're pair-programming with. They see your analysis, the reviewer's comments, and your platform replies, then tell you which suggestions to implement. Approval can come via CLI or review comments — either channel is valid.

### Conditional Requests

Comments with conditional phrasing like "If X, please do Y" should be categorized as **clarification requests**, not suggestions. The reviewer is asking for confirmation before the change should be made.

**Example:**
> "I think `is` means in-sample here. If so, please rename these variables."

This is a clarification request. Reply to confirm the understanding, then implement only after the reviewer confirms:
```
Yes, `is_` here means "in-sample". Would you like me to rename to `in_sample_*` or `train_*`?
```

### Line Number Drift

When comments reference specific line numbers (inline diff comments), be aware that:
- The line numbers in the API response refer to line numbers **at the time the comment was made**
- If new commits have been pushed since the comment was made, line numbers may have shifted
- On GitLab, the `head_sha` in the position data tells you which commit the line numbers refer to

**To find what an inline comment is actually about:**
```bash
# Option 1: Check out the commit the comment was made on
git show <commit_sha>:<file_path> | sed -n '<line_number>p'

# Option 2: View the file at that commit with context
git show <commit_sha>:<file_path> | head -n <line_number+5> | tail -n 10
```

**Do NOT** assume current file line numbers match the comment's line numbers after pushing changes.

### Investigation vs Approval Distinction

Be careful to distinguish comment types:

- **Clear approval** (execute): "Claude can you update...", "Go ahead and change it", "Please update the plan to...", "yes, proceed", "send it"
- **Investigation request** (analyze, then ask): "Can you look into X?", "Claude, can you investigate Y?"
- **Preference statement** (do NOT execute): "please annotate with X", "we should use X", "it would be better to..."

For investigation requests: Analyze the request, provide your findings/recommendations, then explicitly ask for approval before making changes.

### Planning Documents Exception

For `.md` files in plan directories (`docs/plans/`, `.claude/personal/plans/`, or any path containing `plans/`), do NOT auto-fix even if you agree with the comment. Planning documents require discussion, so reply with your thoughts and wait for explicit approval from the review author before making changes.

**When approval is given, only include what was specifically approved** - don't expand scope to include related improvements discussed in the same thread.

### Delta Summaries

Delta/summary comments (e.g., "Summary of Changes Since Last Update") should ALWAYS be posted as **top-level review comments**, not as thread replies. Top-level comments are easier to find and provide better visibility for tracking progress.

**GitHub:**
```bash
gh pr comment <NUMBER> --body "## Summary of Changes Since Last Update

- <change 1>
- <change 2>

---
_Co-authored by Claude Code (Claude Opus 4.6)_"
```

**GitLab:**
```bash
glab mr comment <NUMBER> --message "## Summary of Changes Since Last Update

- <change 1>
- <change 2>

---
_Co-authored by Claude Code (Claude Opus 4.6)_"
```

### Re-review Requests

After pushing new changes, search for ALL reviewers who gave LGTM comments and tag each of them asking for re-review.

**GitHub:**
```bash
# Find all unique reviewers who approved
gh api repos/{owner}/{repo}/pulls/<NUMBER>/reviews --jq '[.[] | select(.state == "APPROVED") | .user.login] | unique | .[]'

# Post re-review request
gh pr comment <NUMBER> --body "@<reviewer> New changes have been pushed - could you please re-review?

---
_Co-authored by Claude Code (Claude Opus 4.6)_"
```

**GitLab:**
```bash
# Find all unique reviewers who gave LGTM comments
glab api "projects/:id/merge_requests/<NUMBER>/notes?sort=desc&per_page=100" | jq -r '[.[] | select(.body | test("LGTM"; "i"))] | [.[].author.username] | unique | .[]'

# Post re-review request
glab mr comment <NUMBER> --message "@<reviewer> New changes have been pushed - could you please re-review?

---
_Co-authored by Claude Code (Claude Opus 4.6)_"
```

**Important:** Tag ALL reviewers who gave LGTM comments, including the review author. When pair-programming with an AI agent, the human is also reviewing the code changes made by the agent.

### Keep Reviews Focused

When responding to review feedback leads to changes unrelated to the review's purpose (e.g., updating rules/guidelines while reviewing an error handling audit), move those changes to a separate branch:

```bash
# Stash unrelated changes
git stash push -m "unrelated changes" <files>

# Switch to appropriate branch (often the base branch)
git checkout <target_branch>

# Apply and commit
git stash pop
git add -A && git commit -m "<message>"
git push origin <target_branch>

# Return to original branch
git checkout <original_branch>
```

This keeps the review focused on its intended scope and makes reviews easier.
