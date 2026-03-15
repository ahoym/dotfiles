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

- `~/.claude/skill-references/request-interaction-base.md` — **Read first.** Shared fetch, tracking, footnote, and resolution patterns
- Platform cluster files — loaded via the base reference's Platform Detection section
- `request-reply-templates.md` — Read before composing replies (step 6)
- `request-lgtm-verification.md` — Read only when an LGTM comment is detected
- `address-request-edge-cases.md` — Read when processing comments (step 5+). Skip on quiet no-ops.
- `~/.claude/learnings/`, `~/.claude/learnings-private/`, `docs/learnings/` — Glob filenames at step 4; read files whose domain matches the comments' subject matter

## Instructions

**Role:** Addresser. Read `~/.claude/skill-references/request-interaction-base.md` for shared patterns (platform detection, consolidated fetch, incremental tracking, footnotes, reply naming, mutual resolution). This skill uses `YOUR_ROLE=Addresser` and `OTHER_ROLE=Reviewer` throughout.

1. **Detect platform and fetch** — follow the base reference: **Platform Detection** → **Consolidated Fetch** → **Terminal State Handling**. Then fetch inline comments via **Fetch Inline/Review Comments** from the platform cluster files. Apply **Incremental Fetch Rules** and **Quiet No-Op** from the base reference. On quiet no-op, stop here.

   **Never dismiss comments as duplicates based on topic.** Each comment ID is a distinct interaction that requires its own response — even if a previous comment on the same thread covered the same topic. A "duplicate" is only a comment you already replied to (same ID). Different comment IDs from different review passes are separate comments, not duplicates.

2. **Display comments summary**:
   - Group by file path (from `path` on GitHub, `position` data on GitLab)
   - Show each comment with: file, line number, author, and content
   - Number each comment for reference (store as `COMMENTS` list)

3. **Checkout the review branch** if not already on it — follow **Checkout Review Branch** in the platform cluster files.

4. **Load relevant learnings**: Glob `~/.claude/learnings/`, `~/.claude/learnings-private/`, and `docs/learnings/` filenames and identify any whose domain matches the comments' subject matter (e.g., a comment about skill structure → `claude-authoring-skills.md`, a comment about test patterns → `testing-*.md`). Read matched files so categorization and replies are grounded in established knowledge. Skip this for trivial comments (typos, praise).

5. **Categorize each comment in `COMMENTS`**:
   a. Read the relevant file and understand the context
   b. Categorize each comment as one of:
      - **Suggestion** - Proposes a code change, architectural change, or different approach
      - **Typo/Bug fix** - Points out an obvious error (typo, missing import, clear bug)
      - **Clarification request** - Asks a question or requests explanation
      - **General feedback** - Praise, acknowledgment, or non-actionable comment
      - **Out of scope** - Valid but should be a separate issue

   Apply the **Mutual Resolution Filter** from the base reference before replying.

6. **Reply to all comments on the platform**:
   Read `request-reply-templates.md` for tone guidance, then reply directly on the platform:
   - For suggestions: State whether you agree/disagree and your proposed approach
   - For clarification requests: Provide the explanation
   - For typo/bug fixes: Acknowledge and confirm you'll fix it
   - For general feedback/positive signals: React with a `rocket` emoji (default) AND post a brief text acknowledgement (1-2 sentences). Follow **React to Comment** in the platform cluster files.

   **IMPORTANT:** Do NOT prompt the user in CLI for approval at this step. Always reply to comments on the platform first.

   Append the **Footnote Format** from the base reference to every reply. Follow **Reply to Inline Comment** in the platform cluster files. Use **Reply File Naming** convention from the base reference.

7. **Act on suggestions based on agreement**:

   **Auto-implement** when both agents converge (addresser agrees with reviewer's suggestion). Also auto-implement typo/bug fixes (corrections, not debatable).

   **Escalate to partner** when the addresser disagrees or is uncertain about a reviewer suggestion. Do NOT implement — wait for explicit approval in a subsequent PR comment (e.g., "go ahead", "all", "1,2") or in CLI.

   Use **Comment Identity** from the base reference to distinguish reviewer/human comments. Human suggestions follow the same escalation logic (agree = implement, disagree = escalate).

8. **Post review actions summary on the platform**:
   After processing, post a top-level comment summarizing what was done and what needs the partner's input:

   ```
   ## Review actions

   | # | File | Suggestion | Action |
   |---|------|------------|--------|
   | 1 | spec.md:141 | Fix tag format | Implemented (mutual agreement) — abc123 |
   | 2 | auth.py:48 | Restructure auth flow | Awaiting your decision (disagree) |
   ```

   Follow **Post Top-Level Comment** in the platform cluster files.

9. **Implement changes**:
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
    - Number of suggestions auto-implemented (mutual agreement)
    - Number of typo/bug fixes addressed
    - Number of comments replied to with clarification
    - Number of suggestions escalated (awaiting partner decision)

## Important Notes (conditional)

- `address-request-edge-cases.md` — Read when processing comments (step 6+). Contains categorization edge cases, line number drift handling, approval vs investigation distinction, planning document exceptions, re-review requests, and keep-reviews-focused guidance. **Skip on quiet no-ops.**
