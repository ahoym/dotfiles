## Step 1: Permission Pre-flight

Verify you can perform critical operations before investing time in analysis. Run this smoke test:
```bash
gh issue view {ISSUE_NUMBER} --json state -q '.state'
```
If this fails with a permission error, write `milestone: errored` and `error: permission denied — gh` to `{ISSUE_DIR}/status.md` and exit immediately. This catches misconfigured `--allowedTools` early.

## Step 2: Read Directives

Read `{RUN_DIR}/directives.md` and `{ISSUE_DIR}/directives.md` if they exist. These are instructions from the director — incorporate them into this pass. Directives may override skip logic, add focus areas, or provide context.

## Step 3: Read Existing Watermark

If `{ISSUE_DIR}/status.md` exists, read `last_sweep_updated_at` and `last_comment_id`. If it doesn't exist, this is the first run — proceed to step 5.

## Step 4: Compare Against Current Issue State

Fetch the issue's current state and last comment body:
```bash
gh issue view {ISSUE_NUMBER} --json state,updatedAt,comments --jq '{state, updatedAt, last_comment_id: (.comments[-1].id // null), last_comment_body: (.comments[-1].body // null)}'
```

**State check (earliest exit):** If state is `CLOSED`, set `milestone: skipped`, `issue_state: closed` in `{ISSUE_DIR}/status.md` and exit immediately.

Compare against watermark values:
- `updatedAt` differs OR `last_comment_id` differs → new activity, proceed to step 5
- Both match AND no directives → no changes since last pass, set `milestone: skipped` in `{ISSUE_DIR}/status.md` and exit
- Both match BUT directives present → directives override skip, proceed to step 5

## Step 5: Update Status

Write to `{ISSUE_DIR}/status.md`:
```yaml
milestone: started
issue: {ISSUE_NUMBER}
started_at: <ISO timestamp>
```

## Work Item

- **#{ISSUE_NUMBER}**: {ISSUE_TITLE}
- **URL**: {ISSUE_URL}
- **Labels**: {ISSUE_LABELS}

### Body

{ISSUE_BODY}

### Comments

{ISSUE_COMMENTS}

## Repository Context

{REPO_SUMMARY}
