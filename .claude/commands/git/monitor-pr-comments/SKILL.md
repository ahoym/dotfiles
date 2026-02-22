---
description: "Watch a PR in background and address new comments as they arrive."
---

# Monitor PR Comments

Poll a PR for new comments at regular intervals and address them as they come in.

## Usage

- `/git:monitor-pr-comments` - Monitor PR for current branch
- `/git:monitor-pr-comments <pr-number>` - Monitor specific PR
- `/git:monitor-pr-comments <pr-number> <interval>` - Custom interval (default: 30s)

## Reference Files (conditional — read only when needed)

- @../_shared/platform-detection.md - Platform detection for GitHub/GitLab
- init-tracking.sh - Initialize the processed comments tracking file
- monitor-script.sh - Background polling script

## Instructions

### 0. Detect platform

Follow `@../_shared/platform-detection.md` to determine GitHub vs GitLab. Set `CLI`, `REVIEW_UNIT`, and API command patterns accordingly. All commands below use GitHub (`gh`) syntax; substitute GitLab equivalents if on GitLab.

### 1. Get repo info and PR number

```bash
REPO=$(gh repo view --json owner,name --jq '.owner.login + "/" + .name')
PR=<pr-number>  # From args or current branch's PR
```

### 2. Initialize tracking

Run the init script to mark all current comments as "already seen":

```bash
bash .claude/commands/git/monitor-pr-comments/init-tracking.sh "$REPO" "$PR"
```

### 3. Start background monitor

Copy the monitor script to /tmp and run with `run_in_background: true`:

```bash
cp .claude/commands/git/monitor-pr-comments/monitor-script.sh ./tmp/
chmod +x ./tmp/monitor-script.sh
./tmp/monitor-script.sh "$REPO" "$PR" "30"
```

This returns a task ID and output file path.

### 4. Check for new comments

Periodically read the output file:

```bash
tail -20 /path/to/task/output
```

### 5. When a new comment is detected

1. **Add to processed list** immediately to avoid re-detection:
   ```bash
   echo "<comment_id>" >> ./tmp/pr${PR}_processed_comments.txt
   ```

2. **Fetch full comment** details:
   ```bash
   gh api repos/$REPO/pulls/$PR/comments/<id>
   ```

3. **Categorize and address** using `/git:address-pr-review` workflow

4. **Refresh baseline** after replying (to exclude your own replies):
   ```bash
   bash .claude/commands/git/monitor-pr-comments/init-tracking.sh "$REPO" "$PR"
   ```

### 6. Stop monitoring

Use `TaskStop` tool with the background task ID.

## Key Details

- **Two comment sources**: PR review comments (`/pulls/{pr}/comments`) and issue comments (`/issues/{pr}/comments`)
- **Tracking file**: `./tmp/pr<number>_processed_comments.txt` - one ID per line
- **Output format**: Truncated to 150 chars; fetch full comment when processing
- **Background execution**: Monitor runs via `run_in_background` so you can continue working
