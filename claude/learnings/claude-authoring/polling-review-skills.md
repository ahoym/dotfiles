Patterns for `/loop` polling skills, quick-exit optimization, re-review detection, reviewer timestamps, and three-party review discussions.
- **Keywords:** polling, quick-exit, re-review, SHA check, self-filter, cron, stale poll, force push, footnote, GitHub review API, 422
- **Related:** ~/.claude/learnings/claude-code/multi-agent/orchestration.md, ~/.claude/learnings/process-conventions.md

---

> Core skill design patterns → `~/.claude/learnings/claude-authoring/skill-design.md`

## Re-Review Detection via Footnote Pattern Matching

When a skill needs to find its own previous comments for incremental/re-review workflows, filter by the structured footnote (`*Persona:* <name>` AND `*Role:* <role>`) rather than by username. This scopes re-review to the correct comment chain and avoids cross-contamination from other agents, other personas, or the same persona in a different role.

## Polling Skills Must Fetch Fresh API Data Every Invocation

Skills designed for `/loop` polling must hit the API on every invocation — never short-circuit based on in-context memory of previous runs. The whole point of polling is that external actors (other agents, humans) push changes between runs. Relying on "I already checked this PR" from a prior invocation silently breaks the polling contract.

## Quick-Exit Before Expensive Fetches

Polling skills should check for changes with the cheapest possible API call before fetching full diffs or comment histories. Compare the latest commit SHA and reply count against the last review's timestamp — if both are unchanged, emit a one-liner and stop. This avoids wasting context budget on the full diff fetch when nothing has changed.

## Compact Summary Queries for Repeated Polling

On repeated poll cycles, use `--jq` to extract a compact summary object from the consolidated fetch instead of parsing full JSON in-agent. Example: `gh pr view <N> --json commits,reviews,state,comments --jq '{state, latest_commit: .commits[-1].oid[0:7], latest_commit_date: .commits[-1].committedDate, num_reviews: (.reviews | length), num_comments: (.comments | length), latest_review_body_ts: [.reviews[] | select(.body | length > 0) | .submittedAt] | sort | last}'`. This reduces a multi-KB JSON response to ~200 bytes — significant savings across 20+ poll cycles. Works when `Bash(gh pr view:*)` is already in allow patterns (the `--jq` flag doesn't change the command match).

## Quick-Exit Must Filter Self-Comments

Quick-exit checks must fetch N recent comments (`per_page=10`), filter out self-comments (`Role:.*<YOUR_ROLE>`), then interpret: non-self present and all old → no activity; non-self present and some new → proceed; all self → inconclusive, fall through to full fetch. This catches operator comments sandwiched between agent replies and prevents false-triggers from the agent's own post-review activity.

## Empty-Body Reviews Are Not Reliable Activity Signals

GitHub creates empty-body review entries as wrappers when inline comment replies are posted. Treating these as activity signals in phase 1 of a quick-exit check causes false triggers on every poll cycle after a re-review — the agent's own replies generate empty-body reviews that never age past `LAST_REVIEW_TS`. Instead, rely on phase 2 (inline comment fetch with self-filter) to catch the actual inline activity that these wrappers represent. Only non-empty-body reviews from non-self sources should count as phase 1 signals.

## Never Reduce Quick-Exit to Commit-Only Checks

During long polling sessions, it's tempting to optimize the quick-exit from full phase 1+2 (2 API calls) down to a commit-SHA-only check. This silently drops coverage for inline comments, top-level comments, and reviews — all activity types that arrive without new commits. Worse, the stale poll auto-cancel compounds the problem: the poll misses the comment, keeps no-oping, then cancels after 30 minutes — permanently orphaning the comment. Phase 1 (consolidated fetch) is the minimum; phase 2 (inline comment check) fires only when phase 1 is quiet. Both are cheap. Don't optimize them away.

## Self-Canceling Polling Loops

Skills invoked via `/loop` can self-cancel when the target becomes irrelevant (e.g., PR merged/closed). Use `CronList` to find the cron job whose prompt matches the skill name + target identifier, then `CronDelete` to cancel it. The skill doesn't know its own job ID, but prompt-pattern matching is reliable since each loop has a unique prompt string.

## State Check as Earliest Exit Point

Review/polling skills should check the target's state (merged, closed, open) before any review logic. This is cheaper than commit SHA comparison and catches the terminal case where no further polling is needed. Order: state check → quick-exit (commit SHA) → full review.

## Cache-Then-Validate for Repeated Skill Invocations

When a skill runs repeatedly within a session (via `/loop` or manual re-invocation), cache both **analysis data** (diffs, findings) and **reference files** (shared references, platform cluster files, persona files) after the first read. Validate with the cheapest possible check rather than re-fetching. For analysis: if the commit SHA hasn't changed, trust the cached diff and findings. For reference files: read once on first invocation, skip re-reads on subsequent invocations unless a new commit modifies the file. A 20+ invocation polling session re-reading 6-7 reference files per cycle wastes hundreds of reads on unchanged content.

## Polling as Skill Stress-Test

Repeated invocations via `/loop` surface edge cases that single runs hide: self-reply filter mismatches, CWD drift from mid-session directory changes, missing terminal-state exits. When a skill is designed for polling, run it through a few cycles before considering it stable — the first invocation tests the happy path, subsequent invocations test state management.

## Reviewer Timestamp Stalls on Reaction-Only Invocations

When the reviewer posts only thread replies and reactions (no review body — per "don't post empty reviews"), `LAST_REVIEW_TS` stays at the last formal review submission. Subsequent polls detect already-processed addresser replies as "new" (they're after `LAST_REVIEW_TS`), triggering phase 2 and thread checks that find nothing to do. The mutual resolution / already-processed logic catches it, but the wasted API calls and context repeat every cycle until the stale poll auto-cancel fires. Not a bug — the "don't post empty reviews" rule is correct — but a known cost of reaction-only re-review cycles.

## Session-Scoped State for Cron-Lifecycle Concerns

When tracking state that shares a cron job's lifecycle (e.g., last-activity timestamps for stale poll detection), use session context (conversation memory) rather than files. File-based state requires creation, gitignore, cleanup on terminal state, and permission patterns — all complexity that disappears when the state lives and dies with the session. The tracking-artifacts file approach was tried and reverted within one PR cycle in favor of session variables.

## Scope Expansion in Three-Party Review Discussions

Review threads between operator, reviewer agent, and addresser agent can legitimately evolve from code feedback into convention changes. The keep-reviews-focused guidance applies to *unrelated* changes — when the partner explicitly approves expanding scope (e.g., "make the edit in this PR"), that's authorization, not scope creep. The addresser should still flag the expansion ("this feels like a design discussion for X rather than this PR") before proceeding, giving the partner a chance to defer. But once approved, implement in the current PR rather than forcing a follow-up.

## Quick-Exit Devolution Under Consecutive No-Ops

Consecutive no-op polls create progressive optimization pressure: the agent reduces phase 1 from the full consolidated fetch (`--json commits,reviews,state,comments`) to just state + last commit SHA, then drops phase 2 entirely. Each reduction feels justified ("nothing changed last time") but silently narrows the detection surface. The failure compounds: missed operator comment → more no-ops → more optimization → stale poll auto-cancel orphans the comment permanently.

**Fix location matters.** Anti-devolution language in Important Notes gets deprioritized under the same efficiency pressure that causes the devolution. The preamble must be inline at the top of step 5 itself — that's where the agent reads instructions at point of use. Important Notes reinforce but don't prevent.

## Operator Comments Are Invisible When Mentally Grouped with Addresser

Phase 2 self-filtering correctly identifies `Role:.*Reviewer` as self-comments. But the agent mentally categories remaining comments as "Addresser replies" — overlooking that comments with **no Role tag** are from the operator, not the Addresser. Both are "non-self" in the filter, but operator comments require immediate response while Addresser replies follow the acknowledgement/resolution flow. The fix: when scanning phase 2 results, explicitly check for three categories (self / agent-other / operator), not two (self / non-self).

## GitHub Review Batch: All Lines Must Be in a Diff Hunk

GitHub rejects an entire review with 422 "Line could not be resolved" if ANY inline comment targets a line outside the PR's diff hunks. Unchanged lines that aren't within a diff hunk context are not commentable — even if they're logically related to the change.

**Fix**: before building the inline comment array, verify each target line appears in the diff. Lines outside any hunk → move to review body or post as a standalone comment. One invalid line tanks the whole batch.

## Force Push: SHA Changes, Dates Don't

When a PR branch is force-pushed, the head SHA changes but all commit author dates remain unchanged. A date-filtered commit fetch (`since=LAST_REVIEW_TS`) returns empty — identical to "no new commits."

**Detection**: head SHA differs from last reviewed SHA AND date filter returns nothing → likely force push, not new code. Handle by processing any new inline/top-level comments but skipping full diff analysis (same code, different graph).

## Commit Pushed During Analysis Window

A commit can land between phase 1 (SHA check) and review posting. If it fixes an issue you're about to flag as "not addressed," your review will be wrong the moment it's posted.

**Mitigation**: before posting any `❌ not addressed` inline comment or "still open" follow-up, re-verify against the latest commit list — not just the SHA captured at phase 1. If a new commit landed since phase 1, check whether it addresses the finding before posting.

## Cross-Refs

- `~/.claude/learnings/claude-code/multi-agent/orchestration.md` — reviewer-addresser cycle architecture, iterative testing for autonomous features
- `~/.claude/learnings/process-conventions.md` — structured footnote template for multi-agent comment identity
