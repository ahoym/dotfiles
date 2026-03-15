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
- `request-reply-templates.md` — Read before composing replies to review comments (step 8)
- `request-lgtm-verification.md` — Read only when an LGTM comment is detected among review comments
- `address-request-edge-cases.md` — Read when processing comments (step 7+). Skip on quiet no-ops.
- `~/.claude/learnings/`, `~/.claude/learnings-private/`, `docs/learnings/` — Glob filenames at step 6; read files whose domain matches the comments' subject matter

## Instructions

1. **Detect platform** — if not already detected this session, read `~/.claude/skill-references/platform-detection.md` and follow its logic to determine GitHub vs GitLab. Then read `~/.claude/skill-references/{github,gitlab}/fetch-review-data.md`, `comment-interaction.md`, and `pr-management.md` (matching detected platform).

2. **Fetch state, reviews, and comments** (2 calls total):

   **Call 1 (consolidated):** Fetch state + reviews + top-level comments in a single call:
   ```bash
   gh pr view <number> --json state,reviews,comments,number,title,headRefName,baseRefName
   ```
   Parse the JSON response — no `--jq` (avoids quoted string permission prompts).

   **Check state first.** If terminal (merged or closed), cancel any active `/loop` polling this review (use `CronList` to find the job by prompt match, then `CronDelete`), announce, and stop.

   **Call 2 (inline comments):** Fetch inline/review comments via the REST API:
   - **Full fetch:** Use **Fetch Inline/Review Comments** from the platform cluster files (with `--paginate`)
   - **Incremental fetch:** Same endpoint, filter client-side by `created_at > LAST_FETCH_TS` and exclude Addresser replies (`Role:.*Addresser` regex in body)

   Run call 2 only after confirming the PR is not in a terminal state.

   **Incremental fetch rules:** After each fetch, set `LAST_FETCH_TS` to the `created_at` of the newest **non-addresser** comment returned (not wall-clock time, not your own reply timestamps) — this ensures we never advance past unseen comments. Comments can arrive between fetch and reply posting; using your reply's `created_at` instead would skip those. If no non-addresser comments are returned, keep the previous `LAST_FETCH_TS`. Filter out your own replies by matching `Role:.*Addresser` (regex) in the comment body — the footer uses markdown italics, so a literal substring match won't work.

   **General Review Comments have no `since` support.** The reviews data from call 1 returns all reviews every time. On incremental fetches, compare the count against `LAST_REVIEW_COUNT` to detect new review submissions. Only process reviews beyond the previous count.

   **Top-level comments** are included in call 1's `comments` field. On incremental fetches, filter by `createdAt > LAST_FETCH_TS` and exclude Addresser replies.

   Announce the mode:
   ```
   Incremental fetch — checking for comments since <LAST_FETCH_TS>
   ```
   or:
   ```
   Full fetch — first review of $REVIEW_UNIT <number>
   ```

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

   **Mutual resolution filter:** Before replying, check each comment for mutual resolution. A thread is mutually resolved when ALL of these are true:
   - The comment is from a reviewer (`Role:.*Reviewer` in body)
   - The comment is a resolution signal (contains: "resolved", "acknowledged", "sounds good", "thread resolved", "no code change needed", "no action needed", or is purely emoji like 👍/🤝)
   - The addresser has already posted a substantive reply on the same thread (`in_reply_to_id` matches a thread where an Addresser reply exists)

   When mutual resolution is detected, skip the comment entirely — no reaction, no reply, no text. Just update `LAST_FETCH_TS` and move on. Announce: `Thread <file>:<line> — mutual resolution detected, skipping.`

7. **Reply to all comments on the platform**:
   Read `request-reply-templates.md` for tone guidance, then reply directly on the platform:
   - For suggestions: State whether you agree/disagree and your proposed approach
   - For clarification requests: Provide the explanation
   - For typo/bug fixes: Acknowledge and confirm you'll fix it
   - For general feedback/positive signals: React with a `rocket` emoji (default) AND post a brief text acknowledgement (1-2 sentences). Follow **React to Comment** in the platform cluster files.

   **IMPORTANT:** Do NOT prompt the user in CLI for approval at this step. Always reply to comments on the platform first.

   **Always append the co-authorship footnote** to every reply posted on the platform. Use the model you're currently running as (e.g., "Claude Opus 4.6", "Claude Sonnet 4.6"). See `request-reply-templates.md` for the exact format — includes model, persona, and role fields.

   Follow **Reply to Inline Comment** in the platform cluster files.

8. **Act on suggestions based on agreement**:

   **Auto-implement** when both agents converge (addresser agrees with reviewer's suggestion). Also auto-implement typo/bug fixes (corrections, not debatable).

   **Escalate to partner** when the addresser disagrees or is uncertain about a reviewer suggestion. Do NOT implement — wait for explicit approval in a subsequent PR comment (e.g., "go ahead", "all", "1,2") or in CLI.

   To distinguish reviewer comments from human comments, check for `Role:.*Reviewer` in the comment body. Comments without a Role tag are from humans — treat human approvals/suggestions with the same escalation logic (agree = implement, disagree = escalate).

9. **Post review actions summary on the platform**:
   After processing, post a top-level comment summarizing what was done and what needs the partner's input:

   ```
   ## Review actions

   | # | File | Suggestion | Action |
   |---|------|------------|--------|
   | 1 | spec.md:141 | Fix tag format | Implemented (mutual agreement) — abc123 |
   | 2 | auth.py:48 | Restructure auth flow | Awaiting your decision (disagree) |
   ```

   Follow **Post Top-Level Comment** in the platform cluster files.

10. **Implement changes**:
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

11. **Push changes**:
    ```bash
    git push origin <branch>
    ```

12. **Reply to comments with commit reference** (after implementation):

    Follow **Reply to Inline Comment** in the platform cluster files. Include `Fixed in <COMMIT_HASH>` in the body, referencing the specific commit that addressed that comment.

    For suggestions that were skipped (not approved):
    - Do not reply automatically
    - Let the user handle these manually or in a follow-up

13. **Summary**: Report to user:
    - Number of suggestions auto-implemented (mutual agreement)
    - Number of typo/bug fixes addressed
    - Number of comments replied to with clarification
    - Number of suggestions escalated (awaiting partner decision)

## Important Notes (conditional)

- `address-request-edge-cases.md` — Read when processing comments (step 6+). Contains categorization edge cases, line number drift handling, approval vs investigation distinction, planning document exceptions, re-review requests, and keep-reviews-focused guidance. **Skip on quiet no-ops.**
