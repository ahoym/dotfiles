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

- @~/.claude/skill-references/platform-detection.md
- `~/.claude/skill-references/github-commands.md` / `gitlab-commands.md` — Platform-specific command templates (read the one matching detected platform)
- `request-reply-templates.md` — Read before composing replies to review comments (step 6)
- `request-lgtm-verification.md` — Read only when an LGTM comment is detected among review comments

## Instructions

1. **Detect platform** — follow `@~/.claude/skill-references/platform-detection.md` to determine GitHub vs GitLab. Then read `~/.claude/skill-references/github-commands.md` or `gitlab-commands.md` (matching detected platform) for exact command templates.

2. **Fetch review and comments** (run in parallel):

   **Incremental fetch:** If this review was already fetched earlier in the session, use `updated_after` (GitLab) or `since` (GitHub) to get only new/edited comments since the last fetch. After each fetch, set `LAST_FETCH_TS` to the `created_at` of the newest comment returned (not wall-clock time) — this ensures we never advance past unseen comments. If no comments are returned, keep the previous `LAST_FETCH_TS`. On incremental fetch, filter out your own replies (author = current user via `$AUTH_CMD`) to avoid re-processing comments you already responded to.

   Announce the mode:
   ```
   Incremental fetch — checking for comments since <LAST_FETCH_TS>
   ```
   or:
   ```
   Full fetch — first review of $REVIEW_UNIT <number>
   ```

   Read `~/.claude/skill-references/github-commands.md` or `gitlab-commands.md` (matching detected platform), then follow:
   - **Fetch Review Details** — get number, title, branch names
   - **Fetch Inline/Review Comments** — use full or incremental fetch as appropriate
   - **Fetch General Review Comments** — comments not tied to specific lines
   - **Fetch Issue/Top-Level Comments** — includes LGTM comments

3. **Display comments summary**:
   - Group by file path (from `path` on GitHub, `position` data on GitLab)
   - Show each comment with: file, line number, author, and content
   - Number each comment for reference (store as `COMMENTS` list)

4. **Checkout the review branch** if not already on it — follow **Checkout Review Branch** in the platform commands file.

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

   **Always append the co-authorship footnote** (`---\n*Co-authored with Claude <model>*`) to every reply posted on the platform, using the model you're currently running as (e.g., "Claude Opus 4.6", "Claude Sonnet 4.6"). See `request-reply-templates.md` for examples.

   Follow **Reply to Inline Comment** in the platform commands file.

7. **Post suggestion summary on the platform**:
   After replying to individual comments, post a top-level comment summarizing actionable suggestions and your recommendations:

   ```
   ## Suggestions awaiting approval

   | # | File | Suggestion | Recommendation |
   |---|------|------------|----------------|
   | 1 | src/auth.py:25 | Use bcrypt | Agree — more secure |
   | 2 | src/auth.py:48 | Add error handling | Agree — improves robustness |
   ```

   Follow **Post Top-Level Comment** in the platform commands file.

   Typo/bug fixes are auto-implemented (they're corrections, not debatable suggestions).

   Wait for explicit approval in a subsequent PR comment (e.g., "go ahead", "all", "1,2") before implementing suggestions. Do NOT prompt in CLI.

8. **Implement approved changes** (only after partner approval):
   a. Group changes by logical concern (e.g., variable elimination, section reordering, typo fixes). Each group becomes its own commit.
   b. For each group:
      - Make the changes
      - Stage the relevant files: `git add <paths>`
      - Commit with a message describing the specific concern:
        ```bash
        git commit -m "$(cat <<'EOF'
        <descriptive message for this group>

        Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
        EOF
        )"
        ```
   c. Track which comments are addressed by each commit hash.

10. **Push changes**:
    ```bash
    git push origin <branch>
    ```

11. **Reply to comments with commit reference** (after implementation):

    Follow **Reply to Inline Comment** in the platform commands file. Include `Fixed in <COMMIT_HASH>` in the body, referencing the specific commit that addressed that comment.

    For suggestions that were skipped (not approved):
    - Do not reply automatically
    - Let the user handle these manually or in a follow-up

12. **Summary**: Report to user:
    - Number of suggestions approved and implemented
    - Number of typo/bug fixes addressed
    - Number of comments replied to with clarification
    - Number of suggestions skipped (awaiting user decision)

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

Follow **Post Top-Level Comment** in the platform commands file.

### Re-review Requests

After pushing new changes, search for ALL reviewers who gave LGTM comments and tag each of them asking for re-review.

Follow **Find Approved Reviewers** in the platform commands file to get the list, then **Post Top-Level Comment** to tag each reviewer asking for re-review.

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
