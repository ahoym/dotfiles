Runner template, model selection, permissions, and worktree mechanics that govern how `claude -p` workers actually launch.
- **Keywords:** runner, template, fill-template, schema-drift, model-selection, worktree, EXIT-trap, stale-branch, permissions, --allowedTools
- **Related:** none

---

## Quick Rerun Without Regenerating

When only a subset of work items need updated prompts (e.g., to add the directives step), edit `pr-<N>/prompt.txt` in-place rather than re-running the sweep skill. Avoids creating a new run directory and preserves existing artifacts. Regeneration is better when the template changed substantially or all items need new prompts.

## Director Local State During Worktree Pushes

When worktree agents push commits to the director's active branch, `git pull` fails if the director has uncommitted local changes. Use `git stash && git pull --ff-only && git stash pop` to sync. Expect this whenever mixing local edits with agent-pushed commits on the same branch.

## Permissions for Sweep Sessions

`claude -p` sessions with `--allowedTools` need explicit `Read` patterns for the run directory (e.g., `Read(~/**/tmp/sweep-reviews/**)`). Without it, the session may not be able to read `status.md` watermarks, `directives.md`, or prior `results.md` sections. `Write` and `Edit` patterns do not imply `Read` access.

## `claude -p` Skill Tool Requires Scoped Permission

The Skill tool IS available in `claude -p` sessions and works for invoking skills (e.g., verified working: `git:resolve-conflicts`, `git:team-review-request`, `git:address-request-comments`). Add scoped patterns like `Skill(git:team-review-request *)` to `~/.claude/settings.json` `permissions.allow`. Without a matching pattern, `claude -p` sessions silently skip the Skill call (no permission denial in logs — the session just works around it by doing the work manually, often incorrectly). Prefer scoped patterns over `Skill(*)` to limit what headless sessions can invoke.

**`--allowedTools` override:** For `claude -p` sessions launched with `--allowedTools`, Skill patterns must also appear in the `--allowedTools` list — `permissions.allow` alone is insufficient. The `--allowedTools` flag is more restrictive: it defines the complete tool set, and global allow patterns don't override it.

## Sweep Prereqs Must Be Platform-Aware

Sweep skill prerequisite patterns are platform-specific (`gh pr view:*` vs `glab mr view:*`). Hardcoding GitHub patterns causes the prereq check to either pass vacuously on GitLab or miss the actual `glab` patterns needed. Detect platform first, then check the corresponding CLI patterns.

## Worktree Creation From Checked-Out Branch

`git worktree add <path> main` fails when the main repo is on `main`. Use `origin/main --detach` instead, then `git checkout -b <branch>` in the worktree.

## Sweep Runner Model Selection: Orchestrator vs Leaf

Match the model to the runner's role. **Orchestrator runners** mainly invoke other skills/subagents (`sweep:review-prs` calling `git:team-review-request`, which spawns reviewer subagents) — `claude-sonnet-4-6` is fine because the heavy work is in the spawned children. **Leaf runners** do the actual work themselves: read diffs, edit files, run git, push commits (`sweep:address-prs`, `sweep:work-items` implementer) — use `claude-opus-4-6`. The runner template's `{{MODEL}}` placeholder is filled per-skill at let-it-rip generation. The `[1m]` variant only when context demands it (very large diffs, multi-file refactors).

## Runner Template Assumes PR Entity Type

Historical (resolved): the runner template hardcoded `pr-<N>` directory naming, `gh pr view` pre-flight, and `pr_state:` keys. Work-item sweeps needed post-generation patches. Now parameterized via metadata: `ENTITY_PREFIX`, `ENTITY_LABEL`, `STATE_FIELD`, `TERMINAL_STATES`, and `FETCH_ITEM_STATE_CMD` (literal platform command referencing `$pr_num`, used by both the launch probe and `process_item`'s API fallback). No post-generation patching required.

## Worktree EXIT Trap Destroys Uncommitted Implementer Work

The runner's `cleanup_worktrees` EXIT trap fires unconditionally — including when the session timed out before committing. All files written by `Write` tool to the worktree are lost. The branch persists locally (no commits, same as base), creating a second failure on relaunch: `git worktree add -b <branch>` fails because the branch already exists. The session can fall back to working in the project root, but the first run's work is unrecoverable. Mitigation options: (1) skip cleanup when `state.md` shows non-`completed` terminal state, (2) commit WIP before cleanup, (3) don't clean up implementer worktrees at all (current skill note: "Worktrees are preserved").

## Stale Branch Blocks Worktree Creation on Relaunch

`git worktree add -b <branch> <path> origin/main` fails when `<branch>` already exists locally from a prior timed-out run (worktree cleaned up but branch not deleted). The session falls back to working in the project root successfully — functional but bypasses worktree isolation. Fix: add `git branch -D <branch> 2>/dev/null` before `git worktree add -b` in the setup function, or use `--force` flag.

## Missing `fill-template.sh` Keys Fail Silently

`fill-template.sh` has no defaults — missing keys in metadata.json leave raw `{KEY}` placeholders in the output. Worse: agents often reason around unresolved placeholders (inferring the intended command from context) rather than erroring. The session succeeds, but the pipeline is fragile. Every skill must explicitly provide every key its template references. Verify with `grep '\{[A-Z_]*\}' prompt.txt` after assembly — a clean run has zero matches.

## Session-PID Liveness Audit on Director Cleanup

Runner `let-it-rip.sh` exit doesn't guarantee child `claude -p` cleanup — orphaned sessions can outlive the runner on crashed/killed runs. Audit at session end:

```bash
for p in tmp/.../sweep-*/*/pr-*/session.pid; do
  pid=$(cat $p); ps -p $pid -o comm= 2>/dev/null && echo "ALIVE $p" || echo "dead $p"
done
```

Alive PIDs after the runner's background task reports completion = leaked processes worth investigating (rate-limit storm, stuck stream-monitor, etc.). Combine with `pgrep -fl 'claude -p'` for a global sweep.

## Runner Template Schema Drift Between Skill Docs and Template

Sweep skill SKILL.md and sweep-scaffold.md document a metadata.json schema (`MODE`, `PRS`, `BRANCHES`, ...) that may drift from what the runner template actually consumes (`ITEMS`, `ENTITY_LABEL`, `ENTITY_PREFIX`, `STATE_FIELD`, `FETCH_ITEM_STATE_CMD`, `TERMINAL_STATES`). Missing placeholders cause the runner to emit `{{PLACEHOLDER}}` literals into `status.md` and skip sessions as `api-error`.

**Defensive check before launching a generated runner:** `grep -c "{{" <run_dir>/let-it-rip.sh` — should be 0. If nonzero, the metadata.json is missing keys the template expects. Re-derive the full list with `grep -oE "\\{\\{[A-Z_]+\\}\\}" <template>` and rebuild metadata.

## Pre-Flight Probe Validates CLI Syntax, Not API Path

The runner's pre-flight probe (template line ~101) dry-runs `FETCH_ITEM_STATE_CMD` with `pr_num=0` to catch CLI-flag errors (`Unknown flag`, `unrecognized argument`) before launching sessions. By design it tests command structure — not connectivity, auth, or whether the platform endpoint actually returns the expected shape. A 404 / empty body / list shape with `pr_num=0` is **expected** (item 0 doesn't exist) and falls through the matcher silently. The probe is a *parse-time* check, not a *runtime* check.

Failure mode this leaves open: a schema mismatch between `FETCH_ITEM_STATE_CMD` and `process_item`'s consumption of it. If the pipeline returns `OPENED` but `is_terminal_state` expects `OPEN`, or returns empty on success, every session marks `api-error` and skips. Probe passes; sweep fails silently.

**Stronger probe (future):** dry-run with `ITEMS[0]` (a real item known to exist) and assert non-empty output before launching. Tradeoff: one extra API call at runner start; catches end-to-end mismatches; turns a wasted sweep cycle into a fast-fail.

## Newly-Created Worktree Lags Remote — `git pull --rebase` Before Reading Source

`git worktree add <path> <branch>` checks out the *local* branch ref. If the remote has commits the local doesn't (common during compound sweeps where the addresser pushed in a prior cycle), the new worktree starts behind PR HEAD. Addresser sessions then read source from the stale worktree and post pushback replies on "phantom code" — features that exist on the live PR but not in the local checkout.

Symptom: 3+ correction replies per thread instead of the expected 2 (ack + commit-ref). Replies look like *"can't find the function this comment references"* followed by a self-correction *"actually, after rebasing the worktree, the function exists"*.

Mitigation: insert `git fetch origin <branch> && git reset --hard origin/<branch>` (or `git pull --rebase origin <branch>`) in the worktree setup function, after `git worktree add` and before the worker reads any source. Per-cycle relaunches need this because the previous cycle's commits are remote-only until refresh.
