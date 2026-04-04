# Sweep Session Patterns

Patterns and gotchas for director-orchestrated sweep workflows (`sweep-review-prs`, `sweep-address-prs`).

**Keywords:** sweep, director, claude -p, learnings-team, learnings, runner, review, address, gitlab, github
**Related:** `~/.claude/learnings/claude-code/multi-agent/CLAUDE.md`, `~/.claude/learnings/claude-code/shell-patterns.md`

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

## GitLab vs GitHub state values in runner scripts

GitLab `glab mr view` returns lowercase state values (`"opened"`, `"merged"`, `"closed"`), while GitHub `gh pr view` returns uppercase (`"OPEN"`, `"MERGED"`, `"CLOSED"`). Runner script pre-flight checks must match the platform's casing. The sweep runner template uses `gh` patterns — when generating for GitLab, substitute both the CLI commands and the state string comparisons.
