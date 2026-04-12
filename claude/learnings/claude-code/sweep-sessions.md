# Sweep Session Patterns

Patterns and gotchas for director-orchestrated sweep workflows (`sweep:review-prs`, `sweep:address-prs`).

**Keywords:** sweep, director, claude -p, learnings-team, learnings, runner, review, address, gitlab, github
**Related:** none

## `claude -p` sessions don't trigger learnings-team search gates

`claude -p` sessions load `~/.claude/CLAUDE.md` (which includes learnings-team search guidelines), but don't reliably hit the search gates (session-start, pre-edit, etc.) during prompt execution. The sessions focus on executing the piped prompt instructions and skip ambient learnings discovery.

**Fix:** Add explicit learnings-team search steps in the generated `prompt.txt` templates. The sweep skills now include dedicated steps (review: step 5 `📚 [pre-review]`, address: step 7 `📚 [pre-address]`) that instruct sessions to search `~/.claude/learnings-team/learnings/` before doing work.

**Principle:** Any behavior that depends on CLAUDE.md guidelines being followed proactively (not just reactively) needs explicit prompt instructions when running via `claude -p`.

## `claude -p` output logs don't capture internal reasoning

`tee` in the runner script captures only final assistant stdout (the summary message). Tool calls, `📚` learnings announcements, intermediate reasoning, and skill invocations are invisible in `output.log`. This means operators cannot verify which learnings-team/personal learnings influenced a sweep session by grepping logs.

**Fix:** Sweep prompt.txt must instruct agents to include a "Learnings loaded" section in `learnings.md` listing each file loaded from learnings-team/personal learnings with a one-line note on how it was applied. This is the only persistent, operator-visible record of learnings influence.

## Compound Mode: Generate Address Artifacts Even When "All Addressed"

In `review+address` compound mode, always generate address artifacts for targeted PRs even if assessment shows all comments currently addressed. The review sweep will post new comments that the address runner picks up on relaunch. The address session's built-in watermark/skip logic handles the no-op case gracefully (compares HEAD SHA + latest comment ID, skips if unchanged).

**Anti-pattern:** Skipping artifact generation because "nothing to address" loses the relaunch path. The runner script is the loop target — it must exist before the review posts new findings.

## Summary-Only Review Findings Need Director Directives

When a review posts findings in the summary comment but not as inline comments (e.g., "verify X" observations), the address session's watermark won't detect them — there's no new inline comment ID to trigger a watermark mismatch. The director must read the review summary, extract summary-only findings, and write a per-PR directive with specifics:

```markdown
## <ISO timestamp> — Summary-only findings from re-review
1. <finding description> — <expected action>
2. <finding description> — <expected action>
This directive overrides skip logic.
```

The directive's presence forces the address session to proceed even if the watermark matches.

## Worktree Path Confusion in Address Sessions

`claude -p` address sessions running in worktrees hit path confusion: the prompt references file paths relative to the main repo root, but the session's CWD is the worktree. Sessions self-correct via `pwd` but burn 10+ tool calls on "file not found" errors first.

**Fix:** Prompts should either use relative paths (which resolve against the worktree CWD) or explicitly instruct the session: "Your CWD is the worktree at `<path>`. All file reads should use paths relative to this directory, not the main repo root."

## Review and Address Must Be Separate Sessions

Never have the same agent both review and address an MR. A reviewer that knows it will also address goes easy; an addresser that wrote its own findings rubber-stamps them. In practice, a same-context review missed that a silent-failure workaround should have been challenged as a design problem — an independent reviewer would have pushed harder.

The director presents review findings to the operator for sign-off before launching the address session. This is structural, not a guideline — review integrity requires independent context.

## Compressed Runner Scripts Break xargs Variable Passing

When compressing runner scripts (single-letter variables, collapsed whitespace), `xargs -I {} bash -c 'process_pr "$@"' _ {}` fails to pass the PR number correctly into functions that build paths like `${RUN_DIR}/pr-${pr_num}`. The symptom: paths resolve to `pr-/` (empty variable) instead of `pr-70/`, causing "No such file or directory" on every file operation. The session launches, produces no logs, and errors silently.

**Root cause:** Bash `export -f` with `xargs` is fragile — shortened variable names and compressed function bodies interact poorly with subshell variable scoping. The full-form script (explicit `local` declarations, uncompressed) works reliably.

**Fix:** Never compress runner scripts for "efficiency." The full-form template works; the compressed version saves ~2KB of disk but costs debugging time when it breaks. Use the `parallel-claude-runner-template.sh` template as-is.

## Multi-Phase Issues: Sweeper-Implement Triggers False "Awaiting Reply"

When a multi-phase issue has its first phase implemented (PR merged), the Sweeper-Implement comment is the last comment. Skip detection sees "Sweeper commented, no human reply" → SKIP(Awaiting reply). But the issue isn't awaiting a reply — it's ready for the next phase.

**Workaround:** The director writes a per-issue directive overriding skip logic and explaining which phase is complete and what to plan next. The directive forces the clarify-confirm agent to proceed.

**Fixed:** Rule d in `sweep/work-items/SKILL.md` now checks for `Role:.*Sweeper-Implement` + linked merged PR → eligible for `clarify-confirm` (next phase planning).

## Implement Gate: Conversation Maturity, Not Static Properties

The decision rule for promoting clarify-confirm to implement should check what actually changes between passes — not static issue properties. File targets, expected behavior, and verification method are properties of the issue that don't change between sweeper passes. If they're true on pass 1, they're true on pass 2.

What changes: whether the sweeper has demonstrated understanding of the operator's feedback. The implement gate should check (a) the sweeper's last comment acknowledged a prior operator reply, and (b) the operator's reply is pure approval. The clarify-confirm agent naturally checks implementability as part of drafting its plan — if file targets aren't clear, it asks more questions, keeping the cycle in clarify-confirm without the assessment skill needing to re-verify.

## Watermark Propagation Across Director Session Boundaries

New sweep cycles for previously-addressed PRs start without the prior watermark, triggering full comment re-analysis. Directors should persist per-PR watermarks (HEAD SHA + latest comment ID) and inject them into new session artifacts.

## Comment-Only Re-Reviews Produce Empty Persona Routing

Re-reviews with no new commits (only thread activity) produce empty `RE_REVIEW_PERSONAS` — no changed files to route. Orchestrator handles directly. Correct behavior, but looks like silent failure in logs.

## Director Directive Dedup Gap

Directive files aren't cleared after the referenced operator comment is addressed, causing redundant session launches. Sweep skill should check whether directive targets are already satisfied before launching.

## Phase Numbering Ambiguity in Confirmation Plans

"Phase 1/2/3..." without stating "Single PR containing:" or "Separate PRs:" causes re-clarification rounds. Lead with the delivery structure.

## Subagent Prompts Can't Inherit Centralized Guideline Context

`claude -p` subagents can't resolve provider paths from config files. Parent skills must resolve paths and inject them into prompts. Centralized read gateways help but don't eliminate this for write-path skills.

## Self-Comment Edge Case in Review↔Address Loop

When the reviewer and addresser are the same git user (e.g., operator runs both sweeps), the address session's `Role:.*Addresser` filter only catches agent-posted footers — it doesn't catch operator-posted team review comments from the same username. Result: the address session sees "all comments are from self" and produces a no-op run.

**Root cause:** Self-filter uses `Role:` tag in structured footnotes, not git username. Team review comments posted by the operator carry `Role:.*Team-Reviewer`, which correctly identifies them as review comments to address — but the username match triggers the "don't reply to yourself" heuristic first.

**Workaround:** The address session correctly skips (no harm done), but it wastes a `claude -p` session. The MR author needs to respond to these findings — the address loop can't do it.

## Context % Surfacing from Stream-JSON

The runner can compute per-cycle context window usage by parsing the latest assistant message's `usage` block from `raw.jsonl`: `input_tokens + cache_creation_input_tokens + cache_read_input_tokens` = total tokens the model just processed = current conversation context size at that turn. Divide by the context window (1m for `[1m]` model variants, else 200k) to get a percentage. Write `context_used_tokens`, `context_window`, and `context_pct` to `state.md` in the success branch — gives the director an at-a-glance view of how saturated each worker is, without parsing `raw.jsonl`. Cheap (one `jq | tail -1` call) and useful for deciding when to relaunch a fresh session vs. resume.

## Active-Branch Director Sessions Work via Worktree Reuse

Main is still the preferred director branch — cleanest, fewest gotchas. But the active-branch case is **supported**, not a workaround: when the PR being swept IS the director's current branch, `git worktree list` reports the project root as the worktree for that branch, and the address sweep skill's worktree-reuse path picks it up automatically. No `git worktree add`, no separate `Agent` needed. Discipline: director must not touch the working tree (only reads `tmp/claude-artifacts/.../state.md`) and must not interleave its own commits concurrently with agent commits — sequential is fine. The off-branch case (working on a *different* branch while sweeps run on the active one) is the one that needs `Agent(isolation: "worktree")`. Don't conflate them. Validated end-to-end across an 8-cycle compound mode session on the active branch.

## GitLab vs GitHub state values in runner scripts

GitLab `glab mr view` returns lowercase state values (`"opened"`, `"merged"`, `"closed"`), while GitHub `gh pr view` returns uppercase (`"OPEN"`, `"MERGED"`, `"CLOSED"`). Runner script pre-flight checks must match the platform's casing. The sweep runner template uses `gh` patterns — when generating for GitLab, substitute both the CLI commands and the state string comparisons.
