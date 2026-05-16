---
name: address-request-comments
description: "Fetch and address request comments from a pull request (GitHub) or merge request (GitLab)."
argument-hint: "[--comment-only] [request-number]"
allowed-tools: Bash, Edit, Glob, Grep, Read, Write
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Address Review

Fetch and address review comments from a pull request (GitHub) or merge request (GitLab).

## Usage

- `/git:address-request-comments` - Address comments on review for current branch
- `/git:address-request-comments <number>` - Address comments on specific review
- `/git:address-request-comments <url>` - Address comments on review by URL
- `/git:address-request-comments --comment-only <number>` - Comment only, no code changes
- `/git:address-request-comments --implement <number>` - Force implementation even on others' MRs

## Reference Files (conditional — read only when needed)

- `~/.claude/skill-references/request-interaction-base.md` — **Read first.** Shared fetch, tracking, footnote, and resolution patterns
- `request-reply-templates.md` — Read before composing replies (step 8)
- `request-lgtm-verification.md` — Read only when an LGTM comment is detected
- `address-request-edge-cases.md` — Read when processing comments (step 6+). Skip on quiet no-ops.
- All provider directories from `~/.claude/learnings-providers.json`, plus `docs/learnings/` — Glob filenames at step 4; read files whose domain matches the comments' subject matter

## Instructions

**Role:** Addresser. Read `~/.claude/skill-references/request-interaction-base.md` for shared patterns (platform commands, consolidated fetch, incremental tracking, footnotes, reply naming, mutual resolution). This skill uses `YOUR_ROLE=Addresser` and `OTHER_ROLE=Reviewer` throughout.

### Mode Detection

Set `COMMENT_ONLY` mode using this precedence:
1. **Explicit flag** — `--comment-only` in arguments → `COMMENT_ONLY=true`; `--implement` → `COMMENT_ONLY=false`
2. **Auto-detect** (no flag) — after the consolidated fetch in step 1, compare the request author's username against the current git user (`git config user.name` or platform username). If they differ → `COMMENT_ONLY=true`. If they match → `COMMENT_ONLY=false`.
3. **Terminal state** — merged/closed requests default to `COMMENT_ONLY=true` (skip Terminal State Handling's hard stop; proceed with comment-only flow instead).

Announce the mode after detection: `Mode: comment-only (not the author)` or `Mode: comment-only (explicit)` or `Mode: implement`.

When `COMMENT_ONLY=true`:
- **Skip** steps 3 (checkout), 9 (act on suggestions), 11 (implement), 12 (push), 13 (reply with commit ref)
- **Adjust step 8** reply tone — use "recommend" / "suggest a follow-up" instead of "I'll fix" / "acknowledged, fixing"
- **Adjust step 10** summary — action column uses "Commented (agree)", "Commented (disagree)", "Clarified", etc. instead of "Implemented" / "Awaiting your decision"
- **Adjust step 14** summary — report comments posted, not changes implemented

1. **Fetch request data** — follow the base reference: **Platform Commands** → **Consolidated Fetch** → **Terminal State Handling**. Then fetch inline comments by running the **Fetch Inline/Review Comments** script (returns `id, in_reply_to_id, commit_id, path, line, body, user, created_at`):
   !`cat ~/.claude/platform-commands/fetch-inline-comments.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
   Pipe the JSON output through the Write tool into `tmp/claude-artifacts/change-request-replies/pr-<REQUEST_NUMBER>-inline-comments.json` (project `tmp/`, never `/tmp/`). Apply **Incremental Fetch Rules** and **Quiet No-Op** from the base reference. On quiet no-op, stop here.

   **Never dismiss comments as duplicates based on topic.** Each comment ID is a distinct interaction that requires its own response — even if a previous comment on the same thread covered the same topic. A "duplicate" is only a comment you already replied to (same ID). Different comment IDs from different review passes are separate comments, not duplicates.

2. **Display comments summary**:
   - Group by file path (from `path` on GitHub, `position` data on GitLab)
   - Show each comment with: file, line number, author, and content
   - Number each comment for reference (store as `COMMENTS` list)
   - **Include new operator comments on previously-replied threads.** A commit-ref reply doesn't close a thread — check all threads for non-self comments (especially operator, no `Role:` tag) posted after the last addresser reply.

3. **Checkout the review branch** if not already on it. **Skip if `COMMENT_ONLY`.**
   ```
   !`cat ~/.claude/platform-commands/checkout-review.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
   ```

4. **Load relevant learnings** *(load-bearing — grounds assessments in cluster knowledge, not first principles; persona proactive loads don't replace this)*: Read `~/.claude/learnings-providers.json` to discover all provider directories. Glob each provider's `localPath/` and `docs/learnings/` filenames and identify any whose domain matches the comments' subject matter (e.g., a comment about skill structure → `claude-authoring-skills.md`, a comment about test patterns → `testing-*.md`). Read matched files so categorization and replies are grounded in established knowledge. Skip this for trivial comments (typos, praise).

5. **Activate persona** (Implementation-start gate): Before assessing suggestions or posting replies, fire the persona gate per `~/.claude/guidelines/context-aware-learnings.md`. Persona shapes both the assessment lens and the `*Persona:*` footer on every reply.

   - Scan the comments' subject-matter domains (e.g., TypeScript, Go backend, infra, docs, CI).
   - **No persona active + domain match exists:** announce `🎭 No persona active — recommending <name>. Set it?` and wait for operator confirmation before proceeding. Use `set-persona` once confirmed.
   - **Persona already active:** announce `🎭 Persona active: <name> — proceeding`.
   - **No domain match:** announce `🎭 No persona — none relevant, proceeding without`.

   **Skip this step entirely** when every comment is trivial (typos, praise, LGTM reacts) — a domain lens is not load-bearing for a typo fix.

6. **Form independent assessment**: For each suggestion, determine what you think the right change is *before* evaluating whether you agree with the reviewer. Read the file context, pull relevant learnings, and reason about the problem independently. Agreement should be a conclusion you arrive at, not a starting position.

   - **Multi-part comments:** Enumerate every distinct point the reviewer raises. Map your proposed change to each one. If your plan doesn't cover a point, either address it or push back on why.
   - **Multi-option suggestions:** When a reviewer offers alternatives, evaluate each against the content's structure. Don't default to the simplest fix.
   - **Push back when warranted:** If the reviewer's suggestion is wrong, incomplete, or misses context, say so — respectfully, with reasoning. This applies to both agent and operator reviewers.

7. **Categorize each comment in `COMMENTS`**:
   a. Read the relevant file and understand the context
   b. Categorize each comment as one of:
      - **Suggestion** - Proposes a code change, architectural change, or different approach
      - **Typo/Bug fix** - Points out an obvious error (typo, missing import, clear bug)
      - **Clarification request** - Asks a question or requests explanation
      - **General feedback** - Praise, acknowledgment, or non-actionable comment
      - **Out of scope** - Valid but should be a separate issue

   Apply the **Mutual Resolution Filter** from the base reference before replying.

8. **Reply to all comments on the platform**:
   Read `request-reply-templates.md` for tone guidance, then reply directly on the platform:
   - For suggestions: Enumerate the reviewer's distinct points. Map your proposed change to each one. If your plan doesn't cover a point, address it or push back on why. Push back on points you disagree with rather than silently skipping them.
   - For clarification requests: Provide the explanation
   - For typo/bug fixes: Acknowledge and confirm you'll fix it (or "recommend fixing" if `COMMENT_ONLY`)
   - For general feedback/positive signals: React with a `rocket` emoji only. No text reply needed.
     ```
     !`cat ~/.claude/platform-commands/react-to-comment.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
     ```

   **IMPORTANT:** Do NOT prompt the operator in CLI for approval at this step. Always reply to comments on the platform first.

   **All replies thread under the parent discussion — even for top-level operator notes.** Every note has a `discussion_id`, whether it's inline (DiffNote with `position`) or top-level (no `position`). Use the discussion-reply endpoint (`reply-to-inline-comment.sh`) for both — it accepts any `discussion_id`. NEVER use `post-top-level-comment.sh` to "reply" to a top-level note: that endpoint creates a new floating discussion instead of threading under the parent, leaving the operator's directive as a single-note discussion with the addresser's responses scattered as siblings rather than children.

   **Before proceeding to step 8, run the Footnote Enforcement check** from the base reference against every comment ID you just posted. Missing footnotes must be fixed here — not deferred — since later steps (mutual resolution, watermarks, self-filter) all depend on the `Role:` tag.

8. **Act on suggestions based on agreement** — **Skip if `COMMENT_ONLY`.**

   **Auto-implement** when both agents converge (addresser agrees with reviewer's suggestion). Also auto-implement typo/bug fixes (corrections, not debatable).

   **Escalate to partner** when the addresser disagrees or is uncertain about a reviewer suggestion. Do NOT implement — wait for explicit approval in a subsequent PR comment (e.g., "go ahead", "all", "1,2") or in CLI.

   Use **Comment Identity** from the base reference to distinguish reviewer/operator comments. Operator suggestions follow the same escalation logic (agree = implement, disagree = escalate).

9. **Top-level summary (conditional — default is skip)**:

   **Default: do not post a top-level comment.** Inline thread replies are the complete record. A summary restating what's already in threads adds no signal and costs the operator's attention.

   **Post only when the table would have rows that need operator attention** — escalations, pushbacks, partial agreements, clarifications awaiting response. Implemented suggestions are documented in their inline thread replies and **must not** appear as table rows. The top-level comment exists for operator-actionable status, not as an audit log of completed work.

   Decision gate before drafting: enumerate items needing operator attention. If the count is zero, stop — do not draft, do not post. If the count is non-zero, draft the summary covering only those items.

   When the gate passes (non-zero operator-actionable items):
   ```
   ## Review actions

   N implemented — see inline comments.

   | # | File | Suggestion | Action |
   |---|------|------------|--------|
   | 2 | auth.py:48 | Restructure auth flow | Awaiting your decision (disagree) |
   | 5 | config.py:12 | Extract constant | Partial — addressed main concern, see thread |
   ```

   **`COMMENT_ONLY` variant** — omit rows where action is "Commented (agree)" or "Clarified" (those are self-evident from the thread). Only include disagreements and items needing follow-up:

   ```
   ## Review actions (comment-only)

   N agreed — see inline comments.

   | # | File | Comment | Action |
   |---|------|---------|--------|
   | 2 | auth.py:48 | Restructure auth flow | Commented (disagree) — pushed back |
   ```

   **Post top-level comment:**
   ```
   !`cat ~/.claude/platform-commands/post-top-level-comment.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
   ```

11. **Implement changes** — **Skip if `COMMENT_ONLY`.**
    a. Group changes by logical concern (e.g., variable elimination, section reordering, typo fixes). Each group becomes its own commit.
    b. For each group:
       - Make the changes
       - Stage the relevant files: `git add <paths>`
       - Commit with a message describing the specific concern:
         ```bash
         git commit -m "$(cat <<'EOF'
         <descriptive message for this group>

         Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
         EOF
         )"
         ```
    c. Track which comments are addressed by each commit hash.

12. **Push changes** — **Skip if `COMMENT_ONLY`.**
    ```bash
    git push origin <branch>
    ```

13. **Reply to comments with commit reference** (after push — mandatory) — **Skip if `COMMENT_ONLY`.**

    **Do not skip this step.** Step 8 posted an initial reply (acknowledgement/agreement). This step posts a **second reply** on the same threads with the commit hash. Reviewers need the commit ref to verify the fix — the review actions summary alone is not enough.

    For each implemented suggestion/fix, follow **Reply to Inline Comment** in the platform command scripts. Include `Fixed in <COMMIT_HASH>` in the body, referencing the specific commit that addressed that comment. **Append the Footnote Format — same rules as step 7 — and run the Footnote Enforcement check against every commit-ref reply before proceeding to step 13.**

    For suggestions that were skipped (not approved):
    - Do not reply automatically
    - Let the operator handle these manually or in a follow-up

14. **Summary**: Report to the operator:
    - Number of suggestions auto-implemented (mutual agreement) — or "commented on (agree)" if `COMMENT_ONLY`
    - Number of typo/bug fixes addressed — or "flagged" if `COMMENT_ONLY`
    - Number of comments replied to with clarification
    - Number of suggestions escalated (awaiting partner decision) — or "commented on (disagree)" if `COMMENT_ONLY`

## Important Notes (conditional)

- `address-request-edge-cases.md` — Read when processing comments (step 6+). Contains independent assessment guidance, categorization edge cases, line number drift handling, approval vs investigation distinction, planning document exceptions, re-review requests, and keep-reviews-focused guidance. **Skip on quiet no-ops.**
