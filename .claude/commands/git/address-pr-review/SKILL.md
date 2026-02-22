---
description: "Fetch and address review comments from a pull request."
---

# Address PR Review

Fetch and address review comments from a pull request.

## Usage

- `/address-pr-review` - Address comments on PR for current branch
- `/address-pr-review <pr-number>` - Address comments on specific PR
- `/address-pr-review <pr-url>` - Address comments on PR by URL

## Reference Files (conditional — read only when needed)

- @../_shared/platform-detection.md - Platform detection for GitHub/GitLab

## Instructions

0. **Detect platform** — follow `@../_shared/platform-detection.md` to determine GitHub vs GitLab. Set `CLI`, `REVIEW_UNIT`, and API command patterns accordingly. All commands below use GitHub (`gh`) syntax; substitute GitLab equivalents if on GitLab.

1. **Fetch PR and comments** (run in parallel):
   - Get PR details:
     ```bash
     gh pr view <pr> --json number,title,headRefName,baseRefName
     ```
   - Get review comments:
     ```bash
     gh api repos/{owner}/{repo}/pulls/{pr}/comments --jq '.[] | {id, path, line, body, user: .user.login, created_at}'
     ```
   - Get general PR review comments (not tied to specific lines):
     ```bash
     gh pr view <pr> --json reviews --jq '.reviews[] | select(.body != "") | {author: .author.login, state: .state, body}'
     ```
   - Get issue/PR comments (includes LGTM comments):
     ```bash
     gh api repos/{owner}/{repo}/issues/{pr}/comments --jq '.[] | {id, body, user: .user.login, created_at}'
     ```

2. **Display comments summary**:
   - Group by file path
   - Show each comment with: file, line number, author, and content
   - Number each comment for reference (store as `COMMENTS` list)

3. **Checkout the PR branch** if not already on it:
   ```bash
   git checkout <headRefName>
   git pull origin <headRefName>
   ```

4. **Categorize each comment in `COMMENTS`**:
   a. Read the relevant file and understand the context
   b. Categorize each comment as one of:
      - **Suggestion** - Proposes a code change, architectural change, or different approach
      - **Typo/Bug fix** - Points out an obvious error (typo, missing import, clear bug)
      - **Clarification request** - Asks a question or requests explanation
      - **General feedback** - Praise, acknowledgment, or non-actionable comment
      - **Out of scope** - Valid but should be a separate issue

5. **Reply to all comments on GitHub**:
   For each comment, reply directly on GitHub with your response:
   - For suggestions: State whether you agree/disagree and your proposed approach
   - For clarification requests: Provide the explanation
   - For typo/bug fixes: Acknowledge and confirm you'll fix it

   **IMPORTANT:** Do NOT prompt the user in CLI for approval. Always reply to comments on GitHub first. The reviewer will approve in PR comments.

   ```bash
   # Reply agreeing with a suggestion
   gh api repos/{owner}/{repo}/pulls/{pr}/comments \
     -f body="Good point - I'll update this to use bcrypt instead. The current sha256 approach is less secure for password hashing.

   ---
   *Co-authored with Claude Opus 4.5*" \
     -F in_reply_to=<comment_id>
   ```

6. **Wait for explicit reviewer approval**:
   After replying to comments, **do not implement changes yet**. Wait for the reviewer to explicitly approve in PR comments (e.g., "yes, please proceed", "approved", "lgtm").

   Report to user:
   ```
   Replied to 3 comments. Awaiting reviewer approval before implementing.
   ```

7. **Implement approved changes** (only after reviewer approval):
   a. For approved suggestions and typo/bug fixes:
      - Make the change
      - Stage the file: `git add <path>`
   b. Track which comments will be addressed by the commit

8. **Create commit** for changes (if any):
   ```bash
   git commit -m "$(cat <<'EOF'
   Address PR review comments

   - <summary of changes made>

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
   EOF
   )"
   ```
   Store commit hash as `COMMIT_HASH`.

9. **Push changes**:
   ```bash
   git push origin <headRefName>
   ```

10. **Reply to comments with commit reference** (after implementation):
   For comments addressed by code changes:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{pr}/comments \
     -f body="<brief explanation>. Fixed in <COMMIT_HASH>.

---
*Co-authored with Claude Opus 4.5*" \
     -F in_reply_to=<comment_id>
   ```

   For comments needing clarification only:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{pr}/comments \
     -f body="<explanation or response>

---
*Co-authored with Claude Opus 4.5*" \
     -F in_reply_to=<comment_id>
   ```

   For suggestions that were skipped (not approved):
   - Do not reply automatically
   - Let the user handle these manually or in a follow-up

11. **Summary**: Report to user:
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

## Reference Files (conditional — read only when needed)

- reply-templates.md - Templates for replying to different comment types
- lgtm-verification.md - How to verify LGTM comments match the implementation

## Important Notes

- Use `/git:explore-pr` first if you need to understand the PR before addressing comments
- **Reply to comments on GitHub first** - Do NOT prompt the CLI user for approval. Reply directly to comments on GitHub with your agreement/disagreement and proposed approach
- **Wait for explicit reviewer approval** - After replying, wait for the reviewer to approve in PR comments before implementing any changes
- **Never implement suggestions without reviewer approval** - Even if you agree with a suggestion, you must wait for the reviewer to explicitly approve before making changes
- Typo fixes and obvious bug fixes can be implemented automatically (they're corrections, not suggestions)
- Always read the file context before making changes
- Use a friendly, appreciative tone in replies ("Thanks for catching this!", "Good call")
- If you disagree with a comment, explain your reasoning respectfully and ask for clarification
- Group related changes into a single commit when possible
- If a comment is unclear, ask the user before responding

### Who is the "user" for approval?

The **PR author** (via their comments) is the user who approves suggestions - not the person running the tool locally. When a reviewer comments with a suggestion, look for explicit approval in follow-up comments from the PR author before implementing.

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

For `.md` files in `docs/plans/`, do NOT auto-fix even if you agree with the comment. Planning documents require discussion, so reply with your thoughts and wait for explicit approval from the PR author before making changes.

**When approval is given, only include what was specifically approved** - don't expand scope to include related improvements discussed in the same thread.

### Delta Summaries

Delta/summary comments (e.g., "Summary of Changes Since Last Update") should ALWAYS be posted as **top-level PR comments**, not as thread replies. Top-level comments are easier to find and provide better visibility for tracking progress.

```bash
gh pr comment <PR_NUMBER> --body "## Summary of Changes Since Last Update

- <change 1>
- <change 2>

---
_Co-authored by Claude Code (Claude Opus 4.5)_"
```

### Re-review Requests

After pushing new changes, search for ALL reviewers who gave LGTM comments and tag each of them asking for re-review:

```bash
# Find all unique reviewers who approved
gh api repos/{owner}/{repo}/pulls/<PR_NUMBER>/reviews --jq '[.[] | select(.state == "APPROVED") | .user.login] | unique | .[]'

# Post re-review request
gh pr comment <PR_NUMBER> --body "@<reviewer> New changes have been pushed - could you please re-review?

---
_Co-authored by Claude Code (Claude Opus 4.5)_"
```

**Important:** Tag ALL reviewers who gave LGTM comments, including the PR author. When pair-programming with an AI agent, the human is also reviewing the code changes made by the agent.

### Keep PRs Focused

When responding to PR feedback leads to changes unrelated to the PR's purpose (e.g., updating rules/guidelines while reviewing an error handling audit), move those changes to a separate branch:

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

This keeps the PR focused on its intended scope and makes reviews easier.
