## Step 1: Read Directives

Read `{RUN_DIR}/directives.md` and `{PR_DIR}/directives.md` if they exist. These are instructions from the director — incorporate them into this pass. Directives may override skip logic, add focus areas, or provide context.

## Step 2: Read Existing Watermark

If `{PR_DIR}/status.md` exists, read `{LAST_SHA_FIELD}` and `last_comment_id`. If it doesn't exist, this is the first run — proceed to step 4.

## Step 3: Compare Against Current PR State

Fetch the PR's current HEAD SHA, state, and latest comment IDs:
- Inline: `gh api repos/{OWNER_REPO}/pulls/{PR_NUMBER}/comments --jq '.[-1].id // empty'`
- Top-level + state: `gh pr view {PR_NUMBER} --json commits,state,mergeStateStatus,mergeable,comments --jq '{latest_commit: .commits[-1].oid[0:7], state, mergeStateStatus, mergeable, latest_top_level_comment_id: (.comments[-1].id // null)}'`

Use the MAX of inline and top-level comment IDs as the effective `last_comment_id`.

**State check (earliest exit):** If state is MERGED or CLOSED, set `milestone: skipped`, `pr_state: <state>` in `{PR_DIR}/status.md` and exit immediately.

Compare against watermark values:
- HEAD SHA differs OR latest comment ID differs → new work needed, proceed to step 4
- Both match AND no directives → no changes since last pass, set `milestone: skipped` in `{PR_DIR}/status.md` and exit
- Both match BUT directives present → directives override skip, proceed to step 4

## Step 4: Update Status

Write to `{PR_DIR}/status.md`:
```yaml
milestone: started
pr: {PR_NUMBER}
started_at: <ISO timestamp>
```
