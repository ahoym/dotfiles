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

- `~/.claude/skill-references/platform-detection.md` — read if platform not yet detected this session
- `~/.claude/skill-references/github/fetch-review-data.md` / `gitlab/fetch-review-data.md` — Fetch PR/MR details
- `~/.claude/skill-references/github/comment-interaction.md` / `gitlab/comment-interaction.md` — Comment fetch/reply/react templates
- `~/.claude/skill-references/github/pr-management.md` / `gitlab/pr-management.md` — Checkout command
- `request-reply-templates.md` — Read before composing replies to review comments (step 7)
- `request-lgtm-verification.md` — Read only when an LGTM comment is detected among review comments
- `address-request-edge-cases.md` — Read when processing comments (step 6+). Skip on quiet no-ops.
- `~/.claude/learnings/`, `~/.claude/learnings-private/`, `docs/learnings/` — Glob filenames at step 5; read files whose domain matches the comments' subject matter

## Instructions

1. **Detect platform** — if not already detected this session, read `~/.claude/skill-references/platform-detection.md` and follow its logic to determine GitHub vs GitLab. Then read `~/.claude/skill-references/{github,gitlab}/fetch-review-data.md`, `comment-interaction.md`, and `pr-management.md` (matching detected platform).

2. **Fetch review and comments** (run in parallel):

   **Incremental fetch:** If this review was already fetched earlier in the session, filter by timestamp client-side (see comment-interaction cluster file). After each fetch, set `LAST_FETCH_TS` to the `created_at` of the newest comment returned (not wall-clock time) — this ensures we never advance past unseen comments. If no comments are returned, keep the previous `LAST_FETCH_TS`. On incremental fetch, filter out your own replies by checking for `Role: Addresser` in the comment body — this is the role tag appended to all replies by this skill.

   **General Review Comments have no `since` support.** The reviews endpoint returns all reviews every time — it doesn't support timestamp filtering. On incremental fetches, always re-fetch reviews and compare the count against `LAST_REVIEW_COUNT` to detect new review submissions. Only process reviews beyond the previous count.

   Announce the mode:
   ```
   Incremental fetch — checking for comments since <LAST_FETCH_TS>
   ```
   or:
   ```
   Full fetch — first review of $REVIEW_UNIT <number>
   ```

   Using the platform cluster files loaded in step 1, follow:
   - **Fetch Review Details** — get number, title, branch names
   - **Fetch Inline/Review Comments** — use full or incremental fetch as appropriate
   - **Fetch General Review Comments** — comments not tied to specific lines
   - **Fetch Issue/Top-Level Comments** — includes LGTM comments

   **Quiet no-op (incremental only):** If inline, top-level, and review comment counts are all 0, emit a single line and stop — do not proceed to step 3+:
   ```
   <REVIEW_UNIT> #<number>: no new comments (<LAST_FETCH_TS>)
   ```

   **Never dismiss comments as duplicates based on topic.** Each comment ID is a distinct interaction that requires its own response — even if a previous comment on the same thread covered the same topic. A "duplicate" is only a comment you already replied to (same ID). Different comment IDs from different review passes are separate comments, not duplicates.

3. **Display comments summary**:
   - Group by file path (from `path` on GitHub, `position` data on GitLab)
   - Show each comment with: file, line number, author, and content
   - Number each comment for reference (store as `COMMENTS` list)

4. **Checkout the review branch** if not already on it — follow **Checkout Review Branch** in the platform cluster files.

5. **Load relevant learnings**: Glob `~/.claude/learnings/`, `~/.claude/learnings-private/`, and `docs/learnings/` filenames and identify any whose domain matches the comments' subject matter (e.g., a comment about skill structure → `claude-authoring-skills.md`, a comment about test patterns → `testing-*.md`). Read matched files so categorization and replies are grounded in established knowledge. Skip this for trivial comments (typos, praise).

6. **Categorize each comment in `COMMENTS`**:
   a. Read the relevant file and understand the context
   b. Categorize each comment as one of:
      - **Suggestion** - Proposes a code change, architectural change, or different approach
      - **Typo/Bug fix** - Points out an obvious error (typo, missing import, clear bug)
      - **Clarification request** - Asks a question or requests explanation
      - **General feedback** - Praise, acknowledgment, or non-actionable comment
      - **Out of scope** - Valid but should be a separate issue

7. **Reply to all comments on the platform**:
   Read `request-reply-templates.md` for tone guidance, then reply directly on the platform:
   - For suggestions: State whether you agree/disagree and your proposed approach
   - For clarification requests: Provide the explanation
   - For typo/bug fixes: Acknowledge and confirm you'll fix it
   - For general feedback/positive signals: React with an emoji (e.g., `+1`, `heart`, `rocket`) instead of a text reply. Follow **React to Comment** in the platform cluster files.

   **IMPORTANT:** Do NOT prompt the user in CLI for approval at this step. Always reply to comments on the platform first.

   **Always append the co-authorship footnote** to every reply posted on the platform. Use the model you're currently running as (e.g., "Claude Opus 4.6", "Claude Sonnet 4.6"). See `request-reply-templates.md` for the exact format — includes model, persona, and role fields.

   Follow **Reply to Inline Comment** in the platform cluster files.

8. **Post suggestion summary on the platform**:
   After replying to individual comments, post a top-level comment summarizing actionable suggestions and your recommendations:

   ```
   ## Suggestions awaiting approval

   | # | File | Suggestion | Recommendation |
   |---|------|------------|----------------|
   | 1 | src/auth.py:25 | Use bcrypt | Agree — more secure |
   | 2 | src/auth.py:48 | Add error handling | Agree — improves robustness |
   ```

   Follow **Post Top-Level Comment** in the platform cluster files.

   Typo/bug fixes are auto-implemented (they're corrections, not debatable suggestions).

   Wait for explicit approval in a subsequent PR comment (e.g., "go ahead", "all", "1,2") before implementing suggestions. Do NOT prompt in CLI.

9. **Implement approved changes** (only after partner approval):
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

    Follow **Reply to Inline Comment** in the platform cluster files. Include `Fixed in <COMMIT_HASH>` in the body, referencing the specific commit that addressed that comment.

    For suggestions that were skipped (not approved):
    - Do not reply automatically
    - Let the user handle these manually or in a follow-up

12. **Summary**: Report to user:
    - Number of suggestions approved and implemented
    - Number of typo/bug fixes addressed
    - Number of comments replied to with clarification
    - Number of suggestions skipped (awaiting user decision)

## Important Notes (conditional)

- `address-request-edge-cases.md` — Read when processing comments (step 6+). Contains categorization edge cases, line number drift handling, approval vs investigation distinction, planning document exceptions, re-review requests, and keep-reviews-focused guidance. **Skip on quiet no-ops.**
