Watermark recording, skip-detection logic, and rerun semantics — what makes single-pass sweep sessions safe to relaunch.
- **Keywords:** watermark, skip, last_comment_id, single-pass, dual-signal, self-comment, post-action, sweeper-regex, pre-flight, manifest-updates
- **Related:** runner-design.md, observability.md

---

## Skip Confirmation in Sweep Skills

Sweep skills should present the assessment summary table (for visibility) but proceed directly to artifact generation without prompting for confirmation. Operator curates by passing specific PR numbers (`/sweep:review-prs #49 #47`), not by interactive exclusion after assessment.

## Incremental Manifest Updates

`manifest-updates.json` (append-only JSONL) supports adding/removing items without regenerating the full artifact structure. The runner reads it once on relaunch (not mid-run), applying `add` (new items with prompt.txt ready) and `close` (writes terminal status.md so pre-flight skips). The director writes updates between cycles; sweep skills don't need to be re-invoked for routine changes.

## Sweeper Footer Regex Must Handle Markdown Italics

The Sweeper footnote renders as `*Role:* Sweeper` (markdown italics). Use `Role.*Sweeper` (no colon in pattern) to match both plain and italic forms. Same for `Sweeper-Confirm`.

## Post-Action Watermark Recording

Agents that post comments (clarifiers, confirmers) must record watermarks *after* posting, not before. The agent's own comment changes the issue's `updatedAt` and `last_comment_id` — recording pre-post values creates a perpetually stale watermark where every rerun sees "new activity" (its own prior post). Re-fetch `updatedAt` and `last_comment_id` after the `gh issue comment` call and use those values in `status.md`.

## Self-Comment Guard

Watermark diffs alone don't distinguish "human replied" from "agent posted last time." Before acting on a watermark mismatch, check whether the latest comment is from a sweeper role (`Role:.*Sweeper` or `Role:.*Sweeper-Confirm` in the comment body). If the latest comment is the agent's own and `status.md` shows `milestone: done`, skip — there's no new human input. This is defense-in-depth alongside the post-action watermark fix.

## Dual-Signal Watermark Comparison

Require both `last_comment_id` AND `updatedAt` to match before skipping a work item. Either signal alone has blind spots: `last_comment_id` misses body/label edits (which change `updatedAt` without adding comments), and `updatedAt` alone could miss propagation edge cases. The two signals cover each other — any mutation breaks at least one.

## Pre-Filter Converged Items Before Launching Sweeps

Launching a sweep run for items that already converged wastes a full session startup (~30s + API cost) for a no-op quick-exit. The director should check convergence signals (HEAD SHA unchanged, no new comments since last review) before including items in the manifest. This is distinct from the runner's pre-flight skip — the director has cross-session state and can avoid generating artifacts entirely.

## Runner Pre-Flight: Entity Terminal States Only, Not Role Convergence

The runner's bash pre-flight skip should gate only on **entity terminal states** (`issue_state: CLOSED`, `pr_state: MERGED/CLOSED`) — never on role convergence signals (`comment_posted`, `pr_opened`, `confirmation_posted`). Convergence signals mean "this role's job is done for now," not "this entity is done." Adding them to pre-flight causes confirm/implement cycles to false-skip after the clarifier posts. The session's internal watermark logic handles "nothing new since last pass" — the runner's job is the cheap cost-optimization skip for truly terminal entities. Same boundary as `state.md` (runner) vs `status.md` (session): don't read session-domain signals in runner code.

## Sweep Sessions Are Single-Pass — No Polling

A completed `claude -p` sweep session exits and does not re-check watermarks. New comments or replies posted *after* the runner finishes are invisible until the director re-assesses. The director must relaunch the sweep skill (fresh `RUN_DIR`, fresh manifest) to pick up new activity — re-running `let-it-rip.sh` alone is not enough since each session's internal watermark check happens once at launch.

**Implication:** if the operator replies on GitHub while a session is running (or just after it exits), the director must proactively trigger a fresh sweep. Surface this clearly when the operator asks "why didn't X get picked up?" — the answer is almost always "sweep was single-pass; we need to relaunch." Don't promise auto-pickup unless a `/loop` or equivalent watcher is wired.

## Re-Review Body-Only Finding Hidden by Reaction-Advanced Watermark

The summary-only directive pattern is well-known for cycle-0 reviews where `findings > inline_comments` and the watermark stalls. **Re-reviews have a sneakier variant**: reviewer posts reactions (🚀/👍) and replies on existing inline threads, advancing `last_comment_id`, AND posts one new finding in the review summary body. The address watermark sees comment-id mismatch and fires, but the addresser classifies the new comment IDs as "reviewer ack on prior thread" → no actionable work → milestone done with no commit. The body-only finding is invisible.

**Detection:** every review cycle's `results.md` should be checked for `New Findings > New Inline Comments`, not just first-pass. If the differential is non-zero on a re-review, write the directive **immediately** — before launching the next address cycle — instead of relying on the cycle to surface the miss.

**Director rule:** read each completed review's `results.md` proactively on runner-completion notification. Don't defer body-only-finding detection to the address session — its watermark/classification logic can't see body content.
