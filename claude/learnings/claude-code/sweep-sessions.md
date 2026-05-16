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

## Operator Directive Overrides Dependency-Blocker SKIP

`sweep:work-items` Phase 3.a2 normally SKIPs an issue whose `Blocked by: #N` chain has unresolved blockers (no PR, not merged). Operator can override by including an explicit assumption in the run-level `directives.md`:

```markdown
# Run-level directives
Assume #X (B2a) and #Y (B2b) will be merged soon. Base off `main`.
- Treat their symbols as if they exist; if a runtime check would currently fail,
  call it out in the PR body but do NOT modify their target files.
```

When this directive is present, list the blocked issue as `eligible` with `base_branch: main`. The implementer respects the boundary — writes code referencing the assumed-merged symbols, flags any not-yet-functional runtime in the PR body. Reviewer rebases post-blocker-merge.

**When to use:** operator wants to parallelize implementation across the dependency chain. Avoids waiting on serial merges when downstream work is mechanically independent.

**When NOT to use:** if the blocked issue's implementation can't be sensibly written without seeing the blocker's interface (e.g., the blocker is itself unfinalized), proceeding anyway just creates rework.

## Prose-Style Dependencies Invisible to sweep:work-items Parser

The Phase 3.a2 dependency parser only honors `Blocked by:` lines and `## Dependencies` sections. Prose like "Depends on P1.3 and P2.1" inside a Scope or Cross-references block is invisible — the issue is treated as having zero blockers and marked eligible.

**Director compensation pattern when running sweep:work-items on a multi-issue plan:**
1. Before trusting the eligible/skip lists, scan each issue body for prose dep phrases (`Depends on`, `Hard gates`, `requires`, `gated on #N`).
2. Cross-check against `gh pr list --state all` to find PRs for each referenced issue.
3. Apply the same skill rule manually: blocker is resolved if issue CLOSED **or** has any PR (open or merged).
4. Override the assessor's `eligible` → `skipped` for items the parser missed, log to `decisions.md`.

Cheap because most plan-issue bodies have ≤5 prose dep references; the cross-check is 1 `gh pr list` call cached across the sweep.

### Stacked PR Variant (operator wants parallelism)

When prose-deps point to **unmerged open PRs** and the operator chooses to stack rather than wait, manually set `BASE_BRANCH` to the predecessor's `headRefName` in each issue's `metadata.json` before invoking `work-items-generate-runner.sh`:

```json
{"BASE_BRANCH": "sweep/153-mnq-backtest-runner-walkforward-spy", ...}
```

The work-items runner does `git fetch origin <BASE_BRANCH>` for non-default bases. The implementer's prompt picks up `--base <BASE_BRANCH>` for `gh pr create`. **Pre-launch check:** `git ls-remote origin <branch>` to confirm the predecessor branch exists on origin (runner's fetch is silent-fail).

**Diamond constraint:** stack only on a single linear chain. If an issue depends on multiple unmerged PRs on different branches, fall back to `BASE_BRANCH=main` and accept the missing-symbol risk OR wait for at least one predecessor to merge.

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

## Reviewer Prompt Gap: Skill Bypass on Re-Review

`claude -p` review sessions skip the `Skill("git:team-review-request")` call when reasoning space exists between the preflight watermark check and the skill invocation. The session fetches the diff, decides "content unchanged" or "all findings addressed," and posts a `gh pr comment` (issue comment) directly — bypassing re-review reactions, the re-review body template, and proper `gh pr review` posting. Diagnostic signal: the review URL is an `issuecomment-*` fragment instead of a `pullrequestreview-*` fragment, and no emoji reactions appear on resolved inline comments.

**Fix:** Make the Skill call the first action after preflight passes — no diff fetch, no analysis, no learnings search between them. The skill handles its own quick-exit, re-review detection, and learnings loading internally. The wrapper prompt retains responsibility for domain-context learnings needed by the write-artifacts/write-learnings phases that run after the Skill returns.

**See also:** `~/.claude/learnings/claude-authoring/skill-design.md` § "Delegating Prompts Must Not Expose Delegated Inputs" for the general principle.

**Validated:** After collapsing the gap, session 2 posted a proper `pullrequestreview` with 8 inline comments, and session 3's re-review posted reactions on the correct reply comments. The `issuecomment` diagnostic signal is reliable for detecting regressions.

## Director Artifact Generation Can Be Batched

When generating artifacts for a single-PR session, all writes (manifests, metadata, data files, preflight copies) are independent and can be issued in parallel. Prompt assembly (`fill-template.sh`) depends on metadata being written first but all prompts can be assembled in parallel. Runner assembly depends on runner metadata. Three sequential batches: data files → prompts → runners. Reduces wall-clock time for multi-PR sessions.

## GitLab vs GitHub state values in runner scripts

GitLab `glab mr view` returns lowercase state values (`"opened"`, `"merged"`, `"closed"`), while GitHub `gh pr view` returns uppercase (`"OPEN"`, `"MERGED"`, `"CLOSED"`). Runner script pre-flight checks must match the platform's casing. The sweep runner template uses `gh` patterns — when generating for GitLab, substitute both the CLI commands and the state string comparisons.

## Static Prompt Can't Transition Lifecycle Roles

Runner scripts replay the same `prompt.txt` on every relaunch. A clarifier prompt that completes (posts questions, gets answers, posts acknowledgment) will skip on relaunch — its own Sweeper comment is the latest, watermark matches, no new activity. To transition from clarify → confirm → implement, invoke `sweep:work-items` again for a fresh assessment that evaluates conversation state and generates artifacts with the matching template. The runner is the loop target for *within-role* reruns; cross-role transitions require reassessment.

## Sub-Issues From Confirmed Plans Lack Sweeper History

Issues created by the director from a confirmed parent plan (e.g., #92/#93 from #90's confirm pass) have no Sweeper comments. The lifecycle assigns `clarify` despite full specification. Workaround: post an operator comment ("Plan confirmed from #N. Implement.") before assessment. The assessment sees the operator comment with no prior Sweeper → still assigns clarify. The real fix: assessment should detect `Relates to #N` + parent issue has `Sweeper-Confirm` approval + operator comment referencing the parent → skip to implement.

## Template Scripts Fail `bash -n` Validation

Platform-command scripts use `<PLACEHOLDER>` syntax (e.g., `gh pr view <N> --json ...`) which isn't valid bash. `bash -n` verification triggers permission denials (no allow pattern for `bash -n`) and would fail on syntax anyway. The scripts are command templates, not executable scripts — validation should check format/structure, not bash syntax. Don't add a `bash -n` permission pattern for these.

**Helper search corollary:** when looking for a skill-reference helper to satisfy an operator's "is there a script for this?" question, the `.sh` files split into two shapes:

| Shape | Location pattern | Invocation | Examples |
|-------|------------------|-----------|----------|
| Executable wrapper | `~/.claude/skill-references/*.sh` (top level) | `bash <path> <args>` | `sweep-status-summary.sh`, `init-sweep-pr-dir.sh`, `director-bootstrap.sh` |
| Template stub | `~/.claude/skill-references/<platform>/commands/*.sh` | Inlined into prompts via `fill-template.sh`; placeholders like `<N>` | `fetch-pr-watermark.sh`, `check-pr-mergeable.sh`, `consolidated-fetch.sh` |

Top-level `.sh` files are runnable. Per-platform `commands/` `.sh` files are command-text templates — open one to confirm: a single `gh pr view <N> --json …` line is a stub. When no executable wrapper exists, fall back to plain allowlisted CLI (`gh pr view <N> --json state,mergeable`), and parse JSON via `jq` — not `gh -q` with a quoted format string (those trip permission prompts).

## Confirmer Should Pre-Seed Sub-Issue Approval

When a confirmer proposes sub-issues as part of its confirmation comment, it should also post approval comments on those sub-issues (after the director creates them). This eliminates the manual step where the operator or director must post "Plan confirmed from #N. Implement." before the assessment can assign the implement role. The confirmer already has the confirmed plan context — it can propagate approval downstream.

## Confirmer Must Propose Sub-Issues for Independent Phases

When a confirmer's plan has N independent phases that could each produce a separate PR, the confirmer should propose sub-issues — not present them as phases of a single implementation. One issue → one PR is the default; multi-phase plans that don't split upfront create monolithic PRs that are hard to review, slow to merge, and block clean phases behind dirty ones. The clarifier's scope assessment identifies the split; the confirmer should honor it by proposing concrete sub-issues with titles, scopes, and dependency order.

## `parallel-claude-runner-template.sh` Handles Both PRs and Issues

The runner template is generalized: `ITEMS=(...)`, `ENTITY_PREFIX` (`pr`|`issue`), `ENTITY_LABEL`, `STATE_FIELD`, `TERMINAL_STATES`, plus `FETCH_ITEM_STATE_CMD` (literal platform command referencing `$pr_num` — same key used by both the launch probe and `process_item`'s API fallback). Block conditionals `{{#BRANCHES}}...{{/BRANCHES}}` and `{{#WORKTREES}}...{{/WORKTREES}}` strip worktree setup when empty — clarify-only `sweep:work-items` runs set both to `""`. All 4 entity keys + `FETCH_ITEM_STATE_CMD` are required — no defaults.

## `sweep-status-summary.sh` for Work-Items, Not `sweep-status.sh`

`~/.claude/skill-references/sweep-status.sh` only iterates `pr-*/` — returns empty output on work-items runs with no error. Use `sweep-status-summary.sh` instead; it handles both `pr-*/` and `issue-*/` and has `--logs N` / `--retro` flags. Default to summary for any sweep status check.

## Persona Auto-Detect Sharpens Clarifier Output

In a two-issue parallel clarify sweep, the CI-lint issue triggered `platform-engineer` persona and the clarifier found 3 existing codebase violations of the constraint being proposed (blocking signal the operator would have otherwise hit on merge). The no-persona issue produced well-formed questions but didn't grep for violations. For constraint/lint/guardrail issues specifically, persona activation is load-bearing — it shifts the clarifier from "ask what the spec means" to "verify the spec against current code."

## SKILL.md `!cat` Preprocessing Expands at Load Time

When reading a SKILL's content from the `Skill` tool message, lines like ``!`cat ~/.claude/platform-commands/foo.sh`` are expanded to the script's actual content before you see the message. The raw SKILL.md file still contains the `!cat` reference. **Before editing** a SKILL.md to "stop inlining commands," Grep/Read the raw file — it may already use `!cat`. The visible inline text is a render artifact, not the source.

## Director Must Run Full Review→Address→Re-Review Cycles

Convergence requires the full cycle: review → address → re-review. Skipping the address step and calling "0 new findings" convergence is wrong — the addresser processes operator comments and implements reviewer suggestions that the reviewer only replies to. A reviewer reply-only cycle is not a substitute for an address cycle. After every review that posts new content (findings, replies, reactions), launch the addresser before re-reviewing.

## Deferred-Only Address Outcomes Stall the Review Watermark

When every reviewer comment on a PR ends up deferred (planning-doc exception, out-of-scope deferral) with no public reply and no commit, the review watermark never advances. Subsequent review cycles skip via SHA+comment-id match — so the reviewer never sees the addresser's internal "agreed but deferred" decision and can't approve-in-session the way the planning-doc flow expects. The compound loop stalls silently; the PR appears converged but actually needs operator input.

**Fix:** addresser must post a public reply for every comment it acts on — including "agreed, deferring to follow-up" and "agreed, awaiting approval for this specific wording." Public reply = new comment id = watermark advances = reviewer gets to respond next cycle. A zero-commit address cycle should still produce N public replies for N reviewer comments.

## Ack-Without-Push Leaves False Confidence on GitHub

Addresser session posts the ack reply ("Agree, fixing X...") then exits before commit/push — local edit stays uncommitted while GitHub shows progress. Next session catches it via `last_addressed_sha` mismatch, but the gap creates a window where reviewers see "addresser engaged" with no code change.

**Diagnostic:** `last_addressed_sha` still pointing at pre-fix SHA + GitHub ack reply present + uncommitted changes in worktree.

**Fix:** addresser-prompt should treat ack-reply + commit + push as atomic — write the ack only after the commit lands, or roll back the ack on push failure. Without this, the loop self-recovers but burns a cycle on rediscovery.

## Compound-Loop Happy Path: Reviewer Can Approve Escalation In-Session

Planning-doc escalations don't always require operator sign-off. When the addresser escalates with proposed wording and posts the reply publicly, the next review cycle's reviewer persona reads it, agrees, and posts an approval reply. The following address cycle picks up the reviewer approval as "new comment → implement" and commits the change. Operator never intervenes.

Conditions: addresser must post proposed wording publicly (not just escalate internally), reviewer persona must treat the thread as actionable, and the compound loop must be allowed enough cycles to complete the approve→implement handoff. This is why the deferred-only stall above is a problem — the stall prevents this happy path entirely.

## Watermark format consistency — store IDs in the format the runtime fetch returns

When a sweep skill writes a comment-ID watermark to `status.md`, it must match the format that subsequent runtime fetches return. GitHub returns inline comment IDs as REST-numeric (`3142970549`) via `gh api repos/.../pulls/N/comments`, but as GraphQL node IDs (`PRRC_kwDOIBAjJc67VVX1`) via `gh api graphql` or `gh pr view --json comments`. Storing one and comparing against the other makes equality always fail — every cycle triggers false "new work" detection and re-processes already-addressed comments, or (worse) the comparison silently fails open and the loop never converges. Pick one format (REST numeric is the common case for `pulls/N/comments` watermarks) and use it consistently across write and read.

## Reaction API: `+1`/`-1`, not `thumbs_up`/`thumbs_down`; inline vs top-level use different endpoints

GitHub reactions API content values are `+1`, `-1`, `laugh`, `confused`, `heart`, `hooray`, `rocket`, `eyes`. Wrong content (e.g., `thumbs_up`) returns HTTP 422. Reviewer/addresser sessions posting reactions on review comments must use these literal values.

Endpoint paths differ by comment type:
- **Inline review comments**: `repos/{owner}/{repo}/pulls/comments/{id}/reactions`
- **Top-level PR comments (issue comments)**: `repos/{owner}/{repo}/issues/comments/{id}/reactions`

The numeric ID for top-level comments lives in the comment URL fragment (`#issuecomment-NNNNNN`), not the GraphQL node ID. Mixing endpoints (e.g., posting an inline-style reaction on a top-level comment ID) returns 404. Confirmed by the PR 147 cycle 1 reviewer when reacting 👍 on an addresser pushback reply.

## Detached-HEAD worktree push: `git push origin HEAD:<branch>`

Address-session workers operating in worktrees that are detached HEAD or whose branch is checked out elsewhere can't `git push origin <branch>` directly — git refuses with "the current branch is not on '<branch>'" or similar. The fix is `git push origin HEAD:<branch>`, which pushes the current commit to the named remote branch regardless of local checkout state.

This is a recurring pattern for sweep-address sessions because:
1. The runner may reuse worktrees from prior sweeps where the branch is locked or checked out by another worktree
2. New worktrees created via `git worktree add <path> <branch>` sometimes land in detached-HEAD state when the branch already exists elsewhere

Worker prompts that involve `git push` should mention this fallback explicitly so the agent doesn't waste cycles on "current branch" errors.

## Reactions don't count toward compound auto-relaunch

The compound auto-relaunch rule fires on "inline comments > 0 OR thread replies > 0" — reactions on existing comments are neither, so a review cycle that posts only reactions (e.g., 👍 on an addresser pushback reply, 🚀 on a "Fixed in xyz" reply) doesn't change comment IDs and the watermark stays in sync. No address relaunch needed for reactions-only cycles. If a different PR in the same run has thread replies, the run-level relaunch still fires — but on the reactions-only PR the address session will skip via watermark match. This is correct behavior, not a gap.

## Locked worktree → create new instead of reusing

`git worktree list` may show worktrees in `locked` state — agent-isolation skills (e.g., `Agent(isolation: "worktree")`) lock their worktrees while the agent runs. Reusing a locked worktree from a different agent risks concurrent-edit collisions. When discovering worktrees for sweep-address reuse, treat `locked` as "owned by another process" and create a new worktree under the run dir instead. The few seconds of `git worktree add` cost beats debugging a partial-state collision.

## Confirmer comments can introduce cross-PR deps the body misses

`sweep:work-items` Phase 3.a2's `Blocked by:` scan reads issue bodies only, not comments. When a Sweeper-Confirm reply accepts a cross-PR dep ("Cross-PR dep accepted — P1.3 lands first or in parallel"), the dep is invisible to the next implement-stage sweep — auto-stacking won't trigger and the dependent's worktree is created from `main`.

**Fix:** before re-invoking sweep on the dependent issue, edit its body to add `Blocked by: #<blocker>`. Phase 3.a2 then sees the blocker has an open PR and sets `base_branch` to that PR's `headRefName`. Body edits are persistent and visible in the GitHub UI; per-issue `directives.md` overrides require remembering to write them each cycle.

## Implementer branches are title slugs, not `sweep/<N>-impl`

The skill's SKILL.md uses `sweep/<N>-impl` as the worktree-add example, but the implementer-prompt creates slugged branches like `sweep/152-etf-mnq-translation-contract-sizing`. Hardcoding `sweep/<N>-impl` as a stacked dependent's `BASE_BRANCH` fails with "branch not found."

For any manual stacking-override path, resolve the literal branch from the blocker's PR before writing metadata:

```bash
gh pr view <blocker-pr> --json headRefName -q '.headRefName'
```

Phase 3.a2 already does this when `Blocked by:` resolution finds a single open PR — the cautionary note is for ad-hoc directive paths.

## `gh api -f body=@file` is literal — use `-F` or expand the file first

`gh api -f` (raw-field) treats `@` as a literal character. `gh api -f body=@reply.txt` posts the string `@reply.txt`, not the file's contents. Two ways to post a file body:

```bash
# Typed field — @file IS expanded
gh api repos/.../comments -F body=@reply.txt

# Or read the file into a variable explicitly
body=$(cat reply.txt)
gh api repos/.../comments -f body="$body"
```

Bites address-session workers posting multi-line reply bodies generated to a file — failures show up as comment bodies containing the literal path string instead of the intended content.

## GitLab State Normalization: `OPENED` vs `OPEN`

GitLab returns `opened` for open MRs, which normalizes to `OPENED` via `tr '[:lower:]' '[:upper:]'`. The runner pre-flight compared against `OPEN` (GitHub convention) — mismatch caused immediate skip of valid MRs. The runner template must accept both: `if [ "$state" != "OPEN" ] && [ "$state" != "OPENED" ]`. GitHub returns `OPEN`; GitLab returns `OPENED`. Don't assume cross-platform state string parity.

## `claude -p` Sessions Short-Circuit on Merge Conflicts

When a `claude -p` session fetches MR watermark data and sees `merge_status: cannot_be_merged`, it may autonomously exit with `push-failed-conflicts` regardless of later prompt steps that instruct conflict resolution. The LLM generates the error message itself — it's not from the prompt template. Fix: write a directive with explicit "Do NOT exit early because of merge conflicts" instructions. Directives are read before the watermark step and carry stronger weight than conditional steps later in the prompt.

## Review Convergence Loops Can Expand Before Converging

Full fresh re-reviews find new issues each cycle because they examine the entire diff, not just verification of prior fixes. Findings can increase (4 → 5 → 7) before converging (→ 2 → 0). Escalate to operator after 2 consecutive cycles of scope growth. Natural convergence pattern: initial spikes settle as the code hardens and remaining findings are increasingly low-severity or acknowledged design decisions.

## Runner `session.state` Must Be Cleared for Clean Relaunches

The runner persists `session.state` with `session_id` for resume support. On relaunch (new cycle), a stale `session.state` triggers `No conversation found with session ID` and the session exits in ~30s with 0 context tokens. Always clear `session.state` alongside `status.md` and `state.md` before relaunching.

## `glab api` Notes Endpoint Rejects `-F per_page=N`

`glab api projects/:id/merge_requests/<IID>/notes -F per_page=5` returns HTTP 400. The endpoint works without pagination params — fetch all notes then filter client-side with `jq`. This differs from other `glab api` endpoints that accept `-F` pagination.

## Agent Worktrees Block Runner Worktree Creation

When an `Agent(isolation: "worktree")` creates a worktree on a PR branch (e.g., for a one-off fix), the address runner can't create its own worktree for the same branch — `git worktree add` errors with "already used by worktree." The runner skips that PR silently. Fix: `git worktree prune` before relaunching address runners, or explicitly `git worktree remove` stale agent worktrees. The director should prune between cycles as part of the relaunch sequence.

## Review Sessions Write Inconsistent Result Filenames

Some `claude -p` review sessions write to `result.md` (singular), others to `results.md` (plural). The sweep scaffold specifies `results.md`, but sessions sometimes deviate. Director monitoring must check both: `pr-*/result*.md`. Consider normalizing in the runner's post-session step.

## fill-template.sh Expands Placeholders in Documentation Headers

Template files with documentation headers containing `{KEY}` and `{@file}` patterns (e.g., `**Placeholders:** \`{PR_NUMBER}\``, `**File inclusions:** \`{@../preflight.md}\``) get those patterns expanded during assembly, duplicating content. All 5 sweep prompt templates had this. Fix: strip everything above the first `---` separator before processing — added as Phase 0 in fill-template.sh.

## `glab api -F` Fails for GET Query Parameters

`glab api projects/:id/merge_requests/N/notes -F sort=desc -F per_page=1` returns HTTP 400. The `-F` flag sends form data for POST requests, not query params for GET. Use `--paginate | jq '[.[].id] | max'` for watermark lookups, or encode params in the URL: `glab api "projects/:id/merge_requests/N/notes?sort=desc&per_page=1"`. The `--paginate` approach is more reliable across glab versions.

## GitLab `has_conflicts` Stale After Force-Push — Use `git merge-tree`

Both `merge_status: cannot_be_merged` and `has_conflicts: true` persist for minutes after a rebase + force-push. The stale cache causes false conflict exits in address sessions. Fix: use `git merge-tree origin/main origin/main origin/<branch> | grep -q CONFLICT` for local verification — accurate immediately, no API cache dependency.

## Stale Worktree Records Block Runner Worktree Creation

`git worktree add` fails with `fatal: '<branch>' is already used by worktree at '<path>'` when prunable worktree records exist (directory deleted but git metadata remains). **Don't blanket `git worktree prune`** — that breaks active-branch reuse where the runner legitimately reuses an existing worktree. Instead: `test -d <path>` before `git worktree add`; if the directory is missing, prune only that specific stale record (`git worktree remove <path> --force`), then retry. Also affects `Agent(isolation: "worktree")` — agent worktrees that aren't auto-cleaned block subsequent `git worktree add` for the same branch.

## live.md Append-Only Across Cycles — Filter by Timestamp

`grep -c "createDiffNote" live.md` counts across ALL review cycles, not just the current one. For per-cycle analysis, use cycle boundary markers (`### Cycle N — <timestamp> ###`) and filter by timestamp range. Cumulative counts caused a false "7 new findings" assessment when only 0 existed in the latest cycle.

## Compound `cd && git` Blocked in `claude -p` Sessions

Claude Code's bare-repository-attack guard blocks `cd /path && git command` as a compound command. This is a hardcoded security check, not overridable by permission patterns. Prompt templates must instruct separate Bash calls: first `cd`, then `git` as independent tool invocations. The addresser-prompt.md Step 5 was updated to enforce this.

## Director Must Maintain `director-state.md` Per Playbook

Skipping `director-state.md` updates between cycles causes cumulative count errors (live.md grep across cycles) and prevents cross-session handoff. Write `cycle`, `review_cycles`, `address_cycles`, convergence state, and the current monitoring table snapshot after each phase transition. The state file is the director's ground truth — without it, convergence assessment relies on ad-hoc live.md parsing.
